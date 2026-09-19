library globals;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:morpheus_launcher_gui/account/account_utils.dart';
import 'package:morpheus_launcher_gui/utils/logging/log_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_theme/system_theme.dart';

class Globals {
  static const buildVersion = "Ver 4.5.0";
  static const windowTitle = "Morpheus Launcher";
  static const borderRadius = 14.0;
  static const ms_client_id = "c2346197-42f1-4461-91a9-20f947a1cca8"; // if you fork this project, you are constrained to change this

  // Impostazioni del launcher: anche se sono settate su false il loro valore viene sempre sovrascritto dalla config
  static var showOnlyReleases = false;
  static var darkModeTheme = false;
  static var showConsole = false;
  static var javaAdvSet = false;
  static var customFolderSet = false;
  static var selectedWindowTheme = '';
  static var accentColor = 0;
  static var fullTransparent = false;
  static var forceClasspath = false;

  //////////////////////////////
  ///// Sezione Variabili //////
  //////////////////////////////
  static List<Account> accounts = [];
  static List<String> pinnedVersions = [];
  static List<String> WindowThemes = [];

  static var navSelected = NavSection.home, AccountSelected = 0;

  /** Sezione textfield */
  static final javapathcontroller = TextEditingController();
  static final javaramcontroller = TextEditingController();
  static final javavmcontroller = TextEditingController();
  static final javalaunchercontroller = TextEditingController();
  static final gamefoldercontroller = TextEditingController();
  static final usernamecontroller = TextEditingController();

  static final LogController consolecontroller = LogController();
  static final LogController diagnosticcontroller = LogController();

  /** Fabric */
  static var fabricGameVersionsResponse;
  static var fabricLoaderVersionsResponse;

  /** Forge */
  static var forgeVersions;

  /** OptiForge */
  static var optiforgeVersions;

  /** Optifine */
  static var optifineVersions;

  /** Vanilla */
  static var vanillaVersionsResponse;
  static var vanillaNewsResponse;

  /** Morpheus */
  static var morpheusVersionsResponse;

  /** Incompatible versions blacklist */
  static late Map<String, dynamic> incompatibleJson;

  static bool get isNewsAvailable => Globals.vanillaNewsResponse != null;

  static bool get isVersionsAvailable => Globals.vanillaVersionsResponse != null;

  static bool get isOnline => isNewsAvailable || isVersionsAvailable;

  static Account? getAccount() {
    if (Globals.accounts.isEmpty) return null;

    return Globals.accounts.elementAt(Globals.AccountSelected);
  }
}

enum NavSection {
  home,
  morpheus,
  vanilla,
  modded,
  settings,
  accounts,
}

class Urls {
  // Vari
  static const skinURL = "https://minepic.org";
  static const morpheusBaseURL = "https://morpheuslauncher.it";
  static const fabricApiURL = "https://meta.fabricmc.net/";
  static const forgeVersionsURL = "https://files.minecraftforge.net/net/minecraftforge/forge/maven-metadata.json";
  static const optifineVersionsURL = "$morpheusBaseURL/downloads/optifine.json";
  static const morpheusProductsURL = "$morpheusBaseURL/downloads/morpheus-lite/index.json";
  static const modrinthApiURL = "https://api.modrinth.com/v2";

  // Roba inerente a ElyBy
  static const elybyBaseURL = "https://account.ely.by";
  static const elybySkinsURL = "https://skinsystem.ely.by";

  // Roba inerente al changelog mojang e alle vanilla
  static const mojangContentURL = "https://launchercontent.mojang.com";
  static const mojangVersionsURL = "https://launchermeta.mojang.com/mc/game/version_manifest.json";

  // Authenticazione Premium
  static const msAuthURL = "https://login.microsoftonline.com/consumers/oauth2/v2.0";
  static const xboxAuthURL = "https://user.auth.xboxlive.com/user/authenticate";
  static const xstsAuthURL = "https://xsts.auth.xboxlive.com/xsts/authorize";
  static const mcAuthURL = "https://api.minecraftservices.com/authentication/login_with_xbox";
  static const mcSkinURL = "https://api.minecraftservices.com/minecraft/profile/skins";
}

class ColorUtils {
  static var isMaterial = false;

  /** Base accent color */
  static Color dynamicAccentColor = getColorFromAccent(Globals.accentColor);

  static Color getColorFromAccent(int accent) {
    List<Color> accentColors = [
      SystemTheme.accentColor.light.withAlpha(200), // System default color
      Colors.red.withAlpha(160),
      Colors.orange.withAlpha(160),
      Colors.yellow.withAlpha(160),
      Colors.green.withAlpha(160),
      Colors.teal.withAlpha(160),
      Colors.blue.withAlpha(160),
      Colors.deepPurpleAccent.withAlpha(160),
    ];

    return accent < accentColors.length ? accentColors[accent] : SystemTheme.accentColor.light.withAlpha(200);
  }

