import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:morpheus_launcher_gui/globals.dart';
import 'package:morpheus_launcher_gui/l10n/app_localizations.dart';
import 'package:morpheus_launcher_gui/utils/launcher/modrinth_utils.dart';
import 'package:morpheus_launcher_gui/utils/widget_utils.dart';

import '../utils/markdown/flutter_markdown_plus.dart';

class ModpackDetailView extends StatefulWidget {
  final dynamic modpack;

  const ModpackDetailView({super.key, required this.modpack});

  @override
  State<ModpackDetailView> createState() => _ModpackDetailViewState();
}

class _ModpackDetailViewState extends State<ModpackDetailView> {
  bool _isLoading = true;
  bool _isLoadingMods = false;
  dynamic _projectData;
  dynamic _latestVersion;
  List<dynamic> _dependencies = [];
  Map<String, dynamic> _modDetails = {};

  // ── Install state ──────────────────────────────
  bool _isInstalled = false;
  bool _isInstalling = false;
  double _installProgress = 0.0;
  String _installStatus = '';

  @override
  void initState() {
    super.initState();
    _fetchDetails();
    _checkInstalled();
  }

  void _checkInstalled() {
    final slug = widget.modpack["slug"]?.toString() ?? '';
    if (slug.isNotEmpty) {
      setState(() => _isInstalled = ModrinthUtils.instanceExists(slug));
    }
  }

