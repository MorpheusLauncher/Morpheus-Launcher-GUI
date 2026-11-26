import 'dart:io';

import 'package:flutter/material.dart';
import 'package:morpheus_launcher_gui/globals.dart';
import 'package:morpheus_launcher_gui/l10n/app_localizations.dart';
import 'package:morpheus_launcher_gui/utils/error_dialog.dart';
import 'package:morpheus_launcher_gui/utils/launcher/launch_policy.dart';
import 'package:morpheus_launcher_gui/utils/launcher/parallel_downloads.dart';
import 'package:morpheus_launcher_gui/utils/launcher/version_utils.dart';
import 'package:morpheus_launcher_gui/utils/widget_utils.dart';
import 'package:morpheus_launcher_gui/views/main_page.dart';

export 'package:morpheus_launcher_gui/utils/launcher/launch_policy.dart' show LaunchConfig, LaunchPolicy, ModLoader, LaunchProfile;

class LaunchUtils {
  /// Lancia Minecraft con i parametri di LaunchConfig
  static Future<void> launchMinecraft(BuildContext context,
      LaunchConfig config, {
        required VoidCallback onAccountRequired,
        String? gameDirectory,
      }) async {
    // Verifica account
    final account = Globals.getAccount();
    if (account == null) {
      WidgetUtils.showMessageDialog(
        context,
        AppLocalizations.of(context)!.account_required_title,
        AppLocalizations.of(context)!.account_required_msg,
            () {
          Navigator.pop(context);
          onAccountRequired();
        },
      );

      return;
    }

    WidgetUtils.showLoadingCircle(context);
    Globals.consolecontroller.clear();
    var loading = true;
    var phase = 'LAUNCH-ACCOUNT';
    try {
      await AccountUtils.refreshPremium(context);
      // Installa Java automaticamente se necessario
      if (!Globals.javaAdvSet) {
        phase = 'LAUNCH-JAVA';
        await LauncherUtils.JavaAutoInstall(
          config.isModded ? config.realGameVersion : config.gameVersion,
        );
      }

      if (context.mounted) {
        Navigator.pop(context);
        loading = false;
      }

      // Costruisci args di lancio
      phase = 'LAUNCH-PROCESS';
      final args = buildLaunchArguments(config, gameDirectory: gameDirectory);
      final environment = {'DOWNLOAD_THREADS': ModpackDownloadSettings.limit.toString()};

      final Process process;

      if (Platform.isLinux) {
        final javaPath = Globals.javapathcontroller.text;
        final lastSlashIndex = javaPath.lastIndexOf('/');

        if (lastSlashIndex > 0) {
          // Su linux è meglio usare una shell per evitare vari casini.
          // Si usa `exec` così java rimpiazza la shell: process.kill() colpisce java e non solo sh
          final javaDir = javaPath.substring(0, lastSlashIndex);
          final javaArgs = args.map(_escapeShellArg).join(' ');
          process = await Process.start('sh', ['-c', "cd '${javaDir.replaceAll("'", "'\\''")}' && exec ./java $javaArgs"], environment: environment);
        } else {
          process = await Process.start(javaPath, args, environment: environment, workingDirectory: gameDirectory ?? Globals.gamefoldercontroller.text);
        }
      } else {
        // Su Windows e MacOS usiamo il lancio normale
        process = await Process.start(Globals.javapathcontroller.text, args, environment: environment, workingDirectory: gameDirectory ?? Globals.gamefoldercontroller.text);
      }

      // Gestione console
      if (Globals.showConsole && context.mounted) {
        WidgetUtils.showConsole(context, process, gameDirectory: gameDirectory);
      } else {
        // Consuma comunque stdout/stderr
        process.stdout.transform(systemEncoding.decoder).listen((data) {
          final cleaned = data.replaceAll(RegExp(r'[\r\n]+'), '');
          debugPrint('[STDOUT] $cleaned');
        });

        process.stderr.transform(systemEncoding.decoder).listen((data) {
          final cleaned = data.replaceAll(RegExp(r'[\r\n]+'), '');
          debugPrint('[STDERR] $cleaned');
        });
      }

      // Handle exit code senza bloccare UI
      _handleProcessExit(context, process, config.gameVersion);
    } catch (e) {
      if (context.mounted) {
        if (loading) Navigator.pop(context);
        await ErrorDialog.show(context, code: phase, operation: 'Could not start Minecraft.', details: 'Minecraft: ${config.gameVersion}', error: e);
      }
    }
  }