  /** Sfumature */
  static Color get defaultShadowColor => Colors.black.withAlpha(30);

  /** Background */
  static late Hct dynamicBackgroundMaterialHct;

  static Color get dynamicMaterialColor => Globals.darkModeTheme ? Color(dynamicBackgroundMaterialHct.toInt()) : const Color(0xFFF0F0F5);

  static Color get dynamicAcrylicColor {
    if (Platform.isMacOS) {
      return Globals.darkModeTheme ? Colors.black.withAlpha(40) : Colors.white.withAlpha(60);
    }

    return Globals.darkModeTheme ? Colors.black.withAlpha(60) : Colors.white.withAlpha(80);
  }

  static Color get dynamicBackgroundColor => isMaterial ? dynamicMaterialColor : dynamicAcrylicColor;

  static Color get dynamicWindowBackgroundColor {
    if (Platform.isMacOS || (Platform.isLinux && Globals.fullTransparent)) {
      return Colors.transparent;
    }

    if (ColorUtils.isMaterial) {
      return ColorUtils.dynamicBackgroundColor;
    } else {
      if (Globals.darkModeTheme) {
        return Colors.black.withAlpha(80);
      } else {
        return Colors.white.withAlpha(10);
      }
    }
  }

  /** Foreground */
  static late Hct dynamicPrimaryMaterialHct; // Colore foreground primario (container)
  static Color get dynamicPrimaryMaterialColor => Globals.darkModeTheme ? Color(dynamicPrimaryMaterialHct.toInt()) : Color(dynamicPrimaryMaterialHct.toInt());

  static Color get dynamicPrimaryForegroundColor => isMaterial ? dynamicPrimaryMaterialColor : dynamicAcrylicColor;
  static late Hct dynamicSecondaryMaterialHct; // Colore foreground secondario (pulsanti, etc.)
  static Color get dynamicSecondaryMaterialColor => Globals.darkModeTheme ? Color(dynamicSecondaryMaterialHct.toInt()) : Color(dynamicSecondaryMaterialHct.toInt());

  static Color get dynamicSecondaryForegroundColor => isMaterial ? dynamicSecondaryMaterialColor : dynamicAcrylicColor;
  static late Hct dynamicTertiaryMaterialHct; // Colore foreground terziario (Font)

  /** Font, Icone e Separatori */
  static Color get primaryFontColor => isMaterial ? (Globals.darkModeTheme ? Colors.white : Color(dynamicTertiaryMaterialHct.toInt()).withAlpha(160)) : Colors.white;

  static Color get secondaryFontColor => primaryFontColor.withAlpha(160);

  static reloadColors() {
    // Background material you
    dynamicBackgroundMaterialHct = Hct.fromInt(dynamicAccentColor.value);
    dynamicBackgroundMaterialHct.tone = 15;
    dynamicBackgroundMaterialHct.chroma = 18;
    // Foreground material you
    dynamicPrimaryMaterialHct = Hct.fromInt(dynamicAccentColor.value);
    dynamicSecondaryMaterialHct = Hct.fromInt(dynamicAccentColor.value);
    dynamicTertiaryMaterialHct = Hct.fromInt(dynamicAccentColor.value);

    if (Globals.darkModeTheme) {
      // Primario (contenitori)
      dynamicPrimaryMaterialHct.tone = 25;
      dynamicPrimaryMaterialHct.chroma = 18;
      // Secondario (bottoni, etc.)
      dynamicSecondaryMaterialHct.tone = 40;
      dynamicSecondaryMaterialHct.chroma = 25;
    } else {
      // Primario (contenitori)
      dynamicPrimaryMaterialHct.tone = 100;
      // Secondario (bottoni, etc.)
      dynamicSecondaryMaterialHct.tone = 90;
      dynamicSecondaryMaterialHct.chroma = 15;
    }
    // Terziario (font)
    dynamicTertiaryMaterialHct.tone = 10;
  }
}

class LauncherUtils {
  static dynamic getApplicationFolder(String targetProgram) {
    if (Platform.isWindows) {
      return ('${Platform.environment['APPDATA']}/.$targetProgram').replaceAll("\\", "/");
    } else if (Platform.isLinux) {
      return '${Platform.environment['HOME']}/.$targetProgram';
    } else if (Platform.isMacOS) {
      return '${Platform.environment['HOME']}/Library/Application Support/$targetProgram';
    } else {
      throw UnsupportedError('Unsupported operating system');
    }
  }

