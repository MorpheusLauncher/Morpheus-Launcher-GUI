import 'dart:async';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:morpheus_launcher_gui/globals.dart';
import 'package:morpheus_launcher_gui/l10n/app_localizations.dart';
import 'package:morpheus_launcher_gui/utils/launcher/version_utils.dart';
import 'package:morpheus_launcher_gui/utils/logging/virtualized_log_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomSettingSwitchStyle {
  final IconData icon;
  final Color bgColor;
  final Color shadowColor;
  final Color fontColor;
  final Color toggleColor;
  final Color activeColor;
  final Color inactiveColor;

  CustomSettingSwitchStyle({
    required this.icon,
    required this.bgColor,
    required this.shadowColor,
    required this.fontColor,
    required this.toggleColor,
    required this.activeColor,
    required this.inactiveColor,
  });
}

class WidgetUtils {
  /// Numero di colonne per una griglia responsive larga [width], dati una
  /// larghezza minima di tile [minTileWidth] e uno spacing tra tile
  /// [spacing]. Usata da tutte le griglie del launcher (home, morpheus,
  /// vanilla, modloaders/modpack, alt manager, browser Modrinth) così che
  /// il numero di colonne resti coerente e prevedibile tra le varie
  /// schermate e durante il resize della finestra, invece di dipendere da
  /// logiche duplicate e leggermente diverse in ogni file.
  static int responsiveColumnCount(
    double width, {
    double minTileWidth = 300,
    double spacing = 8,
    int? maxColumns,
  }) {
    var columns = ((width + spacing) / (minTileWidth + spacing)).floor();
    if (columns < 1) columns = 1;
    if (maxColumns != null && columns > maxColumns) columns = maxColumns;

    return columns;
  }

  /** Switch impostazioni */
  static Widget buildSettingSwitchItem(
    String name,
    String name2,
    CustomSettingSwitchStyle style,
    var set,
    Function(dynamic value) callback,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
      child: SizedBox(
        height: 55,
        child: Material(
          elevation: 15,
          color: style.bgColor,
          shadowColor: style.shadowColor,
          borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
          child: Stack(
            children: [
              Row(
                children: [
                  SizedBox(
                    height: 55,
                    width: 45,
                    child: Center(
                      child: Material(
                        elevation: 10,
                        color: Colors.transparent,
                        shadowColor: ColorUtils.defaultShadowColor,
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                        child: Icon(
                          style.icon,
                          color: style.fontColor,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  /** Nome del setting */
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 18, 10, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: customTextStyle(
                            16,
                            FontWeight.w500,
                            style.fontColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              /** Interruttore */
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    child: Material(
                      elevation: 15,
                      color: Colors.transparent,
                      shadowColor: Colors.transparent,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      child: MouseRegion(
                        onEnter: (e) => {},
                        onExit: (e) => {},
                        child: FlutterSwitch(
                          width: 50,
                          height: 25,
                          toggleSize: 18.0,
                          toggleColor: style.toggleColor,
                          activeColor: style.activeColor,
                          inactiveColor: style.inactiveColor,
                          value: set,
                          onToggle: (value) async {
                            callback(value);
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            await prefs.setBool(name2, value);
                            set = value;
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /** Textfield */
  static Widget buildSettingTextItem(
    dynamic child,
    Color background,
    Color foreground,
    String hint,
    TextEditingController controller,
    Function(dynamic value) callback,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
      child: Material(
        elevation: 15,
        color: background,
        shadowColor: ColorUtils.defaultShadowColor,
        borderRadius: BorderRadius.circular(Globals.borderRadius - 2),
        child: Stack(
          children: [
            Focus(
              onFocusChange: (hasFocus) async {
                callback(hasFocus);
              },
              child: TextField(
                style: TextStyle(
                  color: foreground,
                  fontFamily: 'Comfortaa',
                  shadows: [
                    Shadow(
                      color: ColorUtils.defaultShadowColor,
                      blurRadius: 2.0,
                      offset: const Offset(2.0, 2.0),
                    ),
                  ],
                ),
                controller: controller,
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.transparent),
                    borderRadius: BorderRadius.circular(Globals.borderRadius - 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.circular(Globals.borderRadius - 2),
                  ),
                  hintText: hint,
                  hintStyle: customTextStyle(16, FontWeight.w300, foreground),
                  filled: false,
                ),
              ),
            ),
            if (child != null) child,
          ],
        ),
      ),
    );
  }

  /** Container riempibile impostazioni */
  static Widget buildSettingContainerItem(dynamic widgets) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
      child: Material(
        elevation: 15,
        color: ColorUtils.dynamicPrimaryForegroundColor,
        shadowColor: ColorUtils.defaultShadowColor,
        borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
        child: widgets,
      ),
    );
  }

  /////////////////////////////////
  //// ALTRI ELEMENTI GRAFICI /////
  /////////////////////////////////

  static Widget buildButton(
    IconData icon,
    Color color,
    Color iconColor,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 6, 5),
      child: GestureDetector(
        onTap: onPressed,
        child: backShadow(
          MouseRegion(
            onEnter: (e) => {},
            child: Material(
              elevation: 15,
              color: color,
              shadowColor: Colors.transparent,
              borderRadius: BorderRadius.circular(Globals.borderRadius - 4),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 20),
                ),
              ),
            ),
          ),
          20.0,
          ColorUtils.defaultShadowColor,
        ),
      ),
    );
  }

  static Widget buildTextButton(
    Color color,
    Color textColor,
    VoidCallback onPressed,
    String text,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(7, 7, 0, 7),
      child: GestureDetector(
        onTap: onPressed,
        child: backShadow(
          MouseRegion(
            onEnter: (e) => {},
            child: Material(
              elevation: 15,
              color: color,
              shadowColor: Colors.transparent,
              borderRadius: BorderRadius.circular(Globals.borderRadius - 4),
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Center(
                  child: Text(text, style: customTextStyle(16, FontWeight.w500, textColor)),
                ),
              ),
            ),
          ),
          20.0,
          ColorUtils.defaultShadowColor,
        ),
      ),
    );
  }

  static void showPopup(
    dynamic context,
    String title,
    List<Widget> content,
    List<Widget> actions,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(80),
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          backgroundColor: Colors.white.withAlpha(230),
          shadowColor: Colors.transparent,
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontFamily: 'Comfortaa',
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(children: content),
          ),
          actions: actions,
        );
      },
    );
  }

