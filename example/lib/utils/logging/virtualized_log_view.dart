import 'package:flutter/material.dart';

import 'log_controller.dart';

/// Regole di colorazione: se la riga contiene una delle stringhe chiave
/// (case-insensitive) viene applicato il colore corrispondente.
/// L'ordine conta: la prima regola che matcha vince.
class LogColorRule {
  final String keyword;
  final Color color;
  final bool caseSensitive;

  const LogColorRule({
    required this.keyword,
    required this.color,
    this.caseSensitive = false,
  });
}

/// Regole predefinite per log Minecraft / Java.
const List<LogColorRule> defaultLogColorRules = [
  LogColorRule(keyword: 'exception', color: Color(0xFFFF5555)),
  LogColorRule(keyword: 'error', color: Color(0xFFFF5555)),
  LogColorRule(keyword: 'severe', color: Color(0xFFFF5555)),
  LogColorRule(keyword: 'fatal', color: Color(0xFFFF5555)),
  LogColorRule(keyword: 'warn', color: Color(0xFFFFB86C)),
  LogColorRule(keyword: 'warning', color: Color(0xFFFFB86C)),
  LogColorRule(keyword: '[launcher]', color: Colors.deepPurpleAccent),
  LogColorRule(keyword: 'info', color: Color(0xFF000000)),
  LogColorRule(keyword: 'debug', color: Color(0xFF6272A4)),
  LogColorRule(keyword: 'at ', color: Color(0xFF6272A4)), // stack trace
];

Color _colorForLine(String line, List<LogColorRule> rules, Color fallback) {
  final lower = line.toLowerCase();
  for (final rule in rules) {
    final keyword = rule.caseSensitive ? rule.keyword : rule.keyword.toLowerCase();
    if ((rule.caseSensitive ? line : lower).contains(keyword)) return rule.color;
  }

  return fallback;
}

/// A high-performance, read-only log viewer that renders **only visible lines**
/// using [ListView.builder]. Supporta:
///   • Colorazione per keyword configurabile
///   • Auto-scroll al fondo con nuove righe
///   • Scroll manuale senza interruzioni
///   • Resume auto-scroll tornando in fondo
///   • [wrapLines] true  → righe a capo, solo scroll verticale
///   • [wrapLines] false → riga singola, itemExtent fisso + scroll orizzontale
class VirtualizedLogView extends StatefulWidget {
  const VirtualizedLogView({
    super.key,
    required this.controller,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.textColor = const Color(0xFF000000),
    this.fontSize = 10.0,
    this.fontFamily = 'JetBrainsMono',
    this.lineHeight = 1.6,
    this.minWidth = 300.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    this.showScrollbar = true,
    this.autoScroll = true,
    this.colorRules = defaultLogColorRules,
    this.wrapLines = true,
  });

  final LogController controller;
  final Color backgroundColor;

  /// Colore di fallback per le righe che non matchano nessuna regola.
  final Color textColor;

  final double fontSize;
  final String fontFamily;
  final double lineHeight;

  /// Usato solo quando [wrapLines] è false (scroll orizzontale).
  final double minWidth;

  final EdgeInsets padding;
  final bool showScrollbar;
  final bool autoScroll;

  /// Regole di colorazione. Passa [] per disabilitare del tutto.
  final List<LogColorRule> colorRules;

  /// true  → righe a capo, altezza variabile, solo scroll verticale.
  /// false → riga singola, itemExtent fisso (O(1)), scroll orizzontale.
  final bool wrapLines;

  @override
  State<VirtualizedLogView> createState() => _VirtualizedLogViewState();
}

class _VirtualizedLogViewState extends State<VirtualizedLogView> {
  late final ScrollController _verticalCtrl;
  late final ScrollController _horizontalCtrl;
  bool _autoScroll = true;

  // Usato solo in modalità no-wrap per itemExtent fisso.
  double get _itemHeight => widget.fontSize * widget.lineHeight * 1.6;

  @override
  void initState() {
    super.initState();
    _autoScroll = widget.autoScroll;
    _verticalCtrl = ScrollController();
    _horizontalCtrl = ScrollController();
    widget.controller.addListener(_onNewLines);
    _verticalCtrl.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant VirtualizedLogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onNewLines);
      widget.controller.addListener(_onNewLines);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onNewLines);
    _verticalCtrl.removeListener(_onScroll);
    _verticalCtrl.dispose();
    _horizontalCtrl.dispose();
    super.dispose();
  }

  void _onNewLines() {
    if (mounted) setState(() {});
    if (_autoScroll) _scrollToBottom();
  }

  void _onScroll() {
    if (!_verticalCtrl.hasClients) return;
    final pos = _verticalCtrl.position;
    // Tolleranza dinamica in base alla modalità.
    final threshold = widget.wrapLines ? widget.fontSize * 4 : _itemHeight;
    final atBottom = pos.pixels >= pos.maxScrollExtent - threshold;
    if (atBottom != _autoScroll) setState(() => _autoScroll = atBottom);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_verticalCtrl.hasClients) {
        _verticalCtrl.jumpTo(_verticalCtrl.position.maxScrollExtent);
      }
    });
  }

  Widget _buildItem(String line) {
    final color = widget.colorRules.isEmpty ? widget.textColor : _colorForLine(line, widget.colorRules, widget.textColor);

    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        line,
        softWrap: widget.wrapLines,
        maxLines: widget.wrapLines ? null : 1,
        style: TextStyle(
          fontSize: widget.fontSize,
          fontFamily: widget.fontFamily,
          fontWeight: FontWeight.w400,
          color: color,
          height: widget.lineHeight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.controller.lines;

    Widget listView;

    if (widget.wrapLines) {
      // Altezza variabile: ListView virtualizza ma senza itemExtent fisso.
      listView = ListView.builder(
        controller: _verticalCtrl,
        itemCount: lines.length,
        padding: widget.padding,
        itemBuilder: (_, index) => _buildItem(lines[index]),
      );
    } else {
      // Altezza fissa: itemExtent → O(1), performance massima.
      listView = ListView.builder(
        controller: _verticalCtrl,
        itemExtent: _itemHeight,
        itemCount: lines.length,
        padding: widget.padding,
        itemBuilder: (_, index) => _buildItem(lines[index]),
      );
    }

    Widget content;

    if (widget.wrapLines) {
      // Solo scroll verticale — niente scroll orizzontale annidato.
      content = listView;
    } else {
      // Scroll orizzontale unico — niente scroll annidati.
      content = SingleChildScrollView(
        controller: _horizontalCtrl,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: widget.minWidth,
          child: listView,
        ),
      );
    }

    if (widget.showScrollbar) {
      if (widget.wrapLines) {
        content = Scrollbar(
          controller: _verticalCtrl,
          child: content,
        );
      } else {
        content = Scrollbar(
          controller: _horizontalCtrl,
          notificationPredicate: (n) => n.depth == 0,
          child: Scrollbar(
            controller: _verticalCtrl,
            notificationPredicate: (n) => n.depth == 1,
            child: content,
          ),
        );
      }
    }

    return SelectionArea(
      child: Stack(
        children: [
          Container(color: widget.backgroundColor, child: content),
          if (!_autoScroll)
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() => _autoScroll = true);
                  _scrollToBottom();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: const Icon(Icons.arrow_downward, color: Colors.white, size: 18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
