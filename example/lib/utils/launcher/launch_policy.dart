import 'package:morpheus_launcher_gui/globals.dart';

/// Mod loader families recognized by the launcher.
enum ModLoader {
  vanilla,
  fabric,
  optifine,
  optiforge,
  forge,
  neoforge,
  quilt,
}

/// Result of resolving a version id (and optional metadata) to its loader
/// and real Minecraft version.
class LaunchProfile {
  final String minecraftVersion;
  final ModLoader loader;

  const LaunchProfile({required this.minecraftVersion, required this.loader});
}

/// Full description of a launch: what to run and with which loader.
///
/// [enableClassPath] is derived on demand from [loader], [realGameVersion]
/// and the current global/manual overrides, so it always reflects the
/// latest settings even if they change after this config was built.
class LaunchConfig {
  final String gameVersion;
  final String? productId;
  final bool isModded;
  final String realGameVersion;
  final ModLoader loader;
  final bool startOnFirstThread;

  /// Unconditionally forces classpath mode, regardless of [loader] or
  /// version (used by Modrinth modpacks, which always force classpath
  /// irrespective of their loader).
  final bool forceClassPath;

  final List<String> jvmArgs;
  final List<String> launcherArgs;

  LaunchConfig({
    required this.gameVersion,
    this.productId,
    required this.isModded,
    required this.realGameVersion,
    required this.loader,
    required this.startOnFirstThread,
    this.forceClassPath = false,
    this.jvmArgs = const [],
    this.launcherArgs = const [],
  });

  bool get enableClassPath {
    // Morpheus's own dedicated products aren't Minecraft loaders: the
    // classpath policy doesn't apply to them.
    if (productId != null) return false;
    if (forceClassPath) return true;

    return LaunchPolicy.resolveEnableClassPathFor(loader, realGameVersion);
  }
}

/// Decides whether a launch should use classpath (`-c`) or classloader mode.
///
/// Policy:
/// - Vanilla, Fabric and OptiFine: classloader by default, classpath only
///   when explicitly forced (global setting or manual `-c`).
/// - Old Forge / OptiForge (below [forgeClasspathBaseline]): same as OptiFine.
/// - Forge from [forgeClasspathBaseline] onward: classpath is always forced.
/// - NeoForge and Quilt: classpath is always forced.
class LaunchPolicy {
  /// Forge never shipped a build for plain 1.17; it resumed at 1.17.1, which
  /// is also where Forge switched to requiring classpath mode.
  static const String forgeClasspathBaseline = '1.17.1';

  static bool resolveEnableClassPathFor(ModLoader loader, String minecraftVersion) {
    if (Globals.forceClasspath || hasManualClasspathOverride()) return true;

    switch (loader) {
      case ModLoader.forge:
      case ModLoader.optiforge:
        return _compareMinecraftVersions(minecraftVersion, forgeClasspathBaseline) >= 0;
      case ModLoader.neoforge:
      case ModLoader.quilt:
        return true;
      case ModLoader.vanilla:
      case ModLoader.fabric:
      case ModLoader.optifine:
        return false;
    }
  }

  /// Whether the user manually typed `-c` into the custom launcher
  /// arguments field, as a legacy way of forcing classpath mode.
  static bool hasManualClasspathOverride() {
    return Globals.javalaunchercontroller.text.split(' ').contains('-c');
  }

  /// Maps a Modrinth `loader` field to its [ModLoader].
  static ModLoader loaderFromModrinthId(String id) {
    switch (id) {
      case 'fabric':
        return ModLoader.fabric;
      case 'forge':
        return ModLoader.forge;
      case 'quilt':
        return ModLoader.quilt;
      case 'neoforge':
        return ModLoader.neoforge;
      default:
        return ModLoader.vanilla;
    }
  }

