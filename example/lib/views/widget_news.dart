import 'dart:convert';

import 'package:blur/blur.dart';
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

  const NewsScreen({
    super.key,
    required this.title,
    required this.body,
    required this.url,
    this.detailPath,
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: (MediaQuery.of(context).size.width / 5) - 5,
      child: Material(
        elevation: 15,
        color: ColorUtils.dynamicWindowBackgroundColor,
        shadowColor: Colors.black.withAlpha(60),
        child: Column(
          children: [
            drawTitleCustomBar(),

            /** Roba della miniatura e titolo */
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Image.network(
                    "${Urls.mojangContentURL}${widget.url}",
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height / 4,
                    fit: BoxFit.cover,
                  ).blurred(
                    blur: 4,
                    blurColor: Colors.black,
                    colorOpacity: 0.3,
                  ),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width / 20,
                      fontFamily: 'Comfortaa',
                      color: Colors.white.withAlpha(160),
                    ),
                  ),
                ],
              ),
            ),

            /** Mostra il contenuto */
            Expanded(
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  scrollbars: true,
                ),
                child: ListView(
                  children: [
                    if (_isLoading)
                      LinearProgressIndicator(
                        minHeight: 2,
                        color: ColorUtils.dynamicAccentColor,
                        backgroundColor: Colors.transparent,
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Html(
                        style: {
                          "*": Style(
                            color: Globals.darkModeTheme ? Colors.white.withAlpha(160) : Colors.black.withAlpha(200),
                            fontFamily: 'Comfortaa',
                          ),
                          "h1": Style(
                            color: Globals.darkModeTheme ? Colors.white.withAlpha(200) : Colors.black,
                          ),
                          "h2": Style(
                            color: Globals.darkModeTheme ? Colors.white.withAlpha(200) : Colors.black,
                          ),
                          "h3": Style(
                            color: Globals.darkModeTheme ? Colors.white.withAlpha(200) : Colors.black,
                          ),
                          "code": Style(
                            color: ColorUtils.dynamicAccentColor.withAlpha(255),
                          ),
                          "a": Style(
                            color: ColorUtils.dynamicAccentColor.withAlpha(255),
                          ),
                          "blockquote": Style(
                            backgroundColor: ColorUtils.dynamicSecondaryForegroundColor.withAlpha(40),
                            padding: HtmlPaddings.symmetric(horizontal: 16, vertical: 8),
                            border: Border(left: BorderSide(color: ColorUtils.dynamicAccentColor, width: 4)),
                            margin: Margins.symmetric(vertical: 10),
                          ),
                        },
                        data: _body,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
