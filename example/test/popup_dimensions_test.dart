import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:morpheus_launcher_gui/utils/glass_morphism.dart';
import 'package:morpheus_launcher_gui/utils/widget_utils.dart';

void main() {
  testWidgets('glass popup keeps the original dialog dimensions', (tester) async {
    Future<Rect> showPopup({required bool glass, required double contentWidth, required double contentHeight}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  final content = <Widget>[
                    SizedBox(width: contentWidth, height: contentHeight),
                  ];
                  if (glass) {
                    WidgetUtils.showPopup(context, 'Popup', content, <Widget>[]);
                  } else {
                    showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      barrierColor: Colors.black.withAlpha(80),
                      builder: (context) => AlertDialog(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        backgroundColor: Colors.white.withAlpha(230),
                        shadowColor: Colors.transparent,
                        title: const Text(
                          'Popup',
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'Comfortaa',
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        content: SingleChildScrollView(child: ListBody(children: content)),
                        actions: const <Widget>[],
                      ),
                    );
                  }
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final finder = glass
          ? find.byType(GlassMorphism)
          : find.descendant(
              of: find.byType(AlertDialog),
              matching: find.byWidgetPredicate(
                (widget) => widget is Material && widget.type == MaterialType.card,
              ),
            );
      final rect = tester.getRect(finder);
      await tester.pumpWidget(const SizedBox.shrink());
      return rect;
    }

    for (final size in <Size>[
      const Size(100, 50),
      const Size(500, 250),
      const Size(1200, 800),
    ]) {
      final original = await showPopup(glass: false, contentWidth: size.width, contentHeight: size.height);
      final glass = await showPopup(glass: true, contentWidth: size.width, contentHeight: size.height);
      expect(glass, original, reason: 'content size $size');
    }
  });
}
