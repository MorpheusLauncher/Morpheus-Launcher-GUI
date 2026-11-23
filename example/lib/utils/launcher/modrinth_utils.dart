import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:morpheus_launcher_gui/globals.dart';
import 'package:morpheus_launcher_gui/utils/launcher/file_downloader.dart';
import 'package:morpheus_launcher_gui/utils/launcher/modpack_installations.dart';
import 'package:morpheus_launcher_gui/utils/launcher/modpack_detail_source.dart';
import 'package:morpheus_launcher_gui/utils/launcher/parallel_downloads.dart';

/// Manages Modrinth modpack instances under:
///   .morpheus/modrinth-packs/<slug>/
///
/// Directory layout:
///   .morpheus/modrinth-packs/
///     index.json             ← registry of all installed packs (offline-friendly)
///     <slug>/
///       pack.json            ← per-instance metadata (version, deps…)
///       mods/
///       config/
///       saves/
///       resourcepacks/
///       shaderpacks/
///       screenshots/
///
/// index.json schema:
///   {
///     "packs": [
///       {
///         "slug":        "all-of-fabric-6",
///         "projectId":   "aabbccdd",
///         "title":       "All of Fabric 6",
///         "iconUrl":     "https://…",
///         "versionName": "1.10.0",
///         "minecraft":   "1.20.1",
///         "loader":      "fabric",          // "fabric" | "forge" | "quilt" | …
///         "installedAt": "2025-03-22T…"
///       },
///       …
///     ]
///   }
class ModrinthUtils {
  // ─────────────────────────────────────────
  //  Paths
  // ─────────────────────────────────────────

  /// Root directory for all modpack instances.
  static String get packsRoot => '${LauncherUtils.getApplicationFolder("morpheus")}/modrinth-packs';

  /// Path to the global registry file.
  static String get indexFile => '$packsRoot/index.json';

  /// Directory for a specific modpack instance identified by [slug].
  static String instanceDir(String slug) => '$packsRoot/$slug';

  /// Path to the local metadata file for a modpack instance.
  static String metaFile(String slug) => '${instanceDir(slug)}/pack.json';

  // ─────────────────────────────────────────
  //  index.json — global registry
  // ─────────────────────────────────────────

