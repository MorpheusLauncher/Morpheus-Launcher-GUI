import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:morpheus_launcher_gui/globals.dart';
import 'package:morpheus_launcher_gui/utils/launcher/file_downloader.dart';
import 'package:morpheus_launcher_gui/utils/launcher/ftb_manifest.dart';
import 'package:morpheus_launcher_gui/utils/launcher/ftb_compatibility.dart';
import 'package:morpheus_launcher_gui/utils/launcher/modpack_installations.dart';
import 'package:morpheus_launcher_gui/utils/launcher/parallel_downloads.dart';
import 'package:path/path.dart' as p;

class FtbUtils {
  static String get packsRoot => p.join(LauncherUtils.getApplicationFolder('morpheus'), 'ftb-packs');

  static String _id(String id) {
    if (!RegExp(r'^[0-9]+$').hasMatch(id)) throw const FormatException('Invalid FTB pack ID');
    return id;
  }

  static String instanceDir(String id) => p.join(packsRoot, _id(id));

  static bool instanceExists(String id) => File(p.join(instanceDir(id), 'pack.json')).existsSync();

  static Map<String, dynamic>? readMeta(String id) {
    final file = File(p.join(instanceDir(id), 'pack.json'));
    if (!file.existsSync()) return null;
    return json.decode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  static List<Map<String, dynamic>> readIndex() {
    final root = Directory(packsRoot);
    if (!root.existsSync()) return [];
    return root
        .listSync()
        .whereType<Directory>()
        .where((dir) => RegExp(r'^[0-9]+$').hasMatch(p.basename(dir.path)))
        .map((dir) {
          try {
            return readMeta(p.basename(dir.path));
          } catch (_) {
            return null;
          }
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static Future<void> removeInstance(String id) async {
    final dir = Directory(instanceDir(id));
    if (await dir.exists()) await dir.delete(recursive: true);
  }

  static Future<void> install({
    required Map<String, dynamic> pack,
    void Function(double)? onProgress,
    void Function(String)? onStatus,
    http.Client? client,
    String? rootPath,
    InstallationCancellation? cancellation,
    String? selectedVersionId,
  }) async {
    final id = _id(pack['project_id']?.toString() ?? '');
    final rootPathValue = rootPath ?? packsRoot;
    final destination = p.join(rootPathValue, id);
    if (Directory(destination).existsSync()) throw StateError('FTB instance already exists');
    final versions = (pack['versions'] as List? ?? [])
        .whereType<Map>()
        .where((v) => v['private'] != true && v['id'] != null &&
            (selectedVersionId == null ? v['type']?.toString().toLowerCase() == 'release' : v['id'].toString() == selectedVersionId))
        .toList()
      ..sort((a, b) => (b['updated'] as num? ?? 0).compareTo(a['updated'] as num? ?? 0));
    if (versions.isEmpty) throw StateError('Selected FTB version is unavailable');
    final versionId = versions.first['id'].toString();
    if (!RegExp(r'^[0-9]+$').hasMatch(versionId)) throw const FormatException('Invalid FTB version ID');
    final httpClient = client ?? http.Client();
    Directory? staging;
    try {
      onStatus?.call('Fetching FTB manifest…');
      final response = await (cancellation?.wait(httpClient.get(Uri.parse('${Urls.ftbApiURL}/modpack/$id/$versionId'))) ??
          httpClient.get(Uri.parse('${Urls.ftbApiURL}/modpack/$id/$versionId')));
      if (response.statusCode != 200) throw HttpException('FTB manifest: HTTP ${response.statusCode}');
      final manifest = FtbManifest.fromJson(json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>);
      final compatibility = ftbVersionCompatibility({'targets': [
        {'type': 'game', 'name': 'minecraft', 'version': manifest.minecraftVersion},
        {'type': 'modloader', 'name': manifest.loader, 'version': manifest.loaderVersion},
      ]});
      if (compatibility == FtbCompatibility.incompatible) {
        throw StateError('Unsupported FTB Minecraft/modloader combination');
      }
      final root = Directory(rootPathValue);
      await root.create(recursive: true);
      staging = await root.createTemp('.ftb-$id-');
      final base = staging.path;
      var completed = 0;
      final batch = DownloadBatch();
      await runParallelDownloads(manifest.files, (entry) async {
        cancellation?.check();
        onStatus?.call('Downloading ${completed}/${manifest.files.length}: ${p.posix.basename(entry.relativePath)}');
        final file = File(p.joinAll([base, ...p.posix.split(entry.relativePath)]));
        await batch.downloadFile(client: httpClient, url: entry.url, destination: file, cancellation: cancellation, expectedSize: entry.size, expectedSha1: entry.sha1);
        completed++;
        onProgress?.call(.9 * completed / manifest.files.length);
      });
      onStatus?.call('Verifying downloaded files…');
      await batch.verify(cancellation, (fraction) => onProgress?.call(.9 + .09 * fraction));
      final meta = {
        'projectId': id,
        'slug': id,
        'title': pack['title']?.toString() ?? id,
        'iconUrl': pack['icon_url']?.toString() ?? '',
        'versionName': manifest.versionName,
        'versionId': versionId,
        'minecraft': manifest.minecraftVersion,
        'loader': manifest.loader,
        'installedAt': DateTime.now().toIso8601String(),
        'dependencies': {
          'minecraft': manifest.minecraftVersion,
          manifest.loader == 'fabric' || manifest.loader == 'quilt' ? '${manifest.loader}-loader' : manifest.loader: manifest.loaderVersion,
        },
      };
      cancellation?.beginCommit();
      await File(p.join(base, 'pack.json')).writeAsString(json.encode(meta), flush: true);
      if (await Directory(destination).exists()) throw StateError('FTB instance already exists');
      await staging.rename(destination);
      staging = null;
      onProgress?.call(1);
    } finally {
      if (staging != null && await staging.exists()) await staging.delete(recursive: true);
      if (client == null) httpClient.close();
    }
  }
}
