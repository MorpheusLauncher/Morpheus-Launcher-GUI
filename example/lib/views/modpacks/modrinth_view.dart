import 'package:flutter/material.dart';
import 'package:morpheus_launcher_gui/l10n/app_localizations.dart';
import 'package:morpheus_launcher_gui/utils/launcher/modpack_browser_source.dart';
import 'package:morpheus_launcher_gui/utils/launcher/modpack_detail_source.dart';
import 'package:morpheus_launcher_gui/views/modpacks/common/modpack_browser_view.dart';
import 'package:morpheus_launcher_gui/views/modpacks/common/modpack_detail_view.dart';

class ModrinthView extends StatelessWidget {
  const ModrinthView({super.key});

  @override
  Widget build(BuildContext context) => ModpackBrowserView(
        source: const ModrinthBrowserSource(),
        title: AppLocalizations.of(context)!.modded_modrinth_title,
        detailBuilder: (context, pack) => ModpackDetailView(modpack: pack, source: const ModrinthDetailSource()),
      );
}