  static void showMessageDialog(
    dynamic context,
    String title,
    String content,
    VoidCallback callback,
  ) {
    WidgetUtils.showPopup(
      context,
      title,
      <Widget>[
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Comfortaa',
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
      <Widget>[
        TextButton(
          child: const Text(
            "OK",
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Comfortaa',
              fontWeight: FontWeight.w300,
            ),
          ),
          onPressed: callback,
        ),
      ],
    );
  }

  static Future<void> showConsole(dynamic context, dynamic process, {String? gameDirectory}) async {
    final String targetDirectory = gameDirectory ?? Globals.gamefoldercontroller.text;

    WidgetUtils.showPopup(
      context,
      "Console",
      <Widget>[
        // Un solo scroll gestito internamente da VirtualizedLogView
        SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.6,
          child: VirtualizedLogView(
            controller: Globals.consolecontroller,
            backgroundColor: Colors.white.withAlpha(128),
            textColor: Colors.black,
            fontSize: 10,
            fontFamily: 'JetBrainsMono',
            wrapLines: true,
            minWidth: MediaQuery.of(context).size.width - 20,
          ),
        ),
      ],
      <Widget>[
        IconButton(
          iconSize: 30,
          icon: const Icon(Icons.help, color: Colors.blueAccent),
          onPressed: () {
            WidgetUtils.showDiagnostic(context);
          },
        ),
        IconButton(
          iconSize: 30,
          icon: const Icon(Icons.cleaning_services, color: Colors.blueAccent),
          onPressed: () async {
            Globals.consolecontroller.clear();
            Globals.consolecontroller.appendLine("[LAUNCHER]: ${AppLocalizations.of(context)!.console_clear_msg}\n");
          },
        ),
        IconButton(
          iconSize: 30,
          icon: const Icon(Icons.folder, color: Colors.orange),
          onPressed: () async {
            final Uri _url;
            if (Platform.isWindows) {
              _url = Uri.parse('file:///$targetDirectory');
            } else {
              _url = Uri.parse('file://$targetDirectory');
            }
            if (!await launchUrl(_url)) {
              throw Exception('Could not launch $_url');
            }
          },
        ),
        IconButton(
          iconSize: 30,
          icon: Icon(Icons.logout, color: ColorUtils.dynamicAccentColor.withAlpha(255)),
          onPressed: () {
            showPopup(
              context,
              AppLocalizations.of(context)!.console_exit_title,
              <Widget>[
                Text(
                  "${AppLocalizations.of(context)!.console_exit_msg1}\n${AppLocalizations.of(context)!.console_exit_msg2}",
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'Comfortaa',
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ],
              <Widget>[
                TextButton(
                  child: Text(
                    AppLocalizations.of(context)!.generic_cancel,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Comfortaa',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: Text(
                    AppLocalizations.of(context)!.console_exit_kill,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'Comfortaa',
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                  onPressed: () {
                    process.kill();
                    Globals.consolecontroller.appendLine("[LAUNCHER]: ${AppLocalizations.of(context)!.console_game_kill_msg}");
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
                TextButton(
                  child: Text(
                    AppLocalizations.of(context)!.console_exit_only,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Comfortaa',
                      fontWeight: FontWeight.w700,
                      color: ColorUtils.dynamicAccentColor.withAlpha(255),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        ),
      ],
    );

    process.stdout.transform(systemEncoding.decoder).forEach((chunk) {
      Globals.consolecontroller.append(chunk);
    });
    process.stderr.transform(systemEncoding.decoder).forEach((chunk) {
      Globals.consolecontroller.append(chunk);
    });
  }

  static void showDiagnostic(dynamic context) {
    Globals.diagnosticcontroller.clear();
    Globals.diagnosticcontroller.appendLine("------- System info -------");
    Globals.diagnosticcontroller.appendLine("Build: ${Globals.buildVersion}");
    Globals.diagnosticcontroller.appendLine("Platform: ${Platform.version}");
    Globals.diagnosticcontroller.appendLine("Operating system: ${Platform.operatingSystemVersion}");
    Globals.diagnosticcontroller.appendLine("Locale: ${Platform.localeName}");
    Globals.diagnosticcontroller.appendLine("Machine name: ${Platform.localHostname}");
    Globals.diagnosticcontroller.appendLine("CPU cores: ${Platform.numberOfProcessors}");
    Globals.diagnosticcontroller.appendLine("Java executable: ${Globals.javapathcontroller.text}");
    Globals.diagnosticcontroller.appendLine("Java Ram: ${Globals.javaramcontroller.text}");
    Globals.diagnosticcontroller.appendLine("Java advanced settings: ${Globals.javaAdvSet}");
    Globals.diagnosticcontroller.appendLine("Java args: ${Globals.javavmcontroller.text}");
    Globals.diagnosticcontroller.appendLine("Launcher args: ${Globals.javalaunchercontroller.text}");
    Globals.diagnosticcontroller.appendLine("------- Installed versions -------");
    for (var version in VersionUtils.getMinecraftOfflineVersions(false)) {
      Globals.diagnosticcontroller.appendLine("Type: ${version["type"]}, Version: ${version["id"]}");
    }
    for (var version in VersionUtils.getMinecraftOfflineVersions(true)) {
      Globals.diagnosticcontroller.appendLine("Type: ${version["type"]}, Version: ${version["id"]}");
    }
    if (Globals.accounts.isNotEmpty) {
      Globals.diagnosticcontroller.appendLine("------- Accounts -------");
      for (var account in Globals.accounts) {
        Globals.diagnosticcontroller.appendLine("Username: ${account.username}, UUID: ${account.uuid}, Premium: ${account.isPremium}, Slim skin: ${account.isSlimSkin}");
      }
    }
    Globals.diagnosticcontroller.appendLine("------- Game crashlog -------");
    for (final line in Globals.consolecontroller.lines) {
      Globals.diagnosticcontroller.appendLine(line);
    }

    WidgetUtils.showPopup(
      context,
      AppLocalizations.of(context)!.settings_diagnostic_title,
      <Widget>[
        SizedBox(
          width: double.maxFinite,
          height: 400,
          child: VirtualizedLogView(
            controller: Globals.diagnosticcontroller,
            backgroundColor: Colors.white.withAlpha(128),
            textColor: Colors.black,
            fontSize: 10,
            fontFamily: 'JetBrainsMono',
            autoScroll: false,
          ),
        ),
      ],
      [
        TextButton(
          child: Text(
            AppLocalizations.of(context)!.settings_diagnostic_copy,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Comfortaa',
              fontWeight: FontWeight.w700,
              color: ColorUtils.dynamicAccentColor.withAlpha(255),
            ),
          ),
          onPressed: () async {
            await Clipboard.setData(
              ClipboardData(text: Globals.diagnosticcontroller.text),
            );
          },
        ),
        TextButton(
          child: Text(
            AppLocalizations.of(context)!.console_exit_only,
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Comfortaa',
              fontWeight: FontWeight.w700,
              color: ColorUtils.dynamicAccentColor.withAlpha(255),
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  static void showLoadingCircle(dynamic context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Image.asset('assets/morpheus-animated.gif', width: 64),
          ),
        );
      },
    );
  }

  static TextStyle customTextStyle(double size, FontWeight weight, Color textColor) {
    return TextStyle(
      fontSize: size,
      fontFamily: 'Comfortaa',
      fontFamilyFallback: const [
        'Noto Sans CJK SC',
        'PingFang SC',
        'Hiragino Sans',
        'Microsoft YaHei',
        'Yu Gothic',
        'Malgun Gothic',
        'Noto Sans',
      ],
      fontWeight: weight,
      color: textColor,
      shadows: [
        Shadow(
          color: ColorUtils.defaultShadowColor,
          // Choose the color of the shadow
          blurRadius: 15.0,
          offset: const Offset(2.0, 2.0),
        ),
      ],
    );
  }

  static Widget backShadow(Widget child, dynamic radius, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: <BoxShadow>[
          BoxShadow(color: color, blurRadius: radius, offset: const Offset(0, 0)),
        ],
      ),
      child: child,
    );
  }
}

Widget drawTitleCustomBar() {
  final titleBar = SizedBox(
    height: Platform.isMacOS ? 28 : null,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!Platform.isMacOS) ...[
          const SizedBox(width: 10),
          WidgetUtils.backShadow(
            Image.asset("assets/morpheus.png", width: 18),
            40.0,
            ColorUtils.defaultShadowColor,
          ),
          const SizedBox(width: 5),
        ],
        Material(
          color: Colors.transparent,
          child: WidgetUtils.backShadow(
            Text(Globals.windowTitle, style: WidgetUtils.customTextStyle(12, FontWeight.w400, ColorUtils.primaryFontColor)),
            40.0,
            ColorUtils.defaultShadowColor,
          ),
        ),
        if (!Platform.isMacOS) ...[
          Expanded(child: MoveWindow()),
          WidgetUtils.backShadow(
            const WindowButtons(),
            40.0,
            ColorUtils.defaultShadowColor,
          ),
        ],
      ],
    ),
  );

  return Platform.isMacOS ? titleBar : WindowTitleBarBox(child: titleBar);
}

class WindowButtons extends StatefulWidget {
  const WindowButtons({super.key});

  @override
  _WindowButtonsState createState() => _WindowButtonsState();
}

class _WindowButtonsState extends State<WindowButtons> {
  void maximizeOrRestore() {
    setState(() {
      appWindow.maximizeOrRestore();
    });
  }

  final buttonColors = WindowButtonColors(
    iconNormal: ColorUtils.primaryFontColor,
    mouseOver: const Color(0x66FFFFFF),
    mouseDown: const Color(0xCCFFFFFF),
    iconMouseOver: Colors.white,
    iconMouseDown: Colors.white,
  );

  final closeButtonColors = WindowButtonColors(
    iconNormal: ColorUtils.primaryFontColor,
    mouseOver: const Color(0xFFD32F2F),
    mouseDown: const Color(0xFFB71C1C),
    iconMouseOver: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors, onPressed: maximizeOrRestore),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}