  /// Detects a loader purely from a self-describing version id, following
  /// the naming conventions used by each installer (e.g.
  /// `fabric-loader-<loaderVer>-<mcVer>`, `<mcVer>-forge-<forgeVer>`,
  /// `neoforge-<neoVer>`). Returns [ModLoader.vanilla] when the id doesn't
  /// self-describe a loader.
  static ModLoader detectLoaderFromId(String id) {
    final lower = id.toLowerCase();

    if (lower.startsWith('neoforge-') || lower.startsWith('neoforge_')) return ModLoader.neoforge;
    if (lower.startsWith('fabric-loader-')) return ModLoader.fabric;
    if (lower.startsWith('quilt-loader-')) return ModLoader.quilt;
    if (lower.contains('optiforge')) return ModLoader.optiforge;
    if (lower.contains('optifine')) return ModLoader.optifine;
    if (lower.contains('forge')) return ModLoader.forge;
    if (lower.contains('fabric')) return ModLoader.fabric;
    if (lower.contains('quilt')) return ModLoader.quilt;

    return ModLoader.vanilla;
  }

  /// Detects a loader from a generic type hint (e.g. UI labels like
  /// "Forge", "Fabric", already-normalized type strings, ...).
  static ModLoader detectLoaderFromType(String type) {
    final lower = type.toLowerCase();

    if (lower.contains('neoforge')) return ModLoader.neoforge;
    if (lower.contains('optiforge')) return ModLoader.optiforge;
    if (lower.contains('optifine')) return ModLoader.optifine;
    if (lower.contains('forge')) return ModLoader.forge;
    if (lower.contains('fabric')) return ModLoader.fabric;
    if (lower.contains('quilt')) return ModLoader.quilt;

    return ModLoader.vanilla;
  }

  /// Refines loader detection using an installed version profile's
  /// `libraries` list, the way real Forge/Fabric/Quilt/NeoForge installers
  /// populate it. Returns `null` when no known loader library is found.
  static ModLoader? detectLoaderFromLibraries(List<dynamic> libraries) {
    for (final entry in libraries) {
      final name = entry is Map ? entry['name']?.toString().toLowerCase() : null;
      if (name == null) continue;

      if (name.startsWith('net.neoforged:')) return ModLoader.neoforge;
      if (name.startsWith('net.minecraftforge:forge:')) return ModLoader.forge;
      if (name.startsWith('net.fabricmc:fabric-loader:')) return ModLoader.fabric;
      if (name.startsWith('org.quiltmc:quilt-loader:')) return ModLoader.quilt;
    }

    return null;
  }

  /// Extracts the real Minecraft version out of a self-describing id for
  /// the given [loader]. Assumes [id] actually follows that loader's
  /// naming convention (i.e. [detectLoaderFromId] already matched it).
  static String extractMinecraftVersion(String id, ModLoader loader) {
    switch (loader) {
      case ModLoader.fabric:
        return _stripLoaderPrefix(id, 'fabric-loader-');
      case ModLoader.quilt:
        return _stripLoaderPrefix(id, 'quilt-loader-');
      case ModLoader.forge:
      case ModLoader.optiforge:
      case ModLoader.optifine:
        return id.split('-').first;
      case ModLoader.neoforge:
      case ModLoader.vanilla:
        return id;
    }
  }

  static String _stripLoaderPrefix(String id, String prefix) {
    if (!id.toLowerCase().startsWith(prefix)) return id;

    // Everything after "<loader>-loader-" is "<loaderVersion>-<mcVersion>";
    // the Minecraft version itself may contain dashes (pre-releases, RCs),
    // so only the loader version (up to the first dash) is stripped off.
    final remainder = id.substring(prefix.length);
    final separatorIndex = remainder.indexOf('-');

    return separatorIndex == -1 ? remainder : remainder.substring(separatorIndex + 1);
  }

  static int _compareMinecraftVersions(String a, String b) {
    final partsA = a.split('.');
    final partsB = b.split('.');
    final length = partsA.length > partsB.length ? partsA.length : partsB.length;

    for (var i = 0; i < length; i++) {
      final numA = i < partsA.length ? int.tryParse(partsA[i]) ?? 0 : 0;
      final numB = i < partsB.length ? int.tryParse(partsB[i]) ?? 0 : 0;
      if (numA != numB) return numA.compareTo(numB);
    }

    return 0;
  }
}
