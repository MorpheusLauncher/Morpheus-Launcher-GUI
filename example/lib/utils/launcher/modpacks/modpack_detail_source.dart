import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:morpheus_launcher_gui/globals.dart';
import 'package:morpheus_launcher_gui/utils/launcher/modpacks/ftb/ftb_compatibility.dart';

class ModpackVersion {
  final String id;
  final String label;
  final bool compatible;

  const ModpackVersion({required this.id, required this.label, this.compatible = true});
}

Map<String, dynamic> selectModrinthVersion(List versions, String? id) {
  if (versions.isEmpty) throw StateError('No Modrinth versions available');
  if (id == null) return versions.first as Map<String, dynamic>;

  return versions.whereType<Map<String, dynamic>>().firstWhere(
        (version) => version['id']?.toString() == id,
        orElse: () => throw StateError('Selected Modrinth version is unavailable'),
      );
}

/// Provider-independent data consumed by the shared detail screen.
class ModpackDetails {
  final String description;
  final List<String> gameVersions;
  final List<String> loaders;
  final List<ModpackVersion> versions;
  final bool? supportsServer;
  final Map<String, dynamic>? latestVersion;
  final List<dynamic> dependencies;

  const ModpackDetails({
    this.description = '',
    this.gameVersions = const [],
    this.loaders = const [],
    this.versions = const [],
    this.supportsServer,
    this.latestVersion,
    this.dependencies = const [],
  });
}

abstract class ModpackDetailSource {
  const ModpackDetailSource();

  bool get supportsInstallation;

  Future<ModpackDetails> load(Map<String, dynamic> pack);
}

class ModrinthDetailSource extends ModpackDetailSource {
  final http.Client? client;

  const ModrinthDetailSource({this.client});

  @override
  bool get supportsInstallation => true;

  @override
  Future<ModpackDetails> load(Map<String, dynamic> pack) async {
    final id = Uri.encodeComponent(pack['project_id'].toString());
    Future<http.Response> get(String path) {
      final uri = Uri.parse('${Urls.modrinthApiURL}$path');

      return client == null ? http.get(uri) : client!.get(uri);
    }

    final responses = await Future.wait([get('/project/$id'), get('/project/$id/version')]);
    if (responses.any((response) => response.statusCode != 200)) {
      throw Exception('Failed to load Modrinth details');
    }
    final project = json.decode(utf8.decode(responses[0].bodyBytes)) as Map<String, dynamic>;
    final versions = json.decode(utf8.decode(responses[1].bodyBytes)) as List;
    final latest = versions.isEmpty ? null : versions.first as Map<String, dynamic>;

    return ModpackDetails(
      description: project['body']?.toString() ?? '',
      gameVersions: (project['game_versions'] as List? ?? []).map((v) => v.toString()).toList(),
      loaders: (project['loaders'] as List? ?? []).map((v) => v.toString()).toList(),
      versions: versions
          .whereType<Map>()
          .where((v) => v['id'] != null && v['version_number'] != null)
          .map((v) => ModpackVersion(id: v['id'].toString(), label: v['version_number'].toString()))
          .toList(),
      supportsServer: project['server_side'] == 'required',
      latestVersion: latest,
      dependencies: latest?['dependencies'] as List? ?? [],
    );
  }
}

class FtbDetailSource extends ModpackDetailSource {
  const FtbDetailSource();

  @override
  bool get supportsInstallation => true;

  @override
  Future<ModpackDetails> load(Map<String, dynamic> pack) async {
    final versions = (pack['versions'] as List? ?? []).whereType<Map>().where((v) => v['private'] != true && v['id'] != null).toList()
      ..sort((a, b) => (b['updated'] as num? ?? 0).compareTo(a['updated'] as num? ?? 0));
    final targets = versions.expand((v) => (v['targets'] as List? ?? []).whereType<Map>()).toList();

    return ModpackDetails(
      description: pack['_full_description']?.toString() ?? '',
      gameVersions: targets.where((t) => t['type'] == 'game' && t['name'] == 'minecraft').map((t) => '${t['version']}').toSet().toList().reversed.toList(),
      loaders: targets.where((t) => t['type'] == 'modloader').map((t) => '${t['name']}').toSet().toList(),
      versions: versions
          .map((v) =>
              ModpackVersion(id: v['id'].toString(), label: v['name']?.toString() ?? v['id'].toString(), compatible: ftbVersionCompatibility(v) != FtbCompatibility.incompatible))
          .toList(),
    );
  }
}
