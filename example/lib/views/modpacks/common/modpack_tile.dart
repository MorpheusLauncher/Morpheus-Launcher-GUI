import 'package:flutter/material.dart';
import 'package:morpheus_launcher_gui/globals.dart';

/// Cornice comune alle istanze installate e ai download in corso.
class ModpackTile extends StatelessWidget {
  const ModpackTile({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
        child: SizedBox(
          height: 55,
          width: double.infinity,
          child: Material(
            elevation: 15,
            color: ColorUtils.dynamicPrimaryForegroundColor,
            shadowColor: ColorUtils.defaultShadowColor,
            borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
            child: child,
          ),
        ),
      );
}