  /// Reads the global index, returning the list of pack entries.
  /// Returns an empty list if the file doesn't exist or is malformed.
  static List<Map<String, dynamic>> readIndex() {
    final file = File(indexFile);
    if (!file.existsSync()) return [];
    try {
      final decoded = json.decode(file.readAsStringSync()) as Map<String, dynamic>;
      final packs = decoded['packs'] as List? ?? [];

      return packs.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  /// Writes the full list of pack entries back to index.json atomically.
  static Future<void> _writeIndex(List<Map<String, dynamic>> packs) async {
    Directory(packsRoot).createSync(recursive: true);
    final file = File(indexFile);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert({'packs': packs}),
      flush: true,
    );
  }

  /// Adds or updates the entry for [slug] in index.json.
  static Future<void> _upsertIndex(Map<String, dynamic> entry) async {
    final packs = readIndex();
    final idx = packs.indexWhere((p) => p['slug'] == entry['slug']);
    if (idx >= 0) {
      packs[idx] = entry;
    } else {
      packs.add(entry);
    }
    await _writeIndex(packs);
  }

  /// Removes the entry for [slug] from index.json.
  static Future<void> _removeFromIndex(String slug) async {
    final packs = readIndex()..removeWhere((p) => p['slug'] == slug);
    await _writeIndex(packs);
  }

  /// Returns the index entry for [slug], or null if not registered.
  static Map<String, dynamic>? getIndexEntry(String slug) {
    return readIndex().cast<Map<String, dynamic>?>().firstWhere(
          (p) => p?['slug'] == slug,
          orElse: () => null,
        );
  }

  // ─────────────────────────────────────────
  //  Instance management
  // ─────────────────────────────────────────

  /// Returns true if an instance for [slug] already exists on disk.
  static bool instanceExists(String slug) => Directory(instanceDir(slug)).existsSync();

  /// Creates the directory skeleton for a new modpack instance.
  static void _createInstanceDirs(String slug) {
    for (final sub in ['mods', 'config', 'saves', 'resourcepacks', 'shaderpacks', 'screenshots']) {
      Directory('${instanceDir(slug)}/$sub').createSync(recursive: true);
    }
  }

  /// Saves modpack metadata locally so we can display it without re-fetching.
  static Future<void> _writeMeta(String slug, Map<String, dynamic> meta) async {
    final file = File(metaFile(slug));
    await file.writeAsString(json.encode(meta), flush: true);
  }

  /// Reads cached metadata for [slug], or null if not present.
  static Map<String, dynamic>? readMeta(String slug) {
    final file = File(metaFile(slug));
    if (!file.existsSync()) return null;
    try {
      return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Returns a list of all installed modpack slugs (from index.json).
  /// Falls back to directory scanning if index is missing.
  static List<String> installedSlugs() {
    final indexed = readIndex().map((p) => p['slug'].toString()).toList();
    if (indexed.isNotEmpty) return indexed;

    // Fallback: scan filesystem
    final root = Directory(packsRoot);
    if (!root.existsSync()) return [];

    return root
        .listSync()
        .whereType<Directory>()
        .map((d) => d.path.split(Platform.pathSeparator).last)
        .where((name) => name != 'index.json') // just in case
        .toList();
  }

  /// Deletes the instance directory for [slug] and removes it from index.json.
  static Future<void> removeInstance(String slug) async {
    final dir = Directory(instanceDir(slug));
    if (dir.existsSync()) await dir.delete(recursive: true);
    await _removeFromIndex(slug);
  }

  // ─────────────────────────────────────────
  //  Download & install
  // ─────────────────────────────────────────

  /// Full install pipeline:
  ///   1. Fetch latest version from Modrinth API
  ///   2. Download the .mrpack archive
  ///   3. Extract overrides/ into the instance directory
  ///   4. Download each mod file listed in modrinth.index.json
  ///   5. Write pack.json metadata
  ///   6. Register the pack in index.json
  ///
  /// [onProgress] receives a value between 0.0 and 1.0.
  /// [onStatus]   receives a human-readable status string.
  static Future<void> installModpack({
    required String projectId,
    required String slug,
    required String title,
    String? iconUrl,
    void Function(double progress)? onProgress,
    void Function(String status)? onStatus,
    InstallationCancellation? cancellation,
    String? selectedVersionId,
  }) async {
    final client = http.Client();
    final batch = DownloadBatch();
    try {
      cancellation?.check();
      onStatus?.call('Fetching version info…');

      // 1 ── Fetch latest version metadata
      final versionsRequest = client.get(Uri.parse('${Urls.modrinthApiURL}/project/$projectId/version'));
      final versionsRes = await (cancellation?.wait(versionsRequest) ?? versionsRequest);
      if (versionsRes.statusCode != 200) {
        throw Exception('Failed to fetch versions for $projectId');
      }

      final versions = json.decode(versionsRes.body) as List;
      if (versions.isEmpty) throw Exception('No versions available for $projectId');

    final latest = selectModrinthVersion(versions, selectedVersionId);
      final versionId = latest['id']?.toString() ?? '';
      final versionName = latest['version_number']?.toString() ?? '';

      // Find the primary .mrpack file
      final files = (latest['files'] as List? ?? []);
      final primaryFile = files.firstWhere(
        (f) => f['primary'] == true,
        orElse: () => files.isNotEmpty ? files.first : null,
      );
      if (primaryFile == null) throw Exception('No file found in version $versionId');

      final downloadUrl = primaryFile['url']?.toString() ?? '';
      if (downloadUrl.isEmpty) throw Exception('Empty download URL for $versionId');

      // 2 ── Download .mrpack
      onStatus?.call('Downloading $title $versionName…');
      onProgress?.call(0.05);

      final mrpackRequest = client.get(Uri.parse(downloadUrl));
      final mrpackRes = await (cancellation?.wait(mrpackRequest) ?? mrpackRequest);
      if (mrpackRes.statusCode != 200) {
        throw Exception('Failed to download mrpack from $downloadUrl');
      }

      onProgress?.call(0.25);

      // 3 ── Create instance dirs and extract archive
      _createInstanceDirs(slug);

      final archive = ZipDecoder().decodeBytes(mrpackRes.bodyBytes);

      // Parse modrinth.index.json first
      final indexEntry = archive.files.firstWhere(
        (f) => f.name == 'modrinth.index.json',
        orElse: () => throw Exception('modrinth.index.json not found in mrpack'),
      );
      final index = json.decode(utf8.decode(indexEntry.content as List<int>)) as Map<String, dynamic>;

      // Extract overrides/ → instance root
      onStatus?.call('Extracting overrides…');
      for (final file in archive.files) {
        cancellation?.check();
        if (!file.isFile) continue;
        if (!file.name.startsWith('overrides/')) continue;

        final relativePath = file.name.substring('overrides/'.length);
        if (relativePath.isEmpty) continue;

        final outPath = '${instanceDir(slug)}/$relativePath';
        final outFile = File(outPath);
        outFile.parent.createSync(recursive: true);
        outFile.writeAsBytesSync(file.content as List<int>);
      }

      onProgress?.call(0.45);

      // 4 ── Download individual mod files from index
      final modFiles = (index['files'] as List? ?? []);
      final total = modFiles.length;

      onStatus?.call('Downloading $total mod files…');

      var completed = 0;
      await runParallelDownloads(modFiles, (item) async {
        cancellation?.check();
        final modFile = item as Map<String, dynamic>;
        final modPath = modFile['path']?.toString() ?? '';
        final downloads = (modFile['downloads'] as List? ?? []);
        if (downloads.isEmpty || modPath.isEmpty) throw const FormatException('Modrinth file is missing path or download URL');

        final modUrl = downloads.first.toString();
        final dest = File('${instanceDir(slug)}/$modPath');

        // Skip if already present (resume-friendly)
        if (!dest.existsSync()) {
          final hashes = modFile['hashes'];
          await batch.downloadFile(
            client: client,
            url: Uri.parse(modUrl),
            destination: dest,
            cancellation: cancellation,
            expectedSize: modFile['fileSize'] as int?,
            expectedSha1: hashes is Map ? hashes['sha1']?.toString() : null,
          );
        }

        completed++;
        onProgress?.call(0.45 + 0.45 * (completed / total));
      });
      onStatus?.call('Verifying downloaded files…');
      await batch.verify(cancellation, (fraction) => onProgress?.call(.9 + .09 * fraction));

      // Derive loader name from dependencies
      // modrinth.index.json deps example: { "minecraft": "1.20.1", "fabric-loader": "0.15.7" }
      final deps = Map<String, String>.from(
        (index['dependencies'] as Map? ?? {}).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
      );
      final mcVersion = deps['minecraft'] ?? '';
      final loader = _detectLoader(deps);

      // 5 ── Write per-instance pack.json
      final meta = {
        'projectId': projectId,
        'slug': slug,
        'title': title,
        'iconUrl': iconUrl ?? '',
        'versionId': versionId,
        'versionName': versionName,
        'minecraft': mcVersion,
        'loader': loader,
        'installedAt': DateTime.now().toIso8601String(),
        'dependencies': deps,
      };
      cancellation?.beginCommit();
      await _writeMeta(slug, meta);

      // 6 ── Register in global index.json
      await _upsertIndex({
        'slug': slug,
        'projectId': projectId,
        'title': title,
        'iconUrl': iconUrl ?? '',
        'versionName': versionName,
        'minecraft': mcVersion,
        'loader': loader,
        'installedAt': meta['installedAt'],
      });

      onProgress?.call(1.0);
      onStatus?.call('$title installed successfully!');
    } finally {
      client.close();
      await batch.discardPending();
    }
  }

  /// Detects the mod loader name from a modrinth.index.json dependencies map.
  static String _detectLoader(Map<String, String> deps) {
    if (deps.containsKey('fabric-loader')) return 'fabric';
    if (deps.containsKey('forge')) return 'forge';
    if (deps.containsKey('quilt-loader')) return 'quilt';
    if (deps.containsKey('neoforge')) return 'neoforge';

    return 'unknown';
  }

  // ─────────────────────────────────────────
  //  Launch helpers
  // ─────────────────────────────────────────

  /// Returns the game directory to pass to the Minecraft launcher
  /// for the modpack identified by [slug].
  static String gameDir(String slug) => instanceDir(slug);

  /// Reads the required mod loader and game version from pack.json.
  ///
  /// Returns a map like:
  ///   { 'minecraft': '1.20.1', 'fabric-loader': '0.15.7' }
  /// or an empty map if metadata is missing.
  static Map<String, String> getDependencies(String slug) {
    final meta = readMeta(slug);
    if (meta == null) return {};
    final deps = meta['dependencies'];
    if (deps == null) return {};

    return Map<String, String>.from(deps as Map);
  }
}