  static dynamic buildJVMOptimizedArgs(String maximumRam) {
    return [
      "-XX:+UnlockExperimentalVMOptions",
      "-XX:+UseG1GC",
      "-XX:G1NewSizePercent=20",
      "-XX:G1ReservePercent=20",
      "-XX:MaxGCPauseMillis=50",
      "-XX:G1HeapRegionSize=32M",
      "-XX:+DisableExplicitGC",
      "-XX:+AlwaysPreTouch",
      "-XX:+ParallelRefProcEnabled",
      "-Xms512M",
      "-Xmx${maximumRam}M",
      "-Dfile.encoding=UTF-8",
      "-XX:HeapDumpPath=MojangTricksIntelDriversForPerformance_javaw.exe_minecraft.exe.heapdump",
      "-Xss1M",
    ];
  }

  static Future<Map<String, String>?> checkJava() async {
    try {
      Process process;
      if (Platform.isLinux) {
        final javaPath = Globals.javapathcontroller.text;
        final lastSlashIndex = javaPath.lastIndexOf('/');

        if (lastSlashIndex != -1) {
          final javaDir = javaPath.substring(0, lastSlashIndex);
          process = await Process.start('sh', ['-c', '(cd "$javaDir" && ./java -version)']);
        } else {
          process = await Process.start(javaPath, ['-version']);
        }
      } else {
        process = await Process.start(
          Globals.javapathcontroller.text,
          ['-version'],
        );
      }

      String? firstLine;
      await for (String line in process.stderr.transform(systemEncoding.decoder)) {
        firstLine = line.trim();
        break; // Solo la prima riga
      }

      await process.exitCode;

      if (firstLine != null) {
        // Esempio: openjdk version "21.0.5" 2024-10-15 LTS
        final regex = RegExp(r'^(?<type>\S+)\s+version\s+"(?<version>[^"]+)"(?:\s+(?<date>\d{4}-\d{2}-\d{2}))?(?:\s+(?<lts>LTS))?');
        final match = regex.firstMatch(firstLine);

        if (match != null) {
          return {
            'type': match.namedGroup('type') ?? 'unknown',
            'version': match.namedGroup('version') ?? 'unknown',
            'releaseDate': match.namedGroup('date') ?? '',
            'lts': match.namedGroup('lts') == 'LTS' ? 'true' : 'false',
          };
        }
      }
    } catch (error) {
      print("Errore nel checkJava: $error");
    }

    return null;
  }

  /** Installa java automaticamente */
  static Future<dynamic> JavaAutoInstall(String gameVersion) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var requiredJavaVersion;

    File versionJsonFile = File('${Globals.gamefoldercontroller.text}/versions/$gameVersion/$gameVersion.json');
    if (versionJsonFile.existsSync()) {
      requiredJavaVersion = json.decode(versionJsonFile.readAsStringSync())["javaVersion"]["majorVersion"];
    } else {
      var realgameversion = gameVersion;
      if (gameVersion == "latest") realgameversion = Globals.vanillaVersionsResponse["latest"]["release"];
      if (gameVersion == "snapshot") realgameversion = Globals.vanillaVersionsResponse["latest"]["snapshot"];

      for (var ver in Globals.vanillaVersionsResponse["versions"]) {
        if (realgameversion == ver["id"]) {
          final response = await http.get(
            Uri.parse(ver["url"]),
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
          );
          requiredJavaVersion = json.decode(response.body)["javaVersion"]["majorVersion"];
        }
      }
    }

    var javaBasePath = "${LauncherUtils.getApplicationFolder("morpheus")}/runtime/jre-$requiredJavaVersion";
    var javaBinPath = "$javaBasePath/bin";