  static String _escapeShellArg(String arg) {
    // Se l'argomento contiene spazi o caratteri speciali, wrappa con quote singole
    if (arg.contains(' ') || arg.contains('\$') || arg.contains('!') || arg.contains('"') || arg.contains('\'') || arg.contains('\\')) {
      // Escape delle singole quote interne
      return "'${arg.replaceAll("'", "'\\''")}'";
    }

    return arg;
  }

  /// Gestione exit del processo in background
  static Future<void> _handleProcessExit(BuildContext context, Process process, String version) async {
    final exitCode = await process.exitCode;
    Globals.consolecontroller.append("[LAUNCHER]: exit code $exitCode\n");

    if (exitCode != 0 && exitCode != 143 && context.mounted) {
      await ErrorDialog.show(context, code: 'LAUNCH-EXIT', operation: 'Minecraft exited unexpectedly.', details: 'Minecraft: $version\nExit code: $exitCode');
    }
  }

  /// Costruisce args completi
  static List<String> buildLaunchArguments(LaunchConfig config, {String? gameDirectory}) {
    final account = Globals.getAccount()!;
    final args = <String>[];

    /* ---------- JVM ARGS (PRIMA DI -jar) ---------- */

    args.addAll(config.jvmArgs);

    // Workaround offline 1.16.4 / 1.16.5
    if ((config.realGameVersion == "1.16.4" || config.realGameVersion == "1.16.5") && !account.isPremium) {
      args.addAll([
        "-Dminecraft.api.auth.host=https://0.0.0.0/",
        "-Dminecraft.api.account.host=https://0.0.0.0/",
        "-Dminecraft.api.session.host=https://0.0.0.0/",
        "-Dminecraft.api.services.host=https://0.0.0.0/",
      ]);
    }

    // macOS: XstartOnFirstThread
    if (config.startOnFirstThread) args.add("-XstartOnFirstThread");

    // JVM args utente
    if (Globals.javavmcontroller.text.isNotEmpty) {
      args.addAll(Globals.javavmcontroller.text.split(" "));
    }

    // Ely.by
    if (account.isElyBy) {
      args.add(
        '-javaagent:${LauncherUtils.getApplicationFolder("morpheus")}/authlib-injector.jar=ely.by',
      );
    }

    // JVM base
    final workingDir = gameDirectory ?? Globals.gamefoldercontroller.text;
    args.addAll([
      "-Duser.dir=$workingDir",
      "-Djava.library.path=$workingDir/versions/${config.gameVersion}/natives/",
      ...LauncherUtils.buildJVMOptimizedArgs(Globals.javaramcontroller.text),
    ]);

    /* ---------- JAR ---------- */

    args.addAll([
      "-cp",
      "${LauncherUtils.getApplicationFolder("morpheus")}/Launcher.jar",
      "team.morpheus.launcher.Main",
    ]);

    /* ---------- LAUNCHER ARGS (DOPO -jar) ---------- */

    args.addAll([
      "-version",
      config.productId ?? config.gameVersion,
      "-minecraftToken",
      account.accessToken,
      "-minecraftUsername",
      account.username,
      "-minecraftUUID",
      account.uuid,
    ]);

    if (config.enableClassPath) args.add("-c");
    if (config.startOnFirstThread) args.add("-startOnFirstThread");

    if (Globals.customFolderSet || gameDirectory != null) {
      args.addAll(["-gameFolder", gameDirectory ?? Globals.gamefoldercontroller.text]);
    }

    // Launcher args utente. "-c" è già stato interpretato come override
    // manuale della classpath (vedi LaunchPolicy.hasManualClasspathOverride)
    // e riflesso in config.enableClassPath sopra: va filtrato qui per non
    // duplicarlo.
    if (Globals.javalaunchercontroller.text.isNotEmpty) {
      args.addAll(Globals.javalaunchercontroller.text.split(" ").where((arg) => arg != "-c"));
    }

    // Launcher args del loader
    args.addAll(config.launcherArgs);

    return args;
  }

  /// Determina se serve startOnFirstThread per macOS
  static bool shouldUseStartOnFirstThread(String resolvedGameVersion) {
    if (!Platform.isMacOS) return false;

    final verList = VersionUtils.getMinecraftVersions(false);
    final currentVersionIndex = verList.indexWhere(
          (version) => version["id"] == resolvedGameVersion,
    );
    final startingVersionIndex = verList.indexWhere(
          (version) => version["id"] == "17w43a",
    );

    return currentVersionIndex != -1 && startingVersionIndex != -1 && currentVersionIndex <= startingVersionIndex;
  }
}
