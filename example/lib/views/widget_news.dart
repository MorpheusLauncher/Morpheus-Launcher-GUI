import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'package:morpheus_launcher_gui/globals.dart';
import 'package:morpheus_launcher_gui/utils/widget_utils.dart';

class NewsScreen extends StatefulWidget {
  final String title;
  final String body;
  final String url;
  final String? detailPath;
  final String? date;

  const NewsScreen({
    super.key,
    required this.title,
    required this.body,
    required this.url,
    this.detailPath,
    this.date,
  });

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late String _body;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _body = widget.body;
    _loadFullBody();
  }

  Future<void> _loadFullBody() async {
    final detailPath = widget.detailPath;
    if (detailPath == null || detailPath.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse("${Urls.mojangContentURL}$detailPath"),
      );
      if (response.statusCode != 200) return;

      final detail = json.decode(utf8.decode(response.bodyBytes));
      final fullBody = detail["body"]?.toString();
      if (mounted && fullBody != null && fullBody.isNotEmpty) {
        setState(() => _body = fullBody);
      }
    } catch (error) {
      debugPrint("Unable to load full Java changelog: $error");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? get _formattedDate {
    final date = widget.date;
    if (date == null || date.isEmpty) return null;
    try {
      final dt = DateTime.parse(date).toLocal();

      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // A differenza della vecchia versione (larga solo 1/5 della finestra,
    // rendendo l'articolo illeggibile), questa pagina usa tutta la larghezza
    // disponibile e centra il contenuto testuale in una colonna di
    // larghezza confortevole per la lettura (vedi _buildBody).
    return Material(
      color: ColorUtils.dynamicWindowBackgroundColor,
      child: Column(
        children: [
          drawTitleCustomBar(),
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildHero(context),
                      _buildBody(context),
                    ],
                  ),
                ),
                if (_isLoading)
                  Align(
                    alignment: Alignment.topCenter,
                    child: LinearProgressIndicator(
                      minHeight: 2,
                      color: ColorUtils.dynamicAccentColor,
                      backgroundColor: Colors.transparent,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    // Banner edge-to-edge (niente margini né bordi arrotondati): il
    // pulsante indietro non vive più in una barra a parte sopra l'immagine,
    // ma galleggia direttamente su di essa, sempre visibile grazie allo
    // sfondo circolare semi-trasparente.
    return AspectRatio(
      aspectRatio: 16 / 6,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            "${Urls.mojangContentURL}${widget.url}",
            fit: BoxFit.cover,
          ),
          // Gradiente in basso, non un blur/scurimento uniforme: la
          // miniatura resta ben visibile e il titolo comunque leggibile.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withAlpha(200)],
                stops: const [0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: _buildFloatingBackButton(context),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: WidgetUtils.customTextStyle(24, FontWeight.w700, Colors.white),
                ),
                if (_formattedDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formattedDate!,
                    style: WidgetUtils.customTextStyle(13, FontWeight.w500, Colors.white.withAlpha(200)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBackButton(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(110),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.pop(context),
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  /// Colonna di contenuto centrata a larghezza fissa: su una finestra larga,
  /// del testo che si estende da un bordo all'altro dello schermo è
  /// scomodo da leggere (righe troppo lunghe). 720px tiene la lunghezza
  /// delle righe in una zona confortevole, come in un articolo di blog.
  Widget _buildBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Html(
            style: {
              "body": Style(
                margin: Margins.zero,
                fontSize: FontSize(14),
                lineHeight: const LineHeight(1.5),
                color: Globals.darkModeTheme ? Colors.white.withAlpha(200) : Colors.black.withAlpha(210),
                fontFamily: 'Comfortaa',
              ),
              "p": Style(
                margin: Margins.only(bottom: 10),
              ),
              "h1": Style(
                fontSize: FontSize(21),
                margin: Margins.only(top: 18, bottom: 8),
                color: Globals.darkModeTheme ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
              ),
              "h2": Style(
                fontSize: FontSize(18),
                margin: Margins.only(top: 16, bottom: 8),
                color: Globals.darkModeTheme ? Colors.white : Colors.black,
                fontWeight: FontWeight.w700,
              ),
              "h3": Style(
                fontSize: FontSize(15),
                margin: Margins.only(top: 14, bottom: 6),
                color: Globals.darkModeTheme ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
              "img": Style(
                margin: Margins.symmetric(vertical: 10),
              ),
              "ul": Style(
                margin: Margins.only(bottom: 10),
              ),
              "li": Style(
                margin: Margins.only(bottom: 4),
              ),
              "code": Style(
                fontSize: FontSize(13),
                color: ColorUtils.dynamicAccentColor,
                backgroundColor: ColorUtils.dynamicSecondaryForegroundColor.withAlpha(60),
                padding: HtmlPaddings.symmetric(horizontal: 4),
              ),
              "a": Style(
                color: ColorUtils.dynamicAccentColor,
              ),
              "blockquote": Style(
                backgroundColor: ColorUtils.dynamicSecondaryForegroundColor.withAlpha(40),
                padding: HtmlPaddings.symmetric(horizontal: 14, vertical: 6),
                border: Border(left: BorderSide(color: ColorUtils.dynamicAccentColor, width: 4)),
                margin: Margins.symmetric(vertical: 10),
              ),
            },
            data: _body,
          ),
        ),
      ),
    );
  }
}
