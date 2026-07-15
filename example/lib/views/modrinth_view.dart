import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:morpheus_launcher_gui/globals.dart';
import 'package:morpheus_launcher_gui/l10n/app_localizations.dart';
import 'package:morpheus_launcher_gui/utils/widget_utils.dart';
import 'package:morpheus_launcher_gui/views/modpack_detail_view.dart';

class ModrinthView extends StatefulWidget {
  const ModrinthView({super.key});

  @override
  State<ModrinthView> createState() => _ModrinthViewState();
}

class _ModrinthViewState extends State<ModrinthView> {
  static const int _pageSize = 50;

  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _modpacks = [];
  bool _isLoading = false;
  int _page = 0;
  int _totalHits = 0;
  int _searchRequestId = 0;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
    _searchModpacks("");
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  int get _pageCount {
    if (_totalHits <= 0) return 1;

    return ((_totalHits - 1) ~/ _pageSize) + 1;
  }

  bool get _showPagination => _totalHits > _pageSize || _page > 0;

  Future<void> _searchModpacks(String query, {int page = 0}) async {
    final requestId = ++_searchRequestId;
    final normalizedPage = page < 0 ? 0 : page;

    setState(() {
      _isLoading = true;
      _page = normalizedPage;
    });

    try {
      final uri = Uri.parse("${Urls.modrinthApiURL}/search").replace(
        queryParameters: {
          "query": query.trim(),
          "facets": '[["project_type:modpack"]]',
          "limit": _pageSize.toString(),
          "offset": (normalizedPage * _pageSize).toString(),
        },
      );
      final response = await http.get(uri);

      if (!mounted || requestId != _searchRequestId) return;

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final hits = data["hits"] is List ? data["hits"] as List : <dynamic>[];
        final totalHits = data["total_hits"] is int ? data["total_hits"] as int : hits.length;

        setState(() {
          _modpacks = hits;
          _totalHits = totalHits;
          _isLoading = false;
        });
      } else {
        setState(() {
          _modpacks = [];
          _totalHits = 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted || requestId != _searchRequestId) return;

      setState(() {
        _modpacks = [];
        _totalHits = 0;
        _isLoading = false;
      });
    }
  }

  void _goToPage(int page) {
    if (_isLoading || page < 0 || page >= _pageCount || page == _page) return;

    _searchModpacks(_searchController.text, page: page);
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchModpacks(query, page: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorUtils.dynamicWindowBackgroundColor,
      body: Column(
        children: [
          drawTitleCustomBar(),
          _buildTopBar(context),
          _buildSearchBar(context),
          Expanded(
            child: _isLoading ? Center(child: Image.asset('assets/morpheus-animated.gif', width: 64)) : _buildModpackList(),
          ),
          if (_showPagination) _buildPaginationBar(),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: ColorUtils.primaryFontColor),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Text(
            AppLocalizations.of(context)!.modded_modrinth_title,
            style: WidgetUtils.customTextStyle(24, FontWeight.w600, ColorUtils.primaryFontColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        elevation: 0,
        color: ColorUtils.dynamicPrimaryForegroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            style: WidgetUtils.customTextStyle(16, FontWeight.w400, ColorUtils.primaryFontColor),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: AppLocalizations.of(context)!.modded_modrinth_search,
              hintStyle: WidgetUtils.customTextStyle(16, FontWeight.w300, ColorUtils.secondaryFontColor),
              icon: Icon(Icons.search, color: ColorUtils.secondaryFontColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _searchModpacks("", page: 0);
                      },
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationBar() {
    final canGoBack = !_isLoading && _page > 0;
    final canGoForward = !_isLoading && _page < _pageCount - 1;
    final start = _totalHits == 0 ? 0 : (_page * _pageSize) + 1;
    final rawEnd = (_page + 1) * _pageSize;
    final end = rawEnd > _totalHits ? _totalHits : rawEnd;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Material(
        elevation: 0,
        color: ColorUtils.dynamicPrimaryForegroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                color: ColorUtils.primaryFontColor,
                disabledColor: ColorUtils.secondaryFontColor.withAlpha(80),
                onPressed: canGoBack ? () => _goToPage(0) : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color: ColorUtils.primaryFontColor,
                disabledColor: ColorUtils.secondaryFontColor.withAlpha(80),
                onPressed: canGoBack ? () => _goToPage(_page - 1) : null,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 140),
                child: Text(
                  "$start-$end / $_totalHits",
                  textAlign: TextAlign.center,
                  style: WidgetUtils.customTextStyle(14, FontWeight.w500, ColorUtils.primaryFontColor),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color: ColorUtils.primaryFontColor,
                disabledColor: ColorUtils.secondaryFontColor.withAlpha(80),
                onPressed: canGoForward ? () => _goToPage(_page + 1) : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                color: ColorUtils.primaryFontColor,
                disabledColor: ColorUtils.secondaryFontColor.withAlpha(80),
                onPressed: canGoForward ? () => _goToPage(_pageCount - 1) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _modpackGridColumnCount(double width) {
    const minTileWidth = 360.0;
    const spacing = 8.0;
    var columns = ((width + spacing) / (minTileWidth + spacing)).floor();
    if (columns < 1) columns = 1;
    if (columns > 1) columns = (columns - 2).clamp(1, columns);

    return columns;
  }

  Widget _buildModpackList() {
    if (_modpacks.isEmpty && !_isLoading) {
      return Center(
        child: Text(
          AppLocalizations.of(context)!.modded_modrinth_empty,
          style: WidgetUtils.customTextStyle(16, FontWeight.w300, ColorUtils.secondaryFontColor),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth ? constraints.maxWidth : MediaQuery.of(context).size.width;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _modpackGridColumnCount(width),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 124,
          ),
          itemCount: _modpacks.length,
          itemBuilder: (context, index) {
            final modpack = _modpacks[index];

            return _buildModpackItem(modpack);
          },
        );
      },
    );
  }

  Widget _buildModpackItem(dynamic modpack) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        elevation: 0,
        color: ColorUtils.dynamicPrimaryForegroundColor,
        shadowColor: ColorUtils.defaultShadowColor,
        borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ModpackDetailView(modpack: modpack)),
            );
          },
          borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(Globals.borderRadius - 4),
                  child: CachedNetworkImage(
                    imageUrl: modpack["icon_url"] ?? "",
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.white.withOpacity(0.05)),
                    errorWidget: (context, url, error) => Container(
                      width: 100,
                      height: 100,
                      color: Colors.white.withOpacity(0.05),
                      child: Icon(Icons.apps, color: ColorUtils.secondaryFontColor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Replace the Expanded Column in _buildModpackItem with this:
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        modpack["title"] ?? "",
                        style: WidgetUtils.customTextStyle(17, FontWeight.w600, ColorUtils.primaryFontColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppLocalizations.of(context)!.modpack_author_by(
                          modpack["author"] ?? AppLocalizations.of(context)!.modpack_unknown_author,
                        ),
                        style: WidgetUtils.customTextStyle(12, FontWeight.w400, ColorUtils.dynamicAccentColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2), // was 4
                      Flexible(
                        // <-- wrap description in Flexible
                        child: Text(
                          modpack["description"] ?? "",
                          style: WidgetUtils.customTextStyle(13, FontWeight.w300, ColorUtils.secondaryFontColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4), // was 10
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _buildMetaData(Icons.download, _formatNumber(modpack["downloads"]), Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaData(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: WidgetUtils.customTextStyle(12, FontWeight.w400, color),
        ),
      ],
    );
  }

  String _formatNumber(dynamic number) {
    if (number == null) return "0";
    if (number is int) {
      if (number >= 1000000) return "${(number / 1000000).toStringAsFixed(1)}M";
      if (number >= 1000) return "${(number / 1000).toStringAsFixed(1)}K";

      return number.toString();
    }

    return number.toString();
  }
}
