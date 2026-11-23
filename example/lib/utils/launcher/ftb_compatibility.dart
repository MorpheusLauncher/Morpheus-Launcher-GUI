import 'package:morpheus_launcher_gui/globals.dart';
import 'package:morpheus_launcher_gui/utils/launcher/version_utils.dart';

enum FtbCompatibility { compatible, incompatible, unknown }

FtbCompatibility ftbVersionCompatibility(Map version) {
  final raw = version['targets'];
  if (raw is! List) return FtbCompatibility.unknown;
  final targets = raw.whereType<Map>().toList();
  final games = targets.where((t) => t['type'] == 'game' && t['name']?.toString().toLowerCase() == 'minecraft').toList();
  final loaders = targets.where((t) => t['type'] == 'modloader').toList();
  if (games.length != 1 || loaders.length != 1) return FtbCompatibility.unknown;
  final game = games.single['version']?.toString() ?? '';
  final loader = loaders.single['name']?.toString().toLowerCase() ?? '';
  if (game.isEmpty || loader.isEmpty) return FtbCompatibility.unknown;
  if (!{'forge', 'fabric', 'neoforge', 'quilt'}.contains(loader)) return FtbCompatibility.incompatible;
  if (!VersionUtils.isModpackCompatible(loader, game)) return FtbCompatibility.incompatible;
  if (loader == 'forge') {
    final dynamic supported = Globals.forgeVersions;
    if (supported is! List || supported.isEmpty) return FtbCompatibility.unknown;
    if (!supported.any((v) => v.toString().split('-').first == game)) return FtbCompatibility.incompatible;
  }

  return FtbCompatibility.compatible;
}

FtbCompatibility ftbPackCompatibility(Map pack) {
  final versions = (pack['versions'] as List? ?? []).whereType<Map>().where((v) => v['private'] != true && v['id'] != null);
  var hasUnknown = false;
  var any = false;
  for (final version in versions) {
    any = true;
    final status = ftbVersionCompatibility(version);
    if (status == FtbCompatibility.compatible) return status;
    if (status == FtbCompatibility.unknown) hasUnknown = true;
  }

  return !any || hasUnknown ? FtbCompatibility.unknown : FtbCompatibility.incompatible;
}
