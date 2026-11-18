import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morpheus_launcher_gui/account/account_utils.dart';
import 'package:morpheus_launcher_gui/globals.dart';
import 'package:morpheus_launcher_gui/l10n/app_localizations.dart';
import 'package:morpheus_launcher_gui/utils/launcher/launch_utils.dart';
import 'package:morpheus_launcher_gui/utils/launcher/version_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory gameDirectory;

  setUp(() {
    gameDirectory = Directory.systemTemp.createTempSync('morpheus-launch-policy-');
    Globals.gamefoldercontroller.text = gameDirectory.path;
    Globals.forceClasspath = false;
    Globals.customFolderSet = false;
    Globals.javalaunchercontroller.clear();
    Globals.javavmcontroller.clear();
    Globals.javaramcontroller.text = '2048';
    Globals.vanillaVersionsResponse = null;
    Globals.incompatibleJson = {};
    Globals.AccountSelected = 0;
    Globals.accounts = [
      Account(
        username: 'test-player',
        uuid: 'test-uuid',
        accessToken: 'test-token',
        refreshToken: '',
        isPremium: true,
        isSlimSkin: false,
        isElyBy: false,
      ),
    ];
    VersionUtils.clearVersionCache();
  });

  tearDown(() {
    Globals.accounts = [];
    Globals.forceClasspath = false;
    Globals.javalaunchercontroller.clear();
    Globals.vanillaVersionsResponse = null;
    Globals.incompatibleJson = {};
    VersionUtils.clearVersionCache();
    gameDirectory.deleteSync(recursive: true);
  });

  LaunchConfig configFor(String id, {String type = '', String? minecraftVersion, String? directory}) {
    final profile = VersionUtils.resolveLaunchProfile(id, type: type, minecraftVersion: minecraftVersion, gameDirectory: directory);

    return LaunchConfig(
      gameVersion: id,
      realGameVersion: profile.minecraftVersion,
      isModded: profile.loader != ModLoader.vanilla,
      loader: profile.loader,
      startOnFirstThread: false,
    );
  }

  void writeProfile(String id, Map<String, dynamic> metadata, {String? directory}) {
    final file = File('${directory ?? gameDirectory.path}/versions/$id/$id.json');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(jsonEncode({'id': id, 'type': 'release', ...metadata}));
  }

  // Exercise actual command generation with no installed JSON and no remote
  // manifest. In particular, first-time Forge must not depend on inheritsFrom.
  for (final scenario in [
    (id: 'latest', base: null, classpath: false),
    (id: 'snapshot', base: null, classpath: false),
    (id: '25w18a', base: null, classpath: false),
    (id: '26.1', base: null, classpath: false),
    (id: 'fabric-loader-0.16.14-1.21.6-pre1', base: null, classpath: false),
    (id: '1.21.5-OptiFine_HD_U_J3', base: null, classpath: false),
    (id: '1.12.2-optiforge-14.23.5.2859', base: null, classpath: false),
    (id: '1.9-forge-12.16.1.1887', base: null, classpath: false),
    (id: '1.13.2-forge-25.0.219', base: null, classpath: false),
    (id: '1.16.5-forge-36.2.42', base: null, classpath: false),
    // Forge never shipped a build for plain 1.17; it resumed at 1.17.1.
    (id: '1.17.1-forge-37.1.1', base: null, classpath: true),
    (id: '1.21.1-forge-52.0.0', base: null, classpath: true),
    (id: 'neoforge-21.1.1', base: '1.21.1', classpath: true),
    (id: 'quilt-loader-0.27.1-1.20.1', base: null, classpath: true),
  ]) {
    test('offline launch arguments for ${scenario.id}', () {
      final config = configFor(scenario.id, minecraftVersion: scenario.base);
      final args = LaunchUtils.buildLaunchArguments(config);
      expect(args.where((arg) => arg == '-c').length, scenario.classpath ? 1 : 0);
      final mainIndex = args.indexOf('team.morpheus.launcher.Main');
      expect(args.indexOf('-cp'), lessThan(mainIndex));
      expect(args[args.indexOf('-cp') + 1], endsWith('/Launcher.jar'));
      expect(args[args.indexOf('-version') + 1], scenario.id);
      if (scenario.classpath) expect(args.indexOf('-c'), greaterThan(mainIndex));
    });
  }

  test('Fabric and Quilt keep complete Minecraft pre-release IDs', () {
    expect(configFor('fabric-loader-0.16.14-1.21.6-pre1').realGameVersion, '1.21.6-pre1');
    expect(configFor('quilt-loader-0.27.1-1.21.6-rc1').realGameVersion, '1.21.6-rc1');
    expect(configFor('1.7.10-Forge10.13.4.1614-1.7.10').realGameVersion, '1.7.10');
  });

  test('installed NeoForge keeps its loader identity and reads inheritsFrom', () {
    writeProfile('neoforge-21.1.1', {'inheritsFrom': '1.21.1'});
    final config = configFor('neoforge-21.1.1');
    expect(config.loader, ModLoader.neoforge);
    expect(config.realGameVersion, '1.21.1');
    expect(config.isModded, isTrue);
    expect(config.enableClassPath, isTrue);
  });

  test('custom profile resolves through a not-yet-installed Forge parent', () {
    writeProfile('custom-profile', {'inheritsFrom': '1.17.1-forge-37.0.0'});
    final config = configFor('custom-profile');
    expect(config.loader, ModLoader.forge);
    expect(config.realGameVersion, '1.17.1');
    expect(config.enableClassPath, isTrue);
  });

  test('newly installed custom profile is resolved independently of catalog cache', () {
    expect(VersionUtils.getAllVersions(), isEmpty);
    writeProfile('custom-profile', {
      'inheritsFrom': '1.17.1',
      'libraries': [
        {'name': 'net.minecraftforge:forge:1.17.1-37.0.0'}
      ],
    });
    expect(configFor('custom-profile').enableClassPath, isTrue);
    writeProfile('custom-profile', {
      'inheritsFrom': '1.16.5',
      'libraries': [
        {'name': 'net.minecraftforge:forge:1.16.5-36.2.42'}
      ],
    });
    expect(configFor('custom-profile').enableClassPath, isFalse);
  });

  test('modpack dependencies and directory override the global game folder', () {
    final instance = Directory('${gameDirectory.path}/pack').path;
    writeProfile(
        'custom-profile',
        {
          'inheritsFrom': '1.21.1',
          'libraries': [
            {'name': 'org.quiltmc:quilt-loader:0.27.1'}
          ],
        },
        directory: instance);
    expect(configFor('custom-profile', directory: instance).loader, ModLoader.quilt);

    // No metadata is needed when a modpack already supplies its dependencies.
    final config = configFor('pack-profile', type: 'forge', minecraftVersion: '1.17.1', directory: instance);
    final args = LaunchUtils.buildLaunchArguments(config, gameDirectory: instance);
    expect(args, contains('-c'));
    expect(args[args.indexOf('-gameFolder') + 1], instance);
    expect(args, contains('-Duser.dir=$instance'));
  });

  test('manual override forces legacy loaders without duplicating -c', () {
    final config = configFor('1.12.2-optiforge-14.23.5.2859');
    Globals.forceClasspath = true;
    expect(LaunchUtils.buildLaunchArguments(config).where((arg) => arg == '-c').length, 1);
    Globals.javalaunchercontroller.text = '-c -custom-option';
    expect(LaunchUtils.buildLaunchArguments(config).where((arg) => arg == '-c').length, 1);
    Globals.forceClasspath = false;
    expect(config.enableClassPath, isTrue);
    expect(LaunchUtils.buildLaunchArguments(config), contains('-custom-option'));
  });

  test('Morpheus products preserve their dedicated launch behavior', () {
    Globals.forceClasspath = true;
    final args = LaunchUtils.buildLaunchArguments(LaunchConfig(
      gameVersion: '1.12.2',
      productId: 'morpheus-product',
      isModded: false,
      realGameVersion: '1.12.2',
      loader: ModLoader.vanilla,
      startOnFirstThread: false,
    ));
    expect(args, isNot(contains('-c')));
    expect(args[args.indexOf('-version') + 1], 'morpheus-product');
  });

  testWidgets('compatibility uses the same mode as launch, including manual args and aliases', (tester) async {
    Globals.vanillaVersionsResponse = {
      'latest': {'release': '1.17.1', 'snapshot': '1.17.1'},
      'versions': [
        {'id': '1.17.1', 'type': 'release', 'releaseTime': '2021-07-06T00:00:00Z'}
      ],
    };
    final blocked = {
      'ranges': [
        {
          'from': '1.17.1',
          'to': '1.17.1',
          'reason': 'test-mode-incompatibility',
          'incompatible': {
            for (final os in ['linux', 'windows', 'macos']) os: {'x64': true, 'arm64': true},
          },
        }
      ],
    };
    Globals.incompatibleJson = {
      'forge': {
        'classloader': blocked,
        'classpath': {'ranges': []}
      },
      'fabric': {
        'classloader': {'ranges': []},
        'classpath': blocked
      },
      'release': {
        'classloader': blocked,
        'classpath': {'ranges': []}
      },
    };
    late BuildContext context;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (value) {
        context = value;

        return const SizedBox();
      }),
    ));
    await tester.pumpAndSettle();

    expect(VersionUtils.isCompatible('Forge', '1.17.1', context), isTrue);
    expect(VersionUtils.isCompatible('Fabric', '1.17.1', context), isTrue);
    expect(VersionUtils.isCompatible('release', 'latest', context), isFalse);
    expect(VersionUtils.isCompatible('snapshot', 'snapshot', context), isFalse);

    Globals.javalaunchercontroller.text = '-c';
    expect(VersionUtils.getIncompatibilityReason('Fabric', '1.17.1', context), 'test-mode-incompatibility');
    expect(VersionUtils.isCompatible('release', 'latest', context), isTrue);
    expect(VersionUtils.isCompatible('snapshot', 'snapshot', context), isTrue);
  });
}
