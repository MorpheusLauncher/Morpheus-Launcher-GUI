import 'package:path/path.dart' as p;

/// Validated information required to prepare a client-side FTB instance.
class FtbManifest {
  final String versionName;
  final String minecraftVersion;
  final String loader;
  final String loaderVersion;
  final String? javaVersion;
  final List<FtbManifestFile> files;

  const FtbManifest({
    required this.versionName,
    required this.minecraftVersion,
    required this.loader,
    required this.loaderVersion,
    required this.javaVersion,
    required this.files,
  });

  factory FtbManifest.fromJson(Map<String, dynamic> json) {
    if (json['status'] == 'error') throw FormatException('FTB: ${json['message']}');
    final targets = (json['targets'] as List? ?? []).whereType<Map>().toList();
    String? target(String type, [String? name]) {
      for (final item in targets) {
        if (item['type'] == type && (name == null || item['name'] == name)) {
          final value = item['version']?.toString() ?? '';
          if (value.isNotEmpty) return value;
        }
      }

      return null;
    }

    final minecraft = target('game', 'minecraft');
    final loaders = targets.where((item) => item['type'] == 'modloader').toList();
    if (minecraft == null || loaders.length != 1) {
      throw const FormatException('FTB manifest must specify Minecraft and exactly one modloader');
    }
    final loader = loaders.single['name']?.toString().toLowerCase() ?? '';
    final loaderVersion = loaders.single['version']?.toString() ?? '';
    if (!{'forge', 'neoforge', 'fabric', 'quilt'}.contains(loader) || loaderVersion.isEmpty) {
      throw FormatException('Unsupported FTB modloader: $loader');
    }
    final entries = json['files'];
    if (entries is! List) throw const FormatException('FTB manifest has no file list');
    final files = <FtbManifestFile>[];
    final paths = <String>{};
    for (final raw in entries) {
      if (raw is! Map) throw const FormatException('Invalid FTB file entry');
      if (raw['serveronly'] == true || raw['optional'] == true) continue;
      final file = FtbManifestFile.fromJson(Map<String, dynamic>.from(raw));
      if (!paths.add(file.relativePath.toLowerCase())) {
        throw FormatException('Duplicate FTB file path: ${file.relativePath}');
      }
      files.add(file);
    }

    return FtbManifest(
      versionName: json['name']?.toString() ?? '',
      minecraftVersion: minecraft,
      loader: loader,
      loaderVersion: loaderVersion,
      javaVersion: target('runtime', 'java'),
      files: List.unmodifiable(files),
    );
  }
}

class FtbManifestFile {
  final String relativePath;
  final Uri url;
  final String sha1;
  final int? size;

  const FtbManifestFile({required this.relativePath, required this.url, required this.sha1, required this.size});

  factory FtbManifestFile.fromJson(Map<String, dynamic> json) {
    final directory = json['path']?.toString() ?? '';
    final name = json['name']?.toString() ?? '';
    // Validate as both POSIX and Windows paths, regardless of host OS.
    if (name.isEmpty ||
        name == '.' ||
        name == '..' ||
        name.contains('/') ||
        name.contains(r'\') ||
        directory.contains(r'\') ||
        p.posix.isAbsolute(directory) ||
        p.windows.isAbsolute(directory) ||
        directory.split('/').contains('..') ||
        directory.contains(':') ||
        name.contains(':')) {
      throw FormatException('Unsafe FTB file path: $directory$name');
    }
    final relative = p.posix.normalize(p.posix.join(directory, name));
    final url = Uri.tryParse(json['url']?.toString() ?? '');
    if (url == null || url.scheme != 'https' || url.host.isEmpty) {
      throw FormatException('Missing or invalid HTTPS download URL for $relative');
    }
    final digest = json['sha1']?.toString().toLowerCase() ?? '';
    if (!RegExp(r'^[0-9a-f]{40}$').hasMatch(digest)) {
      throw FormatException('Missing or invalid SHA-1 for $relative');
    }
    final rawSize = json['size'];
    if (rawSize != null && (rawSize is! int || rawSize < 0)) {
      throw FormatException('Invalid file size for $relative');
    }

    return FtbManifestFile(relativePath: relative, url: url, sha1: digest, size: rawSize as int?);
  }
}
