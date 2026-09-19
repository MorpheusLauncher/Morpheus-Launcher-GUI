import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/src/widgets/framework.dart';
import 'package:http/http.dart' as http;
import 'package:morpheus_launcher_gui/globals.dart';
import 'package:morpheus_launcher_gui/l10n/app_localizations.dart';
import 'package:morpheus_launcher_gui/utils/launcher/launch_policy.dart';

class VersionUtils {
  static Future<List<String>> getPinnedVersions() async {
    String filePath = '${Globals.gamefoldercontroller.text}/launcher_profiles.json';
    File file = File(filePath);

    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('{"profiles":{}}');
    }

    String content = await file.readAsString();
    Map<String, dynamic> jsonMap = json.decode(content);
    Map<String, dynamic> profiles = jsonMap['profiles'];
    List<String> versionIds = [];

    profiles.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        String? versionId = value['lastVersionId'];
        if (versionId != null) {
          versionIds.add(versionId);
        }
      }
    });

    return versionIds;
  }

  static Future<void> updateLauncherProfiles(List<String> versionIds) async {
    String filePath = '${Globals.gamefoldercontroller.text}/launcher_profiles.json';
    File file = File(filePath);

    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString('{"profiles":{}}');
    }

    String content = await file.readAsString();
    Map<String, dynamic> jsonMap = json.decode(content);
    Map<String, dynamic>? profiles = jsonMap['profiles'] as Map<String, dynamic>?;
    profiles ??= {};
    List<String> keysToRemove = [];

    for (var versionId in versionIds) {
      if (!profiles.containsKey(versionId)) {
        profiles[versionId] = {
          "name": versionId,
          "lastVersionId": versionId,
        };
      }
    }

    profiles.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        if (!versionIds.contains(key)) {
          keysToRemove.add(key);
        }
      }
    });

    for (var key in keysToRemove) {
      profiles.remove(key);
    }

    jsonMap['profiles'] = profiles;

    await file.writeAsString(json.encode(jsonMap));
  }

  static Future<void> getVersions() async {
    final response = await http.get(
      Uri.parse(Urls.mojangVersionsURL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    Globals.vanillaVersionsResponse = jsonDecode(response.body);
  }

  static Future<void> getFabric() async {
    final fabricGameResponse = await http.get(
      Uri.parse("${Urls.fabricApiURL}/v2/versions/game"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    Globals.fabricGameVersionsResponse = jsonDecode(fabricGameResponse.body);

    final fabricLoaderResponse = await http.get(
      Uri.parse("${Urls.fabricApiURL}/v2/versions/loader"),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    Globals.fabricLoaderVersionsResponse = jsonDecode(fabricLoaderResponse.body);
  }

  static Future<List<String>> getForge() async {
    final forgeGameResponse = await http.get(
      Uri.parse(Urls.forgeVersionsURL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    var parsedData = jsonDecode(forgeGameResponse.body);
    var keys = parsedData.keys.toList();
    List<String> resultList = [];
    parsedData.forEach((key, value) {
      if (value.isNotEmpty) {
        var parts = value.last.split('-');
        if (parts.length >= 2) {
          int idx = keys.indexOf(key);
          if (idx >= keys.indexOf("1.6.4") && idx != keys.indexOf("1.7.10_pre4") && idx != keys.indexOf("1.18") && idx != keys.indexOf("1.19") && (idx < keys.indexOf("1.13.2") || idx > keys.indexOf("1.16.5"))) {
            resultList.add("${parts[0]}-forge-${parts[1]}");
          }
        }
      }
    });

    return resultList.reversed.toList();
  }

  static Future<List<String>> getOptiForge() async {
    final forgeGameResponse = await http.get(
      Uri.parse(Urls.forgeVersionsURL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    var parsedData = jsonDecode(forgeGameResponse.body);
    var keys = parsedData.keys.toList();
    List<String> resultList = [];
    parsedData.forEach((key, value) {
      if (value.isNotEmpty) {
        var parts = value.last.split('-');
        if (parts.length >= 2) {
          if (keys.indexOf(key) >= keys.indexOf("1.8.9") && keys.indexOf(key) <= keys.indexOf("1.12")) resultList.add("${parts[0]}-forge-${parts[1]}");
        }
      }
    });

    return resultList.reversed.toList();
  }

  static Future<List<String>> getOptifine() async {
    final optifineGameResponse = await http.get(
      Uri.parse(Urls.optifineVersionsURL),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );
    var parsedData = jsonDecode(optifineGameResponse.body);
    List<String> resultList = [];
    parsedData.forEach((key, value) {
      resultList.add(value["launchname"]);
    });

    return resultList.toList();
  }

  static List<Map<String, dynamic>>? _cachedAllVersions;

  static List<Map<String, dynamic>> getAllVersions() {
    if (_cachedAllVersions != null) {
      return _cachedAllVersions!;
    }

    List<Map<String, dynamic>> versions = [];
    Set<String> addedVersions = <String>{};

    versions.addAll(getMinecraftVersions(true));
    versions.addAll(getMinecraftVersions(false));
    addedVersions.addAll(versions.map((version) => version["id"]));

    versions.sort((a, b) {
      if (a["inheritsFrom"] != null && b["inheritsFrom"] != null) {
        return a["inheritsFrom"].compareTo(b["inheritsFrom"]);
      } else if (a["releaseTime"] != null && b["releaseTime"] != null) {
        return b["releaseTime"].compareTo(a["releaseTime"]);
      }

      return 0;
    });

    _cachedAllVersions = versions;

    return versions;
  }

  static void clearVersionCache() {
    _cachedAllVersions = null;
  }

  static List<Map<String, dynamic>> getMinecraftVersions(bool onlyModded) {
    List<Map<String, dynamic>> versions = [];
    Set<String> addedVersions = <String>{};

    versions.addAll(getMinecraftOfflineVersions(onlyModded));
    addedVersions.addAll(versions.map((version) => version["id"]));

    if (!onlyModded && Globals.vanillaVersionsResponse != null && Globals.vanillaVersionsResponse["versions"] != null) {
      for (var version in Globals.vanillaVersionsResponse["versions"]) {
        if (!addedVersions.contains(version["id"])) {
          versions.add(version);
          addedVersions.add(version["id"]);
        }
      }
    }

    versions.sort((a, b) {
      if (a["inheritsFrom"] != null && b["inheritsFrom"] != null) {
        return a["inheritsFrom"].compareTo(b["inheritsFrom"]);
      } else {
        return b["releaseTime"].compareTo(a["releaseTime"]);
      }
    });

    return versions;
  }

  static List<Map<String, dynamic>> getMinecraftOfflineVersions(var onlyModded) {
    String versionsFolder = '${Globals.gamefoldercontroller.text}/versions';

    Directory directory = Directory(versionsFolder);
    if (!directory.existsSync()) {
      return [];
    }

    List<Map<String, dynamic>> versions = [];
    directory.listSync().forEach((entity) {
      if (entity is Directory) {
        String version = entity.path.replaceAll("\\", "/").split('/').last;
        String jsonPath = '$versionsFolder/$version/$version.json';
        File jsonFile = File(jsonPath);

        if (jsonFile.existsSync()) {
          String jsonContent = jsonFile.readAsStringSync();
          Map<String, dynamic> jsonData = json.decode(jsonContent);

          if (version == "latest" || version == "snapshot") {
            return;
          }

          if (onlyModded) {
            if (jsonData["inheritsFrom"] != null) {
              versions.add(jsonData);
            }
          } else {
            if (jsonData["inheritsFrom"] == null) {
              versions.add(jsonData);
            }
          }
        }
      }
    });

    return versions;
  }

  static Map<String, dynamic>? resolveBaseVersion(String versionId, List<Map<String, dynamic>> allVersions) {
    if (versionId.isEmpty || allVersions.isEmpty) return null;

    final Map<String, Map<String, dynamic>> byId = {
      for (var v in allVersions)
        if (v["id"] != null) v["id"]: v,
    };

    final Set<String> visited = {};
    String currentId = versionId;

    while (true) {
      if (visited.contains(currentId)) {
        return byId[currentId];
      }
      visited.add(currentId);

      final current = byId[currentId];
      if (current == null) {
        return null;
      }

      final parent = current["inheritsFrom"];
      if (parent == null || parent == "") {
        return current;
      }

      currentId = parent;
    }
  }

  /// Resolves a version id (plus optional hints) to its [ModLoader] and
  /// real Minecraft version, without requiring the version to be installed
  /// or the remote manifest to be available.
  ///
  /// Resolution order for the Minecraft version:
  /// 1. an explicit [minecraftVersion], when given;
  /// 2. the installed profile's `inheritsFrom` (recursing through it when
  ///    the parent id itself self-describes a loader, e.g. a not-yet-
  ///    installed Forge build);
  /// 3. parsing [id] itself using the loader's naming convention.
  ///
  /// The loader is detected from [id], refined by an installed profile's
  /// `libraries` (the way real Forge/Fabric/Quilt/NeoForge installers
  /// record it when `inheritsFrom` points at a plain vanilla version), and
  /// falls back to [type] when [id] doesn't self-describe a loader.
  static LaunchProfile resolveLaunchProfile(
    String id, {
    String type = '',
    String? minecraftVersion,
    String? gameDirectory,
  }) {
    return _resolveLaunchProfile(id, type: type, minecraftVersion: minecraftVersion, gameDirectory: gameDirectory, depth: 0);
  }

  static LaunchProfile _resolveLaunchProfile(
    String id, {
    required String type,
    String? minecraftVersion,
    String? gameDirectory,
    required int depth,
  }) {
    // Guards against a malformed/cyclic inheritsFrom chain.
    if (depth > 10) {
      return LaunchProfile(minecraftVersion: minecraftVersion ?? id, loader: ModLoader.vanilla);
    }

    var loader = LaunchPolicy.detectLoaderFromId(id);
    if (loader == ModLoader.vanilla && type.isNotEmpty) {
      loader = LaunchPolicy.detectLoaderFromType(type);
    }

    String? resolvedVersion = (minecraftVersion != null && minecraftVersion.isNotEmpty) ? minecraftVersion : null;

    final directory = gameDirectory ?? Globals.gamefoldercontroller.text;
    final profileFile = File('$directory/versions/$id/$id.json');

    if (profileFile.existsSync()) {
      try {
        final data = json.decode(profileFile.readAsStringSync()) as Map<String, dynamic>;

        final libraries = data['libraries'];
        if (libraries is List) {
          final libraryLoader = LaunchPolicy.detectLoaderFromLibraries(libraries);
          if (libraryLoader != null) loader = libraryLoader;
        }

        final inheritsFrom = data['inheritsFrom']?.toString();
        if (resolvedVersion == null && inheritsFrom != null && inheritsFrom.isNotEmpty) {
          final parentLoader = LaunchPolicy.detectLoaderFromId(inheritsFrom);

          if (parentLoader != ModLoader.vanilla) {
            // The parent id itself encodes a loader (e.g. a Forge build
            // that hasn't been installed yet): resolve it the same way.
            final parentProfile = _resolveLaunchProfile(inheritsFrom, type: type, gameDirectory: gameDirectory, depth: depth + 1);
            resolvedVersion = parentProfile.minecraftVersion;
            if (loader == ModLoader.vanilla) loader = parentProfile.loader;
          } else {
            resolvedVersion = inheritsFrom;
          }
        }
      } catch (_) {
        // Corrupt or unreadable profile JSON: fall back to id-based parsing.
      }
    }

    resolvedVersion ??= LaunchPolicy.extractMinecraftVersion(id, loader);

    return LaunchProfile(minecraftVersion: resolvedVersion, loader: loader);
  }

  static Future<void> fetchMorpheusProducts() async {
    final response = await http.get(
      Uri.parse(Urls.morpheusProductsURL),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      Globals.morpheusVersionsResponse = data['products'];
    } else {
      Globals.morpheusVersionsResponse = [];
    }
  }

  static Future<void> fetchIncompatibleVersions() async {
    const url = '${Urls.morpheusBaseURL}/downloads/known-incompatible.json';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Errore nel download del JSON: ${response.statusCode}');
    }

    Globals.incompatibleJson = json.decode(response.body);
  }

  // Metodo helper per normalizzare il tipo e la versione
  static ({String gameType, String gameVer}) _normalizeTypeAndVersion(String type, String versionId, BuildContext context) {
    var gameType = type.toLowerCase();
    var gameVer = versionId.toLowerCase();

    if (gameVer.contains("pre-release")) {
      gameVer = gameVer.split(" ").first;
    }

    // "latest"/"snapshot" are aliases for whatever the manifest currently
    // considers the newest release/snapshot; resolve them so range checks
    // (which compare against concrete version ids) can actually match.
    if (gameVer == "latest" && Globals.vanillaVersionsResponse != null) {
      final resolved = Globals.vanillaVersionsResponse["latest"]?["release"];
      if (resolved is String && resolved.isNotEmpty) gameVer = resolved.toLowerCase();
    } else if (gameVer == "snapshot" && Globals.vanillaVersionsResponse != null) {
      final resolved = Globals.vanillaVersionsResponse["latest"]?["snapshot"];
      if (resolved is String && resolved.isNotEmpty) gameVer = resolved.toLowerCase();
    }

    final idLoader = LaunchPolicy.detectLoaderFromId(gameVer);
    if (idLoader != ModLoader.vanilla) {
      gameType = idLoader.name;
      gameVer = LaunchPolicy.extractMinecraftVersion(gameVer, idLoader);
    } else if (gameType.contains("release") || gameType.contains("snapshot")) {
      gameType = "release";
    } else if (gameType.contains("beta")) {
      gameType = "beta";
    } else if (gameType.contains("alpha")) {
      gameType = "alpha";
    }

    return (gameType: gameType, gameVer: gameVer);
  }

  static bool isCompatible(String type, String versionId, BuildContext context) {
    var gameType = type.toLowerCase();

    // We assume that latest vanilla's are good and compatible
    if (gameType.contains(AppLocalizations.of(context)?.vanilla_release_title.toLowerCase() as Pattern)) return true;
    if (gameType.contains(AppLocalizations.of(context)?.vanilla_snapshot_title.toLowerCase() as Pattern)) return true;

    final normalized = _normalizeTypeAndVersion(type, versionId, context);

    return _checkCompatibilityWithReason(normalized.gameType, normalized.gameVer).isCompatible;
  }

  static String? getIncompatibilityReason(String type, String versionId, BuildContext context) {
    var gameType = type.toLowerCase();

    // Le versioni vanilla sono sempre compatibili
    if (gameType.contains(AppLocalizations.of(context)?.vanilla_release_title.toLowerCase() as Pattern)) return null;
    if (gameType.contains(AppLocalizations.of(context)?.vanilla_snapshot_title.toLowerCase() as Pattern)) return null;

    final normalized = _normalizeTypeAndVersion(type, versionId, context);

    return _checkCompatibilityWithReason(normalized.gameType, normalized.gameVer).reason;
  }

  static ({bool isCompatible, String? reason}) _checkCompatibilityWithReason(String loaderType, String version) {
    try {
      final loaderConfig = Globals.incompatibleJson[loaderType];
      if (loaderConfig == null) return (isCompatible: true, reason: null);

      final currentOS = _getCurrentOS();
      final currentArch = _getCurrentArch();

      // Use the exact same mode the actual launch would use for this
      // loader/version, so compatibility checks never disagree with what
      // happens when the user actually launches.
      final loader = LaunchPolicy.detectLoaderFromType(loaderType);
      final useClasspath = LaunchPolicy.resolveEnableClassPathFor(loader, version);
      final rangesToCheck = loaderConfig[useClasspath ? 'classpath' : 'classloader']?['ranges'] as List? ?? [];

      for (var range in rangesToCheck) {
        if (_isVersionInRange(version, range['from'], range['to'])) {
          final incompatible = range['incompatible'] as Map<String, dynamic>?;
          if (incompatible != null && incompatible.containsKey(currentOS)) {
            final platformCompat = incompatible[currentOS] as Map<String, dynamic>;
            final isIncompatible = platformCompat[currentArch] as bool? ?? false;

            if (isIncompatible) {
              return (isCompatible: false, reason: range['reason'] as String?);
            }
          }
        }
      }

      return (isCompatible: true, reason: null);
    } catch (e) {
      return (isCompatible: true, reason: null);
    }
  }

  static bool _isVersionInRange(String version, String from, String to) {
    try {
      final verList = getAllVersions();

      if (verList.isEmpty) return false;

      final currentVersionIndex = verList.indexWhere((v) => v["id"] == version);
      final fromVersionIndex = verList.indexWhere((v) => v["id"] == from);
      final toVersionIndex = verList.indexWhere((v) => v["id"] == to);

      if (currentVersionIndex == -1 || fromVersionIndex == -1 || toVersionIndex == -1) return false;

      return currentVersionIndex <= fromVersionIndex && currentVersionIndex >= toVersionIndex;
    } catch (e) {
      return false;
    }
  }

  static String _getCurrentOS() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';

    return 'unknown';
  }

  static String _getCurrentArch() {
    if (Platform.version.contains('arm64') || Platform.version.contains('aarch64')) {
      return 'arm64';
    }

    return 'x64';
  }
}