    if (requiredJavaVersion != null) {
      try {
        if (Globals.isOnline && !Directory(javaBinPath).existsSync()) {
          String downloadURL;
          String fileName;

          // Se è Java 8 su macOS x64, usa il JRE patchato
          bool isX64 = !Platform.version.contains("arm64");
          if (requiredJavaVersion == 8 && Platform.isMacOS && isX64) {
            downloadURL = "${Urls.morpheusBaseURL}/downloads/jre-8-patched.zip";
            fileName = "jre-8-patched.zip";
          } else {
            // Altrimenti usa l'API Azul come prima
            final queryParameters = {
              'java_version': "$requiredJavaVersion",
              'os': Platform.operatingSystem,
              'arch': Platform.version.contains("arm64") ? "aarch64" : "x86_64",
              'archive_type': Platform.isLinux ? 'tar.gz' : 'zip',
              'java_package_type': 'jdk',
              'latest': 'true',
              'javafx_bundled': 'false',
            };
            final uri = Uri.https('api.azul.com', '/metadata/v1/zulu/packages', queryParameters);
            final azulResponse = await http.get(uri, headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
            });

            dynamic javaResponse = json.decode(azulResponse.body);

            var filteredPackages = javaResponse.where((package) {
              String packageName = package["name"] ?? "";

              return !packageName.contains("musl") && !packageName.contains("alpine");
            }).toList();

            if (filteredPackages.isNotEmpty) {
              fileName = filteredPackages[0]["name"];
              downloadURL = filteredPackages[0]["download_url"];
            } else {
              fileName = javaResponse[0]["name"];
              downloadURL = javaResponse[0]["download_url"];
            }
          }

          Directory(javaBasePath).createSync(recursive: true);

          final archiveResponse = await http.get(Uri.parse(downloadURL));
          if (archiveResponse.statusCode == 200) {
            // Il nome dell'archivio che verrà scaricato
            String archiveExtension = Platform.isLinux ? '.tar.gz' : '.zip';
            String archivePath = "$javaBasePath/jre-$requiredJavaVersion$archiveExtension";

            // Scarica l'archivio
            File(archivePath).writeAsBytesSync(archiveResponse.bodyBytes);

            if (Platform.isMacOS) {
              // Unzippa da terminale, perchè in dart fa schifo
              Process unzipProcess = await Process.start("unzip", ["-o", archivePath, "-d", "$javaBasePath/"]);

              // Senza non funziona
              unzipProcess.stdout.transform(systemEncoding.decoder).forEach((line) {});

              // Quando finisce di estrarre tutto sposta i file nella directory precedente
              if (await unzipProcess.exitCode == 0) {
                Directory currentDir = Directory("$javaBasePath/${fileName.replaceAll(".zip", "/")}");
                List<FileSystemEntity> files = currentDir.listSync();
                for (FileSystemEntity file in files) {
                  Process moveProcess = await Process.start("mv", [file.path, javaBasePath]);

                  // Quando finisce di spostare un file alla volta cancella la cartella alla fine
                  if (await moveProcess.exitCode == 0) {
                    await Process.start("rmdir", [currentDir.path]);
                  }
                }
              }
            } else {
              // Estrazione con la libreria archive per Windows e Linux
              Archive archive;

              if (Platform.isLinux) {
                // Decodifica TAR.GZ
                final bytes = File(archivePath).readAsBytesSync();
                final tarBytes = const GZipDecoder().decodeBytes(bytes);
                archive = TarDecoder().decodeBytes(tarBytes);
              } else {
                // Decodifica ZIP (Windows)
                archive = ZipDecoder().decodeBytes(archiveResponse.bodyBytes);
              }

              // Estrai i file
              String folderToRemove = fileName.replaceAll(Platform.isLinux ? ".tar.gz" : ".zip", "/");
              for (final file in archive) {
                final filePath = "$javaBasePath/${file.name}".replaceAll(folderToRemove, "");
                if (file.isFile) {
                  File(filePath)
                    ..createSync(recursive: true)
                    ..writeAsBytesSync(file.content);
                } else {
                  Directory(filePath).create(recursive: true);
                }
              }
            }

            // Cancella l'archivio
            File(archivePath).deleteSync();

            if (Platform.isMacOS || Platform.isLinux) {
              // Imposta permessi di esecuzione su tutta la directory bin
              await Process.run("chmod", ["-R", "+x", "$javaBasePath/bin"]);
              // Imposta anche permessi di lettura ed esecuzione ricorsivamente su tutto
              await Process.run("chmod", ["-R", "755", javaBasePath]);
            }
          }
        }
      } catch (error) {
        print(error);
      }

      if (Directory(javaBinPath).existsSync()) {
        Globals.javapathcontroller.text = "$javaBinPath/java".replaceAll("//", "/");
      } else {
        Globals.javapathcontroller.text = "java";
      }
    } else {
      Globals.javapathcontroller.text = "java";
    }

    await prefs.setString("javaPath", Globals.javapathcontroller.text);

    return true;
  }
}

class MorpheusProduct {
  final String id;
  final String name;
  final String gameversion;

  MorpheusProduct({required this.id, required this.name, required this.gameversion});

  factory MorpheusProduct.fromJson(Map<String, dynamic> json) {
    return MorpheusProduct(
      id: json['id'],
      name: json['name'],
      gameversion: json['gameversion'],
    );
  }
}

class News {
  String title;
  String type;
  String version;
  String imageUrl;
  String imageTitle;
  String body;
  String id;
  String contentPath;

  News({
    required this.title,
    required this.type,
    required this.version,
    required this.imageUrl,
    required this.imageTitle,
    required this.body,
    required this.id,
    required this.contentPath,
  });

  factory News.fromJSON(Map<String, dynamic> json) {
    return News(
      title: json["title"],
      type: json["type"],
      version: json["version"],
      imageUrl: json["image"]["url"],
      imageTitle: json["image"]["title"],
      body: json["body"],
      id: json["id"],
      contentPath: json["contentPath"],
    );
  }
}