  Future<void> _fetchDetails() async {
    final projectId = widget.modpack["project_id"];
    try {
      final projectRes = await http.get(Uri.parse("${Urls.modrinthApiURL}/project/$projectId"));
      final versionsRes = await http.get(Uri.parse("${Urls.modrinthApiURL}/project/$projectId/version"));

      if (projectRes.statusCode == 200 && versionsRes.statusCode == 200) {
        _projectData = json.decode(utf8.decode(projectRes.bodyBytes));
        final versions = json.decode(utf8.decode(versionsRes.bodyBytes)) as List;
        if (versions.isNotEmpty) {
          _latestVersion = versions.first;
          _dependencies = _latestVersion["dependencies"] ?? [];
        }
      }
    } catch (e) {
      debugPrint("Error fetching modpack details: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (_dependencies.isNotEmpty) _fetchModDetails();
  }

  Future<void> _fetchModDetails() async {
    if (mounted) setState(() => _isLoadingMods = true);
    try {
      final ids = _dependencies.map<String?>((dep) => dep["project_id"]?.toString()).whereType<String>().toSet().toList();
      if (ids.isEmpty) return;

      final idsParam = Uri.encodeQueryComponent(json.encode(ids));
      final res = await http.get(Uri.parse("${Urls.modrinthApiURL}/projects?ids=$idsParam"));
      if (res.statusCode == 200) {
        final projects = json.decode(res.body) as List;
        final map = <String, dynamic>{};
        for (final p in projects) {
          final id = p["id"]?.toString();
          if (id != null) map[id] = p;
        }
        if (mounted) setState(() => _modDetails = map);
      }
    } catch (e) {
      debugPrint("Error fetching mod details: $e");
    } finally {
      if (mounted) setState(() => _isLoadingMods = false);
    }
  }

  // ── Install / uninstall ────────────────────────

  Future<void> _install() async {
    final projectId = widget.modpack["project_id"]?.toString() ?? '';
    final slug = widget.modpack["slug"]?.toString() ?? '';
    final title = widget.modpack["title"]?.toString() ?? slug;
    final iconUrl = widget.modpack["icon_url"]?.toString() ?? '';

    if (projectId.isEmpty || slug.isEmpty) return;

    setState(() {
      _isInstalling = true;
      _installProgress = 0.0;
      _installStatus = '';
    });

    try {
      await ModrinthUtils.installModpack(
        projectId: projectId,
        slug: slug,
        title: title,
        iconUrl: iconUrl,
        onProgress: (p) {
          if (mounted) setState(() => _installProgress = p);
        },
        onStatus: (s) {
          if (mounted) setState(() => _installStatus = s);
        },
      );
      if (mounted) setState(() => _isInstalled = true);
    } catch (e) {
      debugPrint("Install error: $e");
      if (mounted) {
        WidgetUtils.showMessageDialog(
          context,
          AppLocalizations.of(context)!.generic_error_msg,
          e.toString(),
          () => Navigator.pop(context),
        );
      }
    } finally {
      if (mounted) setState(() => _isInstalling = false);
    }
  }

  void _uninstall() {
    final slug = widget.modpack["slug"]?.toString() ?? '';
    final title = widget.modpack["title"]?.toString() ?? slug;

    WidgetUtils.showPopup(
      context,
      title,
      <Widget>[
        const Text(
          'Remove this modpack and all its files?',
          style: TextStyle(
            fontSize: 14,
            fontFamily: 'Comfortaa',
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
      <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppLocalizations.of(context)!.generic_cancel,
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Comfortaa',
              fontWeight: FontWeight.w300,
            ),
          ),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context);
            await ModrinthUtils.removeInstance(slug);
            if (mounted) setState(() => _isInstalled = false);
          },
          child: const Text(
            'Remove',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Comfortaa',
              fontWeight: FontWeight.w700,
              color: Colors.redAccent,
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────
  //  Build
  // ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorUtils.dynamicWindowBackgroundColor,
      body: Column(
        children: [
          drawTitleCustomBar(),
          _buildTopBar(context),
          Expanded(
            child: _isLoading ? Center(child: Image.asset('assets/morpheus-animated.gif', width: 64)) : _buildContent(),
          ),
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
            widget.modpack["title"] ?? AppLocalizations.of(context)!.modpack_details_title,
            style: WidgetUtils.customTextStyle(24, FontWeight.w600, ColorUtils.primaryFontColor),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStats(),
          const SizedBox(height: 24),
          _buildDownloadButton(),
          if ((_projectData?["body"] ?? '').toString().trim().isNotEmpty) ...[
            // ← fix condizione
            const SizedBox(height: 24),
            _buildDescription(),
          ],
          const SizedBox(height: 24),
          if (_dependencies.isNotEmpty) _buildModList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
          child: CachedNetworkImage(
            imageUrl: widget.modpack["icon_url"] ?? "",
            width: 120,
            height: 120,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(color: Colors.white.withOpacity(0.05)),
            errorWidget: (context, url, error) => Icon(Icons.apps, size: 60, color: ColorUtils.secondaryFontColor),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.modpack["title"] ?? "", style: WidgetUtils.customTextStyle(28, FontWeight.bold, ColorUtils.primaryFontColor)),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.modpack_author_by(
                  widget.modpack["author"] ?? AppLocalizations.of(context)!.modpack_unknown_author,
                ),
                style: WidgetUtils.customTextStyle(16, FontWeight.w400, ColorUtils.secondaryFontColor),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (widget.modpack["categories"] as List? ?? []).map<Widget>((cat) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: ColorUtils.dynamicAccentColor.withOpacity(0.1),
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      border: Border.all(color: ColorUtils.dynamicAccentColor.withOpacity(0.3)),
                    ),
                    child: Text(cat.toString().toUpperCase(), style: WidgetUtils.customTextStyle(10, FontWeight.bold, ColorUtils.dynamicAccentColor)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: ColorUtils.dynamicPrimaryForegroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.download, AppLocalizations.of(context)!.modpack_stats_downloads, _formatNumber(widget.modpack["downloads"])),
          _buildStatItem(Icons.update, AppLocalizations.of(context)!.modpack_stats_updated, _formatDate(widget.modpack["date_modified"])),
          _buildStatItem(Icons.sd_storage, AppLocalizations.of(context)!.modpack_stats_size, _formatSize(_getFileSize())),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: ColorUtils.dynamicAccentColor, size: 24),
        const SizedBox(height: 8),
        Text(label.toUpperCase(), style: WidgetUtils.customTextStyle(10, FontWeight.w500, ColorUtils.secondaryFontColor)),
        const SizedBox(height: 4),
        Text(value, style: WidgetUtils.customTextStyle(16, FontWeight.w600, ColorUtils.primaryFontColor)),
      ],
    );
  }

  /// Three states: installing (progress bar) → installed (Remove) → not installed (Download).
  Widget _buildDownloadButton() {
    // ── Installing ─────────────────────────────────────────────────────────
    if (_isInstalling) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: ColorUtils.dynamicPrimaryForegroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _installStatus,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: WidgetUtils.customTextStyle(13, FontWeight.w400, ColorUtils.secondaryFontColor),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(_installProgress * 100).toInt()}%',
                  style: WidgetUtils.customTextStyle(13, FontWeight.w600, ColorUtils.primaryFontColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: LinearProgressIndicator(
                value: _installProgress,
                minHeight: 8,
                backgroundColor: ColorUtils.dynamicSecondaryForegroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(ColorUtils.dynamicAccentColor),
              ),
            ),
          ],
        ),
      );
    }

    // ── Already installed ──────────────────────────────────────────────────
    if (_isInstalled) {
      return SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton.icon(
          onPressed: _uninstall,
          icon: const Icon(Icons.delete_outline, size: 22, color: Colors.white),
          label: Text('Remove modpack', style: WidgetUtils.customTextStyle(16, FontWeight.bold, Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            elevation: 0,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(Globals.borderRadius)),
            ),
          ),
        ),
      );
    }

    // ── Not installed ──────────────────────────────────────────────────────
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(
        onPressed: _install,
        icon: const Icon(Icons.download, size: 22, color: Colors.white),
        label: Text(
          AppLocalizations.of(context)!.modpack_download_button,
          style: WidgetUtils.customTextStyle(16, FontWeight.bold, Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorUtils.dynamicAccentColor,
          elevation: 0,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(Globals.borderRadius)),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  //  Description with collapsible <details> support
  // ──────────────────────────────────────────────

  Widget _buildDescription() {
    final body = (_projectData?["body"] ?? '').toString().trim();
    if (body.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.modpack_description_title, style: WidgetUtils.customTextStyle(20, FontWeight.bold, ColorUtils.primaryFontColor)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorUtils.dynamicPrimaryForegroundColor,
            borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _parseDescriptionSegments(body),
          ),
        ),
      ],
    );
  }

  /// Splits raw markdown/HTML into plain-markdown segments and `<details>` blocks,
  /// returning a list of ready-to-render widgets.
  List<Widget> _parseDescriptionSegments(String content) {
    final widgets = <Widget>[];
    final detailsRe = RegExp(r'<details>(.*?)</details>', dotAll: true);
    final summaryRe = RegExp(r'<summary>(.*?)</summary>', dotAll: true);

    int cursor = 0;
    for (final match in detailsRe.allMatches(content)) {
      if (match.start > cursor) {
        final before = content.substring(cursor, match.start).trim();
        if (before.isNotEmpty) widgets.add(_markdownWidget(before));
      }

      final inner = match.group(1)!;
      final summaryMatch = summaryRe.firstMatch(inner);
      final summaryTitle = summaryMatch?.group(1)?.trim() ?? '';
      final body = inner.replaceFirst(summaryRe, '').trim();

      widgets.add(_buildDetailsSection(summaryTitle, body));
      cursor = match.end;
    }

    if (cursor < content.length) {
      final tail = content.substring(cursor).trim();
      if (tail.isNotEmpty) widgets.add(_markdownWidget(tail));
    }

    return widgets;
  }

  /// Renders a `<details>` block as a styled, collapsible [ExpansionTile].
  Widget _buildDetailsSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: Container(
          decoration: BoxDecoration(
            color: ColorUtils.dynamicSecondaryForegroundColor.withOpacity(0.25),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            border: Border.all(color: ColorUtils.dynamicAccentColor.withOpacity(0.18), width: 1),
          ),
          child: Theme(
            // Remove the default ExpansionTile divider lines.
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              iconColor: ColorUtils.dynamicAccentColor,
              collapsedIconColor: ColorUtils.secondaryFontColor.withOpacity(0.6),
              // Custom leading chevron; suppress default trailing arrow.
              leading: Icon(Icons.chevron_right, size: 18, color: ColorUtils.dynamicAccentColor.withOpacity(0.7)),
              trailing: const SizedBox.shrink(),
              title: Text(
                title,
                style: WidgetUtils.customTextStyle(14, FontWeight.w600, ColorUtils.dynamicAccentColor),
              ),
              children: [
                Divider(color: ColorUtils.dynamicAccentColor.withOpacity(0.15), height: 1, thickness: 1),
                const SizedBox(height: 10),
                _markdownWidget(body),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shared markdown renderer used for both plain content and details bodies.
  Widget _markdownWidget(String data) {
    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        p: WidgetUtils.customTextStyle(15, FontWeight.w300, ColorUtils.secondaryFontColor.withOpacity(0.9)),
        h1: WidgetUtils.customTextStyle(22, FontWeight.bold, ColorUtils.primaryFontColor),
        h2: WidgetUtils.customTextStyle(20, FontWeight.bold, ColorUtils.primaryFontColor),
        h3: WidgetUtils.customTextStyle(18, FontWeight.bold, ColorUtils.primaryFontColor),
        h4: WidgetUtils.customTextStyle(16, FontWeight.w600, ColorUtils.primaryFontColor),
        code: WidgetUtils.customTextStyle(14, FontWeight.w400, ColorUtils.primaryFontColor).copyWith(backgroundColor: Colors.black26),
        listBullet: WidgetUtils.customTextStyle(15, FontWeight.w300, ColorUtils.secondaryFontColor),
        blockquote: WidgetUtils.customTextStyle(14, FontWeight.w400, ColorUtils.primaryFontColor),
        blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        blockquoteDecoration: BoxDecoration(
          color: ColorUtils.dynamicSecondaryForegroundColor.withOpacity(0.25),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          border: Border(left: BorderSide(color: ColorUtils.dynamicAccentColor, width: 4)),
        ),
        a: WidgetUtils.customTextStyle(15, FontWeight.w500, ColorUtils.primaryFontColor.withOpacity(0.5)),
        tableHead: WidgetUtils.customTextStyle(13, FontWeight.bold, ColorUtils.primaryFontColor),
        tableBody: WidgetUtils.customTextStyle(13, FontWeight.w300, ColorUtils.secondaryFontColor),
        tableHeadAlign: TextAlign.center,
        tableBorder: TableBorder.all(color: Colors.white.withOpacity(0.1), width: 1),
        tableColumnWidth: const FlexColumnWidth(),
        tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        codeblockDecoration: BoxDecoration(
          color: ColorUtils.dynamicSecondaryForegroundColor,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        codeblockPadding: const EdgeInsets.all(12),
        tableCellsDecoration: BoxDecoration(color: ColorUtils.dynamicSecondaryForegroundColor),
        tableHeadCellsDecoration: BoxDecoration(color: ColorUtils.dynamicSecondaryForegroundColor.withOpacity(0.5)),
      ),
    );
  }

  Widget _buildModList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppLocalizations.of(context)!.modpack_mod_list_title, style: WidgetUtils.customTextStyle(20, FontWeight.bold, ColorUtils.primaryFontColor)),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ColorUtils.dynamicAccentColor.withOpacity(0.15),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Text("${_dependencies.length}", style: WidgetUtils.customTextStyle(12, FontWeight.bold, ColorUtils.dynamicAccentColor)),
            ),
            if (_isLoadingMods) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: ColorUtils.dynamicAccentColor),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: ColorUtils.dynamicPrimaryForegroundColor,
            borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dependencies.length,
            separatorBuilder: (context, index) => Divider(color: Colors.white.withOpacity(0.05), height: 1),
            itemBuilder: (context, index) => _buildModItem(_dependencies[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildModItem(dynamic dep) {
    final projectId = dep["project_id"]?.toString();
    final modData = projectId != null ? _modDetails[projectId] : null;
    final title = modData?["title"]?.toString() ?? AppLocalizations.of(context)!.modpack_unknown_mod;
    final iconUrl = modData?["icon_url"]?.toString();
    final depType = (dep["dependency_type"] ?? "").toString().toUpperCase();

    Color depColor;
    switch (dep["dependency_type"]?.toString()) {
      case "required":
        depColor = Colors.greenAccent;
        break;
      case "optional":
        depColor = Colors.orangeAccent;
        break;
      case "incompatible":
        depColor = Colors.redAccent;
        break;
      default:
        depColor = ColorUtils.secondaryFontColor;
    }

    return ListTile(
      dense: true,
      leading: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        child: iconUrl != null && iconUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: iconUrl,
                width: 36,
                height: 36,
                fit: BoxFit.cover,
                placeholder: (context, url) => _modIconPlaceholder(),
                errorWidget: (context, url, error) => _modIconPlaceholder(),
              )
            : _modIconPlaceholder(),
      ),
      title: Text(title, style: WidgetUtils.customTextStyle(14, FontWeight.w500, ColorUtils.primaryFontColor)),
      subtitle: Text(depType, style: WidgetUtils.customTextStyle(11, FontWeight.w300, depColor)),
      trailing: Icon(
        dep["dependency_type"] == "required" ? Icons.check_circle_outline : Icons.info_outline,
        color: depColor.withOpacity(0.7),
        size: 16,
      ),
    );
  }

  Widget _modIconPlaceholder() {
    return Container(
      width: 36,
      height: 36,
      color: ColorUtils.dynamicSecondaryForegroundColor,
      child: Icon(Icons.extension_outlined, size: 20, color: ColorUtils.secondaryFontColor),
    );
  }

  // ──────────────────────────────────────────────
  //  Helpers
  // ──────────────────────────────────────────────

  int _getFileSize() {
    if (_latestVersion != null && _latestVersion["files"] != null && (_latestVersion["files"] as List).isNotEmpty) {
      return _latestVersion["files"][0]["size"] ?? 0;
    }

    return 0;
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

  String _formatDate(dynamic date) {
    if (date == null) return "N/A";
    try {
      final dt = DateTime.parse(date.toString());

      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (e) {
      return "N/A";
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return "N/A";
    const units = ["B", "KB", "MB", "GB", "TB"];
    var idx = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && idx < units.length - 1) {
      size /= 1024;
      idx++;
    }

    return "${size.toStringAsFixed(1)} ${units[idx]}";
  }
}
