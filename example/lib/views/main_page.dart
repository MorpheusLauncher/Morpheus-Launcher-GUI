import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:morpheus_launcher_gui/account/account_utils.dart';
import 'package:morpheus_launcher_gui/account/microsoft_auth.dart';
import 'package:morpheus_launcher_gui/globals.dart';
import 'package:morpheus_launcher_gui/l10n/app_localizations.dart';
import 'package:morpheus_launcher_gui/main.dart';
import 'package:morpheus_launcher_gui/utils/circle_utils.dart';
import 'package:morpheus_launcher_gui/utils/launcher//version_utils.dart';
import 'package:morpheus_launcher_gui/utils/launcher/launch_utils.dart';
import 'package:morpheus_launcher_gui/utils/launcher/modrinth_utils.dart';
import 'package:morpheus_launcher_gui/utils/morpheus_icons_icons.dart';
import 'package:morpheus_launcher_gui/utils/skinmodel/skin_utils.dart';
import 'package:morpheus_launcher_gui/utils/skinmodel/skin_viewer.dart';
import 'package:morpheus_launcher_gui/utils/widget_utils.dart';
import 'package:morpheus_launcher_gui/views/modrinth_view.dart';
import 'package:morpheus_launcher_gui/views/widget_news.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_3d/simple_3d.dart';
import 'package:simple_3d_renderer/simple_3d_renderer.dart';
import 'package:system_theme/system_theme.dart';
import 'package:text_divider/text_divider.dart';
import 'package:url_launcher/url_launcher.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final ValueNotifier<String?> _themeNotifier = ValueNotifier(Globals.selectedWindowTheme);

  @override
  void initState() {
    super.initState();
    rebuild();
  }

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  Future<void> rebuild() async {
    if (Globals.getAccount() != null) {
      ThreeDimensionalViewer.objs.clear();
      ThreeDimensionalViewer.setupUV(Globals.getAccount()!.isSlimSkin);
      ThreeDimensionalViewer.texturizePlayerModel();
      Timer.periodic(const Duration(milliseconds: 100), (timer) async {
        setState(() {
          ThreeDimensionalViewer.isLoaded = ThreeDimensionalViewer.isLoaded;
        });
        timer.cancel();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorUtils.dynamicWindowBackgroundColor,
      child: Column(
        children: [
          drawTitleCustomBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Stack(
                children: [
                  _buildContent(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (Globals.navSelected) {
      case NavSection.home:
        return _buildPage(buildHomeWidgetList());
      case NavSection.morpheus:
        return _buildPage(buildMorpheusList());
      case NavSection.vanilla:
        return _buildPage(buildVanillaList());
      case NavSection.modded:
        return _buildPage(buildModdedList());
      case NavSection.settings:
        return _buildPage(buildSettingsList());
      case NavSection.accounts:
        return _buildAccountsPage();
    }
  }

  Widget _buildPage(Widget child) {
    return Row(
      children: [
        buildNavbar(),
        const SizedBox(width: 8),
        Expanded(
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveTileGrid(
    List<Widget> children, {
    double minTileWidth = 340,
    double spacing = 8,
    double runSpacing = 0,
    int maxColumns = 4,
  }) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth ? constraints.maxWidth : MediaQuery.of(context).size.width;
        final columns = WidgetUtils.responsiveColumnCount(
          width,
          minTileWidth: minTileWidth,
          spacing: spacing,
          maxColumns: maxColumns,
        );

        final tileWidth = (width - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(
                width: tileWidth,
                child: child,
              ),
          ],
        );
      },
    );
  }

  //////////////////////////////////
  //////////// NAVBAR //////////////
  //////////////////////////////////

  /** Renderizza la Navbar */
  Widget buildNavbar() {
    return Material(
      elevation: 15,
      color: ColorUtils.dynamicPrimaryForegroundColor,
      shadowColor: ColorUtils.defaultShadowColor,
      borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          buildNavItem(Icons.home, NavSection.home),
          const SizedBox(height: 20),
          buildNavMorpheusItem(NavSection.morpheus),
          const SizedBox(height: 20),
          buildNavItem(MorpheusIcons.vanilla, NavSection.vanilla),
          buildNavItem(MorpheusIcons.modded, NavSection.modded),
          buildNavItem(Icons.settings, NavSection.settings),
          const SizedBox(height: 20),
          buildNavAccountItem(NavSection.accounts),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /** Renderizza le icone della Navbar */
  Widget buildNavItem(IconData icon, NavSection section) {
    final bool selected = Globals.navSelected == section;

    return GestureDetector(
      onTap: () async {
        setState(() {
          Globals.navSelected = section;
        });

        if (section == NavSection.home) {
          Globals.pinnedVersions = await VersionUtils.getPinnedVersions();
        }
      },
      child: SizedBox(
        height: 70,
        width: 60,
        child: Icon(
          icon,
          size: 30,
          color: selected ? ColorUtils.primaryFontColor : ColorUtils.primaryFontColor.withAlpha(128),
        ),
      ),
    );
  }

  Widget buildNavMorpheusItem(NavSection section) {
    final bool selected = Globals.navSelected == section;

    return GestureDetector(
      onTap: () {
        setState(() {
          Globals.navSelected = section;
        });
      },
      child: MouseRegion(
        onEnter: (e) => {},
        child: FutureBuilder<Uint8List>(
          future: SkinUtils.loadCroppedSkin(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 30,
                width: 30,
                child: CircularProgressIndicator(),
              );
            }

            return ColorFiltered(
              colorFilter: selected
                  ? const ColorFilter.mode(
                      Colors.transparent,
                      BlendMode.multiply,
                    )
                  : const ColorFilter.matrix(
                      <double>[
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0.2126,
                        0.7152,
                        0.0722,
                        0,
                        0,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ],
                    ),
              child: Container(
                height: 30,
                width: 30,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    filterQuality: FilterQuality.none,
                    image: AssetImage("assets/morpheus.png"),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /** Renderizza la faccia del player */
  Widget buildNavAccountItem(NavSection section) {
    final bool selected = Globals.navSelected == section;

    return GestureDetector(
      onTap: () {
        setState(() {
          Globals.navSelected = section;
        });
      },
      child: MouseRegion(
        onEnter: (e) => {},
        child: FutureBuilder<Uint8List>(
          future: SkinUtils.loadCroppedSkin(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 35,
                width: 35,
                child: CircularProgressIndicator(),
              );
            }

            final croppedBytes = snapshot.data!;

            return Container(
              height: 35,
              width: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  filterQuality: FilterQuality.none,
                  opacity: selected ? 1 : 0.5,
                  image: MemoryImage(croppedBytes),
                  fit: BoxFit.cover,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  ////////// HOME PAGE /////////////

  ListView buildHomeWidgetList() {
    return ListView(
      children: [
        /** Versioni pinnate */
        if (Globals.pinnedVersions.isNotEmpty) ...[
          /** Divider Versioni Preferite */
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: TextDivider(
              color: ColorUtils.secondaryFontColor.withAlpha(80),
              thickness: 2,
              text: Text(
                AppLocalizations.of(context)!.home_favourite_title,
                textAlign: TextAlign.center,
                style: WidgetUtils.customTextStyle(
                  20,
                  FontWeight.w300,
                  ColorUtils.primaryFontColor,
                ),
              ),
            ),
          ),
          _buildResponsiveTileGrid([
            for (var version in VersionUtils.getAllVersions())
              if (Globals.pinnedVersions.contains(version["id"]))
                buildVanillaItem(
                  version["type"],
                  version["id"],
                  "",
                  VersionUtils.isCompatible(
                    version["type"],
                    version["id"],
                    context,
                  ),
                ),
          ]),
          /** Divider News/Changelog mojang */
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: TextDivider(
              color: ColorUtils.secondaryFontColor.withAlpha(80),
              thickness: 2,
              text: Text(
                AppLocalizations.of(context)!.home_news_title,
                textAlign: TextAlign.center,
                style: WidgetUtils.customTextStyle(
                  20,
                  FontWeight.w300,
                  ColorUtils.primaryFontColor,
                ),
              ),
            ),
          ),
        ],

        /** Changelog */
        if (Globals.isNewsAvailable) ...[
          _buildResponsiveTileGrid(
            [
              for (var version in Globals.vanillaNewsResponse)
                if ((version["type"] == "release" && Globals.showOnlyReleases) || !Globals.showOnlyReleases)
                  buildNewsItem(
                    version["title"].toString().replaceAll(": Java Edition", "").replaceAll(" Aquatic", ""),
                    version["body"],
                    version["image"]["url"],
                    detailPath: version["detailPath"]?.toString(),
                    date: version["date"]?.toString(),
                  ),
            ],
            minTileWidth: 280,
          ),
        ] else ...[
          /** quando non può mostrare le news */
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Text(
              AppLocalizations.of(context)!.home_news_empty_msg,
              textAlign: TextAlign.center,
              style: WidgetUtils.customTextStyle(
                14,
                FontWeight.w300,
                ColorUtils.primaryFontColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget buildNewsItem(
    String title,
    String body,
    String url, {
    String? detailPath,
    String? date,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          elevation: 15,
          color: ColorUtils.dynamicPrimaryForegroundColor,
          shadowColor: ColorUtils.defaultShadowColor,
          borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NewsScreen(
                    title: title,
                    body: body,
                    url: url,
                    detailPath: detailPath,
                    date: date,
                  ),
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /** Miniatura con titolo e data leggibili su gradiente */
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(Globals.borderRadius - 2),
                    child: Stack(
                      children: [
                        Image.network(
                          "${Urls.mojangContentURL}$url",
                          width: double.infinity,
                          height: 150,
                          fit: BoxFit.cover,
                        ),
                        // Gradiente in basso invece di un blur uniforme: la
                        // miniatura resta leggibile e il testo sopra pure.
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withAlpha(190)],
                                stops: const [0.4, 1.0],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 8,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: WidgetUtils.customTextStyle(16, FontWeight.w600, Colors.white),
                              ),
                              if (date != null && date.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  _formatNewsDate(date),
                                  style: WidgetUtils.customTextStyle(11, FontWeight.w500, Colors.white.withAlpha(190)),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatNewsDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();

      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return "";
    }
  }

  /////////// MORPHEUS /////////////

  ListView buildMorpheusList() {
    return ListView(
      children: [
        _buildMorpheusHero(),
        const SizedBox(height: 8),
        if (Globals.morpheusVersionsResponse != null) ...[
          _buildResponsiveTileGrid(
            [
              for (var prodotto in Globals.morpheusVersionsResponse)
                buildMorpheusItem(
                  prodotto['name'],
                  prodotto['gameversion'],
                  prodotto['id'],
                  prodotto['img'],
                ),
            ],
            minTileWidth: 340,
            maxColumns: 2,
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              AppLocalizations.of(context)!.morpheus_products_empty,
              textAlign: TextAlign.center,
              style: WidgetUtils.customTextStyle(
                22,
                FontWeight.w300,
                ColorUtils.primaryFontColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Banner introduttivo sopra la griglia dei prodotti Morpheus: spiega in
  /// due righe perché scegliere il client Morpheus invece di vanilla/mod,
  /// dato che l'API dei prodotti non fornisce alcuna descrizione.
  Widget _buildMorpheusHero() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorUtils.dynamicAccentColor.withAlpha(60),
            ColorUtils.dynamicPrimaryForegroundColor,
          ],
        ),
        borderRadius: BorderRadius.circular(Globals.borderRadius + 4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome, color: ColorUtils.dynamicAccentColor, size: 34),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.morpheus_hero_title,
                  style: WidgetUtils.customTextStyle(20, FontWeight.w700, ColorUtils.primaryFontColor),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context)!.morpheus_hero_subtitle,
                  style: WidgetUtils.customTextStyle(13, FontWeight.w400, ColorUtils.secondaryFontColor),
                ),
                const SizedBox(height: 10),
                // A differenza delle feature del client (OptiFine, PvP, ...)
                // questi riguardano l'intero ecosistema Morpheus: per questo
                // vivono nell'hero e non nella singola card del prodotto.
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildMorpheusTrustChip(Icons.shield_outlined, AppLocalizations.of(context)!.morpheus_trust_privacy),
                    _buildMorpheusTrustChip(Icons.block, AppLocalizations.of(context)!.morpheus_trust_no_ads),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Trust badge dell'hero (privacy, niente pubblicità): stile pensato per
  /// stare sullo sfondo chiaro dell'hero, a differenza delle feature chip
  /// del client che vivono sopra uno screenshot scuro.
  Widget _buildMorpheusTrustChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ColorUtils.dynamicAccentColor.withAlpha(30),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(color: ColorUtils.dynamicAccentColor.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: ColorUtils.dynamicAccentColor),
          const SizedBox(width: 5),
          Text(label, style: WidgetUtils.customTextStyle(11, FontWeight.w600, ColorUtils.primaryFontColor)),
        ],
      ),
    );
  }

  Widget _buildMorpheusFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(38),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        border: Border.all(color: Colors.white.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: WidgetUtils.customTextStyle(11, FontWeight.w500, Colors.white)),
        ],
      ),
    );
  }

  Widget buildMorpheusItem(
    String productName,
    String gameVersion,
    String productId,
    String image,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
      child: Material(
        elevation: 15,
        color: ColorUtils.dynamicPrimaryForegroundColor,
        shadowColor: ColorUtils.defaultShadowColor,
        borderRadius: BorderRadius.circular(Globals.borderRadius + 4),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(image, fit: BoxFit.cover),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withAlpha(210)],
                    stops: const [0.25, 0.85],
                  ),
                ),
              ),
            ),

            /** Badge "In evidenza" */
            Positioned(
              top: 12,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(38),
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  boxShadow: [BoxShadow(color: Colors.black.withAlpha(60), blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.star, size: 13, color: ColorUtils.dynamicAccentColor),
                    const SizedBox(width: 4),
                    Text(
                      AppLocalizations.of(context)!.morpheus_badge_featured,
                      style: WidgetUtils.customTextStyle(11, FontWeight.w700, ColorUtils.secondaryFontColor).copyWith(height: 1),
                    ),
                  ],
                ),
              ),
            ),

            /** Contenuto: uno spacer riserva l'area "solo immagine" in alto,
             * poi il pannello info (non posizionato: è lui a determinare
             * l'altezza finale della card, l'immagine si adatta di conseguenza
             * grazie al Positioned.fill sopra). */
            Column(
              children: [
                const SizedBox(height: 118),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              productName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: WidgetUtils.customTextStyle(18, FontWeight.w500, Colors.white),
                            ),
                            Text(
                              "minecraft $gameVersion",
                              style: WidgetUtils.customTextStyle(14, FontWeight.w500, Colors.white.withAlpha(200)),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                _buildMorpheusFeatureChip(Icons.auto_awesome, AppLocalizations.of(context)!.morpheus_feature_optifine),
                                _buildMorpheusFeatureChip(Icons.bolt, AppLocalizations.of(context)!.morpheus_feature_pvp),
                                _buildMorpheusFeatureChip(Icons.music_note, AppLocalizations.of(context)!.morpheus_feature_music),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      /** Pulsante Gioca */
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final config = LaunchConfig(
                              gameVersion: gameVersion,
                              productId: productId,
                              isModded: false,
                              realGameVersion: gameVersion,
                              loader: ModLoader.vanilla,
                              startOnFirstThread: false,
                              jvmArgs: [],
                              launcherArgs: [],
                            );

                            await LaunchUtils.launchMinecraft(
                              context,
                              config,
                              onAccountRequired: () {
                                setState(() => Globals.navSelected = NavSection.accounts);
                              },
                            );
                          },
                          icon: const Icon(Icons.rocket_launch, size: 20, color: Colors.white),
                          label: Text(
                            AppLocalizations.of(context)!.morpheus_play_button,
                            style: WidgetUtils.customTextStyle(15, FontWeight.w700, Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorUtils.dynamicAccentColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(Globals.borderRadius - 4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /////////// VANILLA //////////////

  ListView buildVanillaList() {
    return ListView(
      children: [
        /** Avvisa l'utente che non ha versioni vanilla */
        if (VersionUtils.getMinecraftVersions(false).isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              AppLocalizations.of(context)!.vanilla_empty_title,
              textAlign: TextAlign.center,
              style: WidgetUtils.customTextStyle(
                22,
                FontWeight.w300,
                ColorUtils.primaryFontColor,
              ),
            ),
          ),

        /** Ultime versioni */
        _buildResponsiveTileGrid([
          buildVanillaItem(
            AppLocalizations.of(context)!.vanilla_release_title,
            Globals.vanillaVersionsResponse != null ? Globals.vanillaVersionsResponse["latest"]["release"] : "",
            "",
            true,
          ),
          buildVanillaItem(
            AppLocalizations.of(context)!.vanilla_snapshot_title,
            Globals.vanillaVersionsResponse != null ? Globals.vanillaVersionsResponse["latest"]["snapshot"] : "",
            "",
            true,
          ),
        ]),
        /** Separatore */
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Divider(
            color: ColorUtils.secondaryFontColor,
          ),
        ),

        /** Lista completa delle versioni solo vanilla (misto) */
        _buildResponsiveTileGrid([
          for (var version in VersionUtils.getMinecraftVersions(false))
            if ((version["type"] == "release" && Globals.showOnlyReleases) || !Globals.showOnlyReleases)
              buildVanillaItem(
                version["type"],
                version["id"],
                version["releaseTime"],
                VersionUtils.isCompatible(
                  version["type"],
                  version["id"],
                  context,
                ),
              ),
        ]),
      ],
    );
  }

  Widget buildVanillaItem(String gameType, String gameVersion, String releaseDate, bool compatible) {
    final bool compatible = VersionUtils.isCompatible(gameType, gameVersion, context);
    final String? incompatibilityReason = compatible ? null : VersionUtils.getIncompatibilityReason(gameType, gameVersion, context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: Material(
          elevation: 15,
          color: ColorUtils.dynamicPrimaryForegroundColor,
          shadowColor: ColorUtils.defaultShadowColor,
          borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icona
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Tooltip(
                  message: incompatibilityReason ?? "",
                  textStyle: WidgetUtils.customTextStyle(12, FontWeight.w500, ColorUtils.primaryFontColor),
                  decoration: BoxDecoration(
                    color: ColorUtils.dynamicBackgroundColor,
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                  ),
                  waitDuration: const Duration(milliseconds: 500),
                  child: ColorFiltered(
                    colorFilter: compatible
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                        : const ColorFilter.matrix(<double>[
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0.2126,
                            0.7152,
                            0.0722,
                            0,
                            0,
                            0,
                            0,
                            0,
                            1,
                            0,
                          ]),
                    child: Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          filterQuality: FilterQuality.none,
                          image: AssetImage(_getVersionIcon(gameType, gameVersion)),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Testo
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${gameType.substring(0, 1).toUpperCase()}${gameType.substring(1)} $gameVersion",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WidgetUtils.customTextStyle(
                        releaseDate.isNotEmpty ? 18 : 20,
                        FontWeight.w500,
                        ColorUtils.primaryFontColor,
                      ),
                    ),
                    if (releaseDate.isNotEmpty)
                      Text(
                        "${DateTime.parse(releaseDate).toLocal().day}/${DateTime.parse(releaseDate).toLocal().month}/${DateTime.parse(releaseDate).toLocal().year}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WidgetUtils.customTextStyle(
                          14,
                          FontWeight.w500,
                          ColorUtils.secondaryFontColor,
                        ),
                      ),
                  ],
                ),
              ),

              // Pulsanti
              if (!gameType.contains(AppLocalizations.of(context)!.vanilla_release_title) && !gameType.contains(AppLocalizations.of(context)!.vanilla_snapshot_title))
                WidgetUtils.buildButton(
                  Globals.pinnedVersions.contains(gameVersion) ? Icons.favorite : Icons.favorite_border,
                  ColorUtils.dynamicSecondaryForegroundColor,
                  ColorUtils.primaryFontColor,
                  () async {
                    setState(() {
                      if (!Globals.pinnedVersions.contains(gameVersion)) {
                        Globals.pinnedVersions.add(gameVersion);
                      } else {
                        Globals.pinnedVersions.remove(gameVersion);
                      }
                    });
                    await VersionUtils.updateLauncherProfiles(Globals.pinnedVersions);
                  },
                ),

              WidgetUtils.buildButton(
                Icons.rocket_launch,
                ColorUtils.dynamicAccentColor,
                Colors.white,
                () async {
                  final resolvedVersion = versionResolver(gameType, gameVersion, context);
                  final profile = VersionUtils.resolveLaunchProfile(
                    resolvedVersion.gameVersion,
                    gameDirectory: Globals.gamefoldercontroller.text,
                  );
                  final config = LaunchConfig(
                    gameVersion: resolvedVersion.gameVersion,
                    productId: null,
                    isModded: profile.loader != ModLoader.vanilla,
                    realGameVersion: profile.minecraftVersion,
                    loader: profile.loader,
                    startOnFirstThread: LaunchUtils.shouldUseStartOnFirstThread(
                      profile.minecraftVersion,
                    ),
                    jvmArgs: resolvedVersion.additionalArgs,
                    launcherArgs: [],
                  );
                  await LaunchUtils.launchMinecraft(
                    context,
                    config,
                    onAccountRequired: () {
                      setState(() => Globals.navSelected = NavSection.accounts);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getVersionIcon(String gameType, String gameVersion) {
    final type = gameType.toLowerCase();
    final version = gameVersion.toLowerCase();

    if (type.contains("alpha")) return 'assets/alpha.png';
    if (type.contains("beta")) return 'assets/beta.png';
    if (type.contains("snapshot")) return 'assets/snapshot.png';
    if (type.contains("optifine") || version.contains("optifine")) return 'assets/optifine.png';
    if (type.contains("optiforge") || version.contains("optiforge")) return 'assets/optiforge.png';
    if (type.contains("forge") || version.contains("forge")) return 'assets/forge.png';
    if (type.contains("fabric") || version.contains("fabric")) return 'assets/fabric.png';

    return 'assets/release.png';
  }

  /// Costruisce l'id di versione completo (auto-descrittivo per il loader,
  /// es. "fabric-loader-X-Y", "Y-forge-X") a partire dai cataloghi
  /// disponibili. La policy classloader/classpath viene poi decisa da
  /// LaunchConfig.enableClassPath in base al loader risolto da
  /// VersionUtils.resolveLaunchProfile, non da questo metodo.
  ({String gameVersion, List<String> additionalArgs}) versionResolver(
    String gameType,
    String gameVersion,
    BuildContext context,
  ) {
    // Latest Release
    if (gameType.contains(AppLocalizations.of(context)?.vanilla_release_title as Pattern) || gameVersion.contains("latest")) {
      return (gameVersion: "latest", additionalArgs: const []);
    }

    // Latest Snapshot
    if (gameType.contains(AppLocalizations.of(context)?.vanilla_snapshot_title as Pattern) || gameVersion.contains("snapshot")) {
      return (gameVersion: "snapshot", additionalArgs: const []);
    }

    // NeoForge (already self-describing in the installed list, e.g.
    // "neoforge-21.1.1"). Must be checked before Forge below, since
    // "neoforge" also contains the substring "forge".
    if (gameType.toLowerCase().contains("neoforge") || gameVersion.toLowerCase().contains("neoforge")) {
      return (gameVersion: gameVersion, additionalArgs: const []);
    }

    // Fabric
    if (gameType.toLowerCase().contains("fabric") || gameVersion.toLowerCase().contains("fabric")) {
      if (!gameVersion.toLowerCase().startsWith("fabric")) {
        var fabricVersion = Globals.fabricLoaderVersionsResponse[0]["version"];
        gameVersion = "fabric-loader-$fabricVersion-$gameVersion";
      }

      return (gameVersion: gameVersion, additionalArgs: const []);
    }

    // OptiFine
    if (gameType.toLowerCase().contains("optifine") || gameVersion.toLowerCase().contains("optifine")) {
      if (gameType.toLowerCase().contains("optifine")) {
        final baseVersion = gameVersion.toLowerCase();
        for (var version in Globals.optifineVersions) {
          if (version.split("-")[0] == baseVersion) {
            gameVersion = version;
            break;
          }
        }
      }

      return (gameVersion: gameVersion, additionalArgs: const []);
    }

    // OptiForge
    if (gameType.toLowerCase().contains("optiforge") || gameVersion.toLowerCase().contains("optiforge")) {
      if (gameType.toLowerCase().contains("optiforge")) {
        final baseVersion = gameVersion.toLowerCase();
        for (var version in Globals.forgeVersions) {
          if (version.split("-")[0] == baseVersion) {
            gameVersion = version.toString().replaceAll("forge", "optiforge");
            break;
          }
        }
      }

      return (
        gameVersion: gameVersion,
        additionalArgs: ["-Dfml.ignoreInvalidMinecraftCertificates=true"],
      );
    }

    // Forge
    if (gameType.toLowerCase().contains("forge") || gameVersion.toLowerCase().contains("forge")) {
      if (gameType.toLowerCase().contains("forge")) {
        final baseVersion = gameVersion.toLowerCase();
        for (var version in Globals.forgeVersions) {
          if (version.split("-")[0] == baseVersion) {
            gameVersion = version;
            break;
          }
        }
      }

      return (
        gameVersion: gameVersion,
        additionalArgs: ["-Dfml.ignoreInvalidMinecraftCertificates=true"],
      );
    }

    // Vanilla (default)
    return (gameVersion: gameVersion, additionalArgs: const []);
  }

  /////////// MODDING //////////////

  final Set<String> _selectedFilters = {}; // vuoto = tutti visibili

  bool _isVisible(String label) {
    if (_selectedFilters.isEmpty) return true;

    return _selectedFilters.contains(label);
  }

  Widget _buildDivider(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: TextDivider(
        color: ColorUtils.secondaryFontColor.withAlpha(80),
        thickness: 2,
        text: Text(
          label,
          textAlign: TextAlign.center,
          style: WidgetUtils.customTextStyle(
            20,
            FontWeight.w300,
            ColorUtils.primaryFontColor,
          ),
        ),
      ),
    );
  }

  Widget _buildModloaderSection({
    required String label,
    required List<Widget> children,
    required int count,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      decoration: BoxDecoration(
        color: ColorUtils.dynamicAcrylicColor,
        borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
        border: Border.all(
          color: ColorUtils.secondaryFontColor.withAlpha(50),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text(
                  label,
                  style: WidgetUtils.customTextStyle(
                    16,
                    FontWeight.w500,
                    ColorUtils.primaryFontColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
                  decoration: BoxDecoration(
                    color: ColorUtils.dynamicAcrylicColor,
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                  ),
                  child: Text(
                    "$count",
                    style: WidgetUtils.customTextStyle(
                      12,
                      FontWeight.w600,
                      ColorUtils.primaryFontColor.withAlpha(200),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Children
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: _buildResponsiveTileGrid(children),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip({
    required String label,
    required IconData icon,
    bool isActive = true,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: ColorUtils.dynamicAcrylicColor,
          borderRadius: BorderRadius.circular(Globals.borderRadius - 2),
          border: Border.all(
            color: isActive ? ColorUtils.primaryFontColor.withAlpha(200) : ColorUtils.secondaryFontColor.withAlpha(80),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isActive ? ColorUtils.primaryFontColor.withAlpha(200) : ColorUtils.secondaryFontColor.withAlpha(80),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: WidgetUtils.customTextStyle(
                12,
                isActive ? FontWeight.w600 : FontWeight.w300,
                isActive ? ColorUtils.primaryFontColor.withAlpha(200) : ColorUtils.secondaryFontColor.withAlpha(80),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ["OptiFine", "OptiForge", "Forge", "Fabric"];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((label) {
            final isActive = _selectedFilters.contains(label);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildQuickChip(
                label: label,
                icon: isActive ? Icons.visibility : Icons.visibility_off,
                isActive: isActive || _selectedFilters.isEmpty,
                onTap: () {
                  setState(() {
                    if (isActive) {
                      _selectedFilters.remove(label);
                    } else {
                      _selectedFilters.add(label);
                    }
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildModdedList() {
    final fabricFiltered = Globals.fabricGameVersionsResponse != null
        ? Globals.fabricGameVersionsResponse.where((v) {
            if (Globals.showOnlyReleases != true) return true;

            return v["stable"] == true || (v["type"] is String && v["type"].toString().toLowerCase() == "release");
          }).toList()
        : [];

    // Loaded from .morpheus/modrinth-packs/index.json — works fully offline
    final installedModpacks = ModrinthUtils.readIndex();

    return ListView(
      children: [
        // ── Modrinth browser button (online only) ──────────────────────────
        if (Globals.isVersionsAvailable) ...[
          _buildDivider(AppLocalizations.of(context)!.modded_modrinth_section_title),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
            child: SizedBox(
              height: 55,
              width: double.infinity,
              child: Material(
                elevation: 0,
                color: ColorUtils.dynamicPrimaryForegroundColor,
                shadowColor: ColorUtils.defaultShadowColor,
                borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ModrinthView()),
                    );
                  },
                  borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Container(
                          height: 30,
                          width: 30,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              filterQuality: FilterQuality.none,
                              image: AssetImage("assets/modrinth.png"),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.modded_modrinth_button,
                        style: WidgetUtils.customTextStyle(16, FontWeight.w500, ColorUtils.primaryFontColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],

        // ── Installed Modrinth modpacks (offline-friendly) ─────────────────
        if (installedModpacks.isNotEmpty) ...[
          _buildDivider(AppLocalizations.of(context)!.modded_modrinth_title),
          _buildResponsiveTileGrid([
            for (final pack in installedModpacks) _buildModrinthPackItem(pack),
          ]),
        ],

        // ── Installed modded versions (Forge/Fabric/etc.) ──────────────────
        if (VersionUtils.getMinecraftVersions(true).isNotEmpty) _buildDivider(AppLocalizations.of(context)!.modded_installed_title),
        if (VersionUtils.getMinecraftVersions(true).isEmpty && !Globals.isVersionsAvailable && installedModpacks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              AppLocalizations.of(context)!.modded_empty_title,
              textAlign: TextAlign.center,
              style: WidgetUtils.customTextStyle(22, FontWeight.w300, ColorUtils.primaryFontColor),
            ),
          ),
        _buildResponsiveTileGrid([
          for (var version in VersionUtils.getMinecraftVersions(true))
            buildVanillaItem(
              version["type"],
              version["id"],
              "",
              VersionUtils.isCompatible(version["type"], version["id"], context),
            ),
        ]),

        // ── Available modloader versions ───────────────────────────────────
        _buildDivider(AppLocalizations.of(context)!.modded_available_versions_title),
        _buildFilterChips(),
        const SizedBox(height: 4),
        if (_isVisible("OptiFine") && Globals.optifineVersions != null)
          _buildModloaderSection(
            label: "OptiFine",
            count: Globals.optifineVersions.length,
            children: [
              for (var version in Globals.optifineVersions)
                buildVanillaItem(
                  "Optifine",
                  version.split("-")[0],
                  "",
                  VersionUtils.isCompatible("Optifine", version.split("-")[0], context),
                ),
            ],
          ),
        if (_isVisible("OptiForge") && Globals.optiforgeVersions != null)
          _buildModloaderSection(
            label: "OptiForge",
            count: Globals.optiforgeVersions.length,
            children: [
              for (var version in Globals.optiforgeVersions)
                buildVanillaItem(
                  "OptiForge",
                  version.split("-")[0],
                  "",
                  VersionUtils.isCompatible("OptiForge", version.split("-")[0], context),
                ),
            ],
          ),
        if (_isVisible("Forge") && Globals.forgeVersions != null)
          _buildModloaderSection(
            label: "Forge",
            count: Globals.forgeVersions.length,
            children: [
              for (var version in Globals.forgeVersions)
                buildVanillaItem(
                  "Forge",
                  version.split("-")[0],
                  "",
                  VersionUtils.isCompatible("Forge", version.split("-")[0], context),
                ),
            ],
          ),
        if (_isVisible("Fabric") && Globals.fabricGameVersionsResponse != null)
          _buildModloaderSection(
            label: "Fabric",
            count: fabricFiltered.length,
            children: [
              for (var version in fabricFiltered) buildVanillaItem("Fabric", version["version"], "", true),
            ],
          ),
      ],
    );
  }

  /// Builds a single row for an installed Modrinth modpack.
  /// Reads all data from index.json — no network needed.
  Widget _buildModrinthPackItem(Map<String, dynamic> pack) {
    final slug = pack['slug']?.toString() ?? '';
    final title = pack['title']?.toString() ?? slug;
    final iconUrl = pack['iconUrl']?.toString() ?? '';
    final mcVersion = pack['minecraft']?.toString() ?? '';
    final loader = pack['loader']?.toString() ?? '';
    final versionName = pack['versionName']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: Material(
          elevation: 15,
          color: ColorUtils.dynamicPrimaryForegroundColor,
          shadowColor: ColorUtils.defaultShadowColor,
          borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(6)),
                  child: iconUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: iconUrl,
                          width: 30,
                          height: 30,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _modrinthIconPlaceholder(),
                          errorWidget: (_, __, ___) => _modrinthIconPlaceholder(),
                        )
                      : _modrinthIconPlaceholder(),
                ),
              ),

              // Title + subtitle
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WidgetUtils.customTextStyle(16, FontWeight.w500, ColorUtils.primaryFontColor),
                    ),
                    Text(
                      '$loader $mcVersion, ver. $versionName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WidgetUtils.customTextStyle(12, FontWeight.w300, ColorUtils.secondaryFontColor),
                    ),
                  ],
                ),
              ),

              // Delete button
              WidgetUtils.buildButton(
                Icons.delete_outline,
                Colors.redAccent,
                Colors.white,
                () {
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
                          setState(() {});
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
                },
              ),

              // Launch button
              WidgetUtils.buildButton(
                Icons.rocket_launch,
                ColorUtils.dynamicAccentColor,
                Colors.white,
                () async {
                  final deps = ModrinthUtils.getDependencies(slug);
                  final mcVer = deps['minecraft'] ?? mcVersion;
                  final loaderName = loader;
                  final modLoader = LaunchPolicy.loaderFromModrinthId(loaderName);

                  String gameVersion;

                  switch (loaderName) {
                    case 'fabric':
                      final loaderVer = deps['fabric-loader'] ?? (Globals.fabricLoaderVersionsResponse?.isNotEmpty == true ? Globals.fabricLoaderVersionsResponse[0]['version'].toString() : '');
                      gameVersion = loaderVer.isNotEmpty ? 'fabric-loader-$loaderVer-$mcVer' : mcVer;
                      break;
                    case 'forge':
                      final forgeVer = deps['forge'] ?? '';
                      gameVersion = forgeVer.isNotEmpty ? '$mcVer-forge-$forgeVer' : mcVer;
                      break;
                    case 'quilt':
                      final quiltVer = deps['quilt-loader'] ?? '';
                      gameVersion = quiltVer.isNotEmpty ? 'quilt-loader-$quiltVer-$mcVer' : mcVer;
                      break;
                    case 'neoforge':
                      final neoVer = deps['neoforge'] ?? '';
                      gameVersion = neoVer.isNotEmpty ? 'neoforge-$neoVer' : mcVer;
                      break;
                    default:
                      gameVersion = mcVer;
                  }

                  final config = LaunchConfig(
                    gameVersion: gameVersion,
                    productId: null,
                    isModded: modLoader != ModLoader.vanilla,
                    realGameVersion: mcVer,
                    loader: modLoader,
                    // I modpack Modrinth forzano sempre la classpath, a prescindere dal loader.
                    forceClassPath: true,
                    startOnFirstThread: LaunchUtils.shouldUseStartOnFirstThread(mcVer),
                    jvmArgs: [],
                    launcherArgs: [],
                  );

                  await LaunchUtils.launchMinecraft(
                    context,
                    config,
                    onAccountRequired: () {
                      setState(() => Globals.navSelected = NavSection.accounts);
                    },
                    gameDirectory: ModrinthUtils.gameDir(slug),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modrinthIconPlaceholder() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: ColorUtils.dynamicSecondaryForegroundColor,
        borderRadius: const BorderRadius.all(Radius.circular(6)),
      ),
      child: Icon(Icons.extension_outlined, size: 16, color: ColorUtils.secondaryFontColor),
    );
  }

  /////////// SETTING //////////////

  ListView buildSettingsList() {
    return ListView(
      children: [
        /** Separatore */
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: TextDivider(
            color: ColorUtils.secondaryFontColor.withAlpha(80),
            thickness: 2,
            text: Text(
              AppLocalizations.of(context)!.settings_appearance_label,
              textAlign: TextAlign.center,
              style: WidgetUtils.customTextStyle(
                20,
                FontWeight.w300,
                ColorUtils.primaryFontColor,
              ),
            ),
          ),
        ),

        /** Setting per la darkmode */
        WidgetUtils.buildSettingSwitchItem(
          AppLocalizations.of(context)!.settings_dark_mode_switch,
          "darkModeTheme",
          CustomSettingSwitchStyle(
            icon: Icons.invert_colors_rounded,
            bgColor: ColorUtils.dynamicPrimaryForegroundColor,
            shadowColor: ColorUtils.defaultShadowColor,
            fontColor: ColorUtils.primaryFontColor,
            toggleColor: ColorUtils.isMaterial ? ColorUtils.dynamicPrimaryForegroundColor : Colors.white,
            activeColor: ColorUtils.dynamicAccentColor,
            inactiveColor: ColorUtils.dynamicSecondaryForegroundColor,
          ),
          Globals.darkModeTheme,
          (value) {
            setState(() => Globals.darkModeTheme = value);
            ColorUtils.reloadColors();

            Window.setEffect(
              effect: getWindowEffect(),
              color: ColorUtils.dynamicBackgroundColor,
              dark: Globals.darkModeTheme,
            );
            if (Platform.isMacOS) {
              Window.overrideMacOSBrightness(
                dark: Globals.darkModeTheme,
              );
            }
          },
        ),

        /** Setting per il colore */
        WidgetUtils.buildSettingContainerItem(
          Stack(
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
                          Icons.color_lens,
                          color: ColorUtils.primaryFontColor,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  /** Nome del setting */
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.settings_follow_system_color,
                          style: WidgetUtils.customTextStyle(
                            16,
                            FontWeight.w500,
                            ColorUtils.primaryFontColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 18, 10, 0),
                    child: Material(
                      elevation: 15,
                      color: Colors.transparent,
                      shadowColor: Colors.transparent,
                      // Globals.defaultShadowColor,
                      borderRadius: const BorderRadius.all(Radius.circular(10)),
                      child: Row(
                        children: [
                          MouseRegion(
                            onEnter: (e) => {},
                            child: GestureDetector(
                              onTap: () async => {
                                Globals.accentColor = 0,
                                (await SharedPreferences.getInstance()).setInt('accentColor', Globals.accentColor),
                                setState(() => ColorUtils.dynamicAccentColor = ColorUtils.getColorFromAccent(
                                      Globals.accentColor,
                                    )),
                                ColorUtils.reloadColors(),
                                Window.setEffect(
                                  effect: getWindowEffect(),
                                  color: ColorUtils.dynamicBackgroundColor,
                                  dark: Globals.darkModeTheme,
                                ),
                                if (Platform.isMacOS) ...[
                                  Window.overrideMacOSBrightness(
                                    dark: Globals.darkModeTheme,
                                  ),
                                ],
                              },
                              child: Stack(
                                children: [
                                  ColoredCircle(
                                    size: 20,
                                    color: SystemTheme.accentColor.light.withAlpha(200),
                                    outlineColor: Globals.accentColor == 0 ? SystemTheme.accentColor.light : Colors.transparent,
                                    outlineWidth: 2,
                                    distance: 3,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(2, 4, 0, 0),
                                    child: Text(
                                      "OS",
                                      style: WidgetUtils.customTextStyle(
                                        10,
                                        FontWeight.w100,
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          for (int i = 1; i <= 7; i++) ...[
                            const SizedBox(
                              width: 2,
                            ),
                            MouseRegion(
                              onEnter: (e) => {},
                              child: GestureDetector(
                                onTap: () async => {
                                  Globals.accentColor = i,
                                  (await SharedPreferences.getInstance()).setInt(
                                    'accentColor',
                                    Globals.accentColor,
                                  ),
                                  setState(() => ColorUtils.dynamicAccentColor = ColorUtils.getColorFromAccent(
                                        Globals.accentColor,
                                      )),
                                  ColorUtils.reloadColors(),
                                  Window.setEffect(
                                    effect: getWindowEffect(),
                                    color: ColorUtils.dynamicBackgroundColor,
                                    dark: Globals.darkModeTheme,
                                  ),
                                  if (Platform.isMacOS) ...[
                                    Window.overrideMacOSBrightness(
                                      dark: Globals.darkModeTheme,
                                    ),
                                  ],
                                },
                                child: ColoredCircle(
                                  size: 20,
                                  color: ColorUtils.getColorFromAccent(i),
                                  outlineColor: Globals.accentColor == i
                                      ? ColorUtils.getColorFromAccent(
                                          Globals.accentColor,
                                        )
                                      : Colors.transparent,
                                  outlineWidth: 2,
                                  distance: 3,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        /** Setting Tema */
        WidgetUtils.buildSettingContainerItem(
          Stack(
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
                          Icons.brush,
                          color: ColorUtils.primaryFontColor,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                  /** Nome del setting */
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.settings_theme,
                          style: WidgetUtils.customTextStyle(
                            16,
                            FontWeight.w500,
                            ColorUtils.primaryFontColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 7),
                    child: Material(
                      elevation: 15,
                      color: Colors.transparent,
                      shadowColor: ColorUtils.defaultShadowColor,
                      borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
                      child: MouseRegion(
                        onEnter: (e) => {},
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2<String>(
                            isExpanded: true,
                            hint: Text(
                              'Theme',
                              style: WidgetUtils.customTextStyle(
                                16,
                                FontWeight.w500,
                                ColorUtils.primaryFontColor,
                              ),
                            ),
                            items: Globals.WindowThemes.map(
                              (String item) => DropdownItem<String>(
                                value: item,
                                child: Text(
                                  item,
                                  style: WidgetUtils.customTextStyle(
                                    16,
                                    FontWeight.w500,
                                    ColorUtils.primaryFontColor,
                                  ),
                                ),
                              ),
                            ).toList(),
                            valueListenable: _themeNotifier,
                            onChanged: (String? value) async {
                              _themeNotifier.value = value;
                              Globals.selectedWindowTheme = value!;
                              ColorUtils.isMaterial = (Globals.selectedWindowTheme.contains('Material'));

                              if (ColorUtils.isMaterial) Globals.fullTransparent = false;

                              SharedPreferences prefs = await SharedPreferences.getInstance();
                              await prefs.setString(
                                "themeSet",
                                Globals.selectedWindowTheme,
                              );
                              ColorUtils.reloadColors();

                              dynamic effect = getWindowEffect();
                              Window.setEffect(
                                effect: effect,
                                color: ColorUtils.dynamicBackgroundColor,
                                dark: Globals.darkModeTheme,
                              );
                              if (Platform.isMacOS) {
                                Window.overrideMacOSBrightness(
                                  dark: Globals.darkModeTheme,
                                );
                              }
                              setState(() => effect = effect);
                            },
                            buttonStyleData: ButtonStyleData(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              height: 40,
                              width: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  Globals.borderRadius - 4,
                                ),
                                color: ColorUtils.dynamicSecondaryForegroundColor,
                              ),
                            ),
                            menuItemStyleData: const MenuItemStyleData(),
                            dropdownStyleData: DropdownStyleData(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  Globals.borderRadius - 4,
                                ),
                                color: ColorUtils.dynamicPrimaryForegroundColor,
                              ),
                              offset: const Offset(0, -4),
                              elevation: ColorUtils.isMaterial ? 9 : 0,
                            ),
                            iconStyleData: IconStyleData(
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                              ),
                              iconSize: 14,
                              iconEnabledColor: ColorUtils.primaryFontColor,
                              iconDisabledColor: Colors.white30,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        /** Setting trasparenza per linux */
        if (Platform.isLinux && Globals.selectedWindowTheme == 'Clear') ...[
          WidgetUtils.buildSettingSwitchItem(
            "Disable background tinting",
            "fullTransparent",
            CustomSettingSwitchStyle(
              icon: Icons.format_paint_rounded,
              bgColor: ColorUtils.dynamicPrimaryForegroundColor,
              shadowColor: ColorUtils.defaultShadowColor,
              fontColor: ColorUtils.primaryFontColor,
              toggleColor: ColorUtils.isMaterial ? ColorUtils.dynamicPrimaryForegroundColor : Colors.white,
              activeColor: ColorUtils.dynamicAccentColor,
              inactiveColor: ColorUtils.dynamicSecondaryForegroundColor,
            ),
            Globals.fullTransparent,
            (value) {
              setState(() => Globals.fullTransparent = value);
            },
          ),
        ],

        /** Separatore */
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: TextDivider(
            color: ColorUtils.secondaryFontColor.withAlpha(80),
            thickness: 2,
            text: Text(
              AppLocalizations.of(context)!.settings_misc_label,
              textAlign: TextAlign.center,
              style: WidgetUtils.customTextStyle(
                20,
                FontWeight.w300,
                ColorUtils.primaryFontColor,
              ),
            ),
          ),
        ),

        /** Setting per nascondere tutto tranne le release */
        WidgetUtils.buildSettingSwitchItem(
          AppLocalizations.of(context)!.settings_only_release_switch,
          "showOnlyReleases",
          CustomSettingSwitchStyle(
            icon: Icons.widgets_rounded,
            bgColor: ColorUtils.dynamicPrimaryForegroundColor,
            shadowColor: ColorUtils.defaultShadowColor,
            fontColor: ColorUtils.primaryFontColor,
            toggleColor: ColorUtils.isMaterial ? ColorUtils.dynamicPrimaryForegroundColor : Colors.white,
            activeColor: ColorUtils.dynamicAccentColor,
            inactiveColor: ColorUtils.dynamicSecondaryForegroundColor,
          ),
          Globals.showOnlyReleases,
          (value) => setState(() => Globals.showOnlyReleases = value),
        ),

        /** Setting per mostrare la console */
        WidgetUtils.buildSettingSwitchItem(
          AppLocalizations.of(context)!.settings_console_switch,
          "showConsole",
          CustomSettingSwitchStyle(
            icon: Icons.terminal_rounded,
            bgColor: ColorUtils.dynamicPrimaryForegroundColor,
            shadowColor: ColorUtils.defaultShadowColor,
            fontColor: ColorUtils.primaryFontColor,
            toggleColor: ColorUtils.isMaterial ? ColorUtils.dynamicPrimaryForegroundColor : Colors.white,
            activeColor: ColorUtils.dynamicAccentColor,
            inactiveColor: ColorUtils.dynamicSecondaryForegroundColor,
          ),
          Globals.showConsole,
          (value) => setState(() => Globals.showConsole = value),
        ),

        /** Setting Java */
        WidgetUtils.buildSettingContainerItem(
          Column(
            children: [
              WidgetUtils.buildSettingSwitchItem(
                AppLocalizations.of(context)!.settings_java_advanced_settings,
                "javaAdvSet",
                CustomSettingSwitchStyle(
                  icon: MorpheusIcons.java,
                  bgColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  fontColor: ColorUtils.primaryFontColor,
                  toggleColor: ColorUtils.isMaterial ? ColorUtils.dynamicPrimaryForegroundColor : Colors.white,
                  activeColor: ColorUtils.dynamicAccentColor,
                  inactiveColor: ColorUtils.dynamicSecondaryForegroundColor,
                ),
                Globals.javaAdvSet,
                (value) => setState(() => Globals.javaAdvSet = value),
              ),
              if (Globals.javaAdvSet) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                  child: Column(
                    children: [
                      /** Java selection */
                      WidgetUtils.buildSettingTextItem(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 3, 3, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              WidgetUtils.buildButton(
                                Icons.folder,
                                ColorUtils.dynamicAccentColor,
                                Colors.white,
                                () async {
                                  FilePickerResult? result = await FilePicker.pickFiles();
                                  if (result != null) {
                                    File file = File(result.files.single.path!);
                                    Globals.javapathcontroller.text = file.path.replaceAll("\\", "/");
                                    SharedPreferences prefs = await SharedPreferences.getInstance();
                                    await prefs.setString(
                                      "javaPath",
                                      Globals.javapathcontroller.text,
                                    );
                                  }
                                },
                              ),
                              WidgetUtils.buildButton(
                                Icons.checklist,
                                ColorUtils.dynamicAccentColor,
                                Colors.white,
                                () async {
                                  final result = await LauncherUtils.checkJava();

                                  // Titolo fisso localizzato
                                  final title = AppLocalizations.of(context)!.settings_check_java_title;

                                  // Corpo del messaggio
                                  String message;
                                  if (result != null) {
                                    final type = result['type'];
                                    final version = result['version'];
                                    final date = result['releaseDate'];
                                    final lts = result['lts'] == 'true' ? 'LTS' : '';

                                    // Messaggio positivo + info JVM
                                    message =
                                        '${AppLocalizations.of(context)!.settings_check_java_yes}\n\n→ JVM: $type\n→ Versione: $version${date != null && date.isNotEmpty ? '\n→ Data rilascio: $date' : ''}${lts.isNotEmpty ? '\n→ Tipo: $lts' : ''}';
                                  } else {
                                    // Messaggio negativo
                                    message = AppLocalizations.of(context)!.settings_check_java_no;
                                  }

                                  // Mostra dialog
                                  WidgetUtils.showMessageDialog(
                                    context,
                                    title,
                                    message,
                                    () => Navigator.pop(context),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        ColorUtils.dynamicSecondaryForegroundColor,
                        ColorUtils.primaryFontColor,
                        AppLocalizations.of(context)!.settings_java_path_msg,
                        Globals.javapathcontroller,
                        (value) async {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                            "javaPath",
                            Globals.javapathcontroller.text,
                          );
                        },
                      ),
                      /** Java ram */
                      WidgetUtils.buildSettingTextItem(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 3, 3, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              WidgetUtils.buildButton(
                                Icons.memory,
                                ColorUtils.dynamicAccentColor,
                                Colors.white,
                                () => {},
                              ),
                            ],
                          ),
                        ),
                        ColorUtils.dynamicSecondaryForegroundColor,
                        ColorUtils.primaryFontColor,
                        AppLocalizations.of(context)!.settings_java_ram_msg,
                        Globals.javaramcontroller,
                        (value) async {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                            "javaRAM",
                            Globals.javaramcontroller.text,
                          );
                        },
                      ),
                      /** Java VM args */
                      WidgetUtils.buildSettingTextItem(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 3, 3, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              WidgetUtils.buildButton(
                                MorpheusIcons.java,
                                ColorUtils.dynamicAccentColor,
                                Colors.white,
                                () => {},
                              ),
                            ],
                          ),
                        ),
                        ColorUtils.dynamicSecondaryForegroundColor,
                        ColorUtils.primaryFontColor,
                        "VM Args",
                        Globals.javavmcontroller,
                        (value) async {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                            "javaVMArgs",
                            Globals.javavmcontroller.text,
                          );
                        },
                      ),
                      /** Launcher args */
                      WidgetUtils.buildSettingTextItem(
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 3, 3, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              WidgetUtils.buildButton(
                                Icons.terminal,
                                ColorUtils.dynamicAccentColor,
                                Colors.white,
                                () => {},
                              ),
                            ],
                          ),
                        ),
                        ColorUtils.dynamicSecondaryForegroundColor,
                        ColorUtils.primaryFontColor,
                        "Launcher args",
                        Globals.javalaunchercontroller,
                        (value) async {
                          SharedPreferences prefs = await SharedPreferences.getInstance();
                          await prefs.setString(
                            "javaLauncherArgs",
                            Globals.javalaunchercontroller.text,
                          );
                        },
                      ),
                      /** Modalità classpath */
                      WidgetUtils.buildSettingSwitchItem(
                        AppLocalizations.of(context)!.settings_force_classpath,
                        "forceClasspath",
                        CustomSettingSwitchStyle(
                          icon: Icons.fork_left_rounded,
                          bgColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          fontColor: ColorUtils.primaryFontColor,
                          toggleColor: ColorUtils.isMaterial ? ColorUtils.dynamicPrimaryForegroundColor : Colors.white,
                          activeColor: ColorUtils.dynamicAccentColor,
                          inactiveColor: ColorUtils.dynamicSecondaryForegroundColor,
                        ),
                        Globals.forceClasspath,
                        (value) => setState(() => Globals.forceClasspath = value),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        /** Cartella di installazione */
        WidgetUtils.buildSettingContainerItem(
          Column(
            children: [
              WidgetUtils.buildSettingSwitchItem(
                AppLocalizations.of(context)!.settings_custom_folder_title,
                "customFolderSet",
                CustomSettingSwitchStyle(
                  icon: Icons.folder_rounded,
                  bgColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  fontColor: ColorUtils.primaryFontColor,
                  toggleColor: ColorUtils.isMaterial ? ColorUtils.dynamicPrimaryForegroundColor : Colors.white,
                  activeColor: ColorUtils.dynamicAccentColor,
                  inactiveColor: ColorUtils.dynamicSecondaryForegroundColor,
                ),
                Globals.customFolderSet,
                (value) async => {
                  setState(() => Globals.customFolderSet = value),
                  if (!Globals.customFolderSet) ...[
                    Globals.gamefoldercontroller.text = LauncherUtils.getApplicationFolder("minecraft"),
                    await (await SharedPreferences.getInstance()).setString(
                      "gameFolderPath",
                      Globals.gamefoldercontroller.text,
                    ),
                  ],
                },
              ),
              if (Globals.customFolderSet) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
                  child: WidgetUtils.buildSettingTextItem(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 3, 3, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          WidgetUtils.buildButton(
                            Icons.folder,
                            ColorUtils.dynamicAccentColor,
                            Colors.white,
                            () async {
                              final String? selectedDirectory = await getDirectoryPath();
                              if (selectedDirectory != null) {
                                Globals.gamefoldercontroller.text = selectedDirectory.replaceAll("\\", "/");
                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                await prefs.setString(
                                  "gameFolderPath",
                                  Globals.gamefoldercontroller.text,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    ColorUtils.dynamicSecondaryForegroundColor,
                    ColorUtils.primaryFontColor,
                    AppLocalizations.of(context)!.settings_custom_folder,
                    Globals.gamefoldercontroller,
                    (value) async {
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.setString(
                        "gameFolderPath",
                        Globals.gamefoldercontroller.text,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),

        /* Tasti vari*/
        WidgetUtils.buildSettingContainerItem(
          Row(
            children: [
              /** Dati di diagnostica */
              WidgetUtils.buildTextButton(
                ColorUtils.dynamicSecondaryForegroundColor,
                ColorUtils.primaryFontColor,
                () {
                  WidgetUtils.showDiagnostic(context);
                },
                AppLocalizations.of(context)!.settings_diagnostic_title,
              ),

              /** Apri cartella di gioco */
              WidgetUtils.buildTextButton(
                ColorUtils.dynamicSecondaryForegroundColor,
                ColorUtils.primaryFontColor,
                () async {
                  final folder = Globals.gamefoldercontroller.text;
                  if (folder.isEmpty) return;

                  try {
                    if (Platform.isWindows) {
                      await Process.start('explorer', [folder.replaceAll('/', '\\')]);
                    } else if (Platform.isMacOS) {
                      await Process.start('open', [folder]);
                    } else if (Platform.isLinux) {
                      await Process.start('xdg-open', [folder]);
                    }
                  } catch (e) {
                    WidgetUtils.showMessageDialog(
                      context,
                      AppLocalizations.of(context)!.generic_error_msg,
                      e.toString(),
                      () => Navigator.pop(context),
                    );
                  }
                },
                AppLocalizations.of(context)!.settings_open_game_folder,
              ),
            ],
          ),
        ),

        /** Separatore */
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: TextDivider(
            color: ColorUtils.secondaryFontColor.withAlpha(80),
            thickness: 2,
            text: Text(
              AppLocalizations.of(context)!.settings_account_label,
              textAlign: TextAlign.center,
              style: WidgetUtils.customTextStyle(
                20,
                FontWeight.w300,
                ColorUtils.primaryFontColor,
              ),
            ),
          ),
        ),

        /**/
        WidgetUtils.buildSettingContainerItem(
          Row(children: [
            /** Bottone per pulire la cache */
            WidgetUtils.buildTextButton(
              Colors.red.withAlpha(160),
              Colors.white,
              () async {
                await DefaultCacheManager().emptyCache();
              },
              AppLocalizations.of(context)!.settings_clear_cache,
            ),

            /** Bottone per importare gli account */
            WidgetUtils.buildTextButton(
              ColorUtils.dynamicSecondaryForegroundColor,
              Colors.white,
              () async {
                final result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['json'],
                );
                if (result != null && result.files.single.path != null) {
                  final path = result.files.single.path!;
                  final importedAccounts = importAccountListFromJsonPlain(path);
                  Globals.accounts = importedAccounts;
                  saveAccounts();
                }
              },
              AppLocalizations.of(context)!.settings_account_import,
            ),

            /** Bottone per esportare gli account */
            WidgetUtils.buildTextButton(
              ColorUtils.dynamicSecondaryForegroundColor,
              Colors.white,
              () async {
                final result = await FilePicker.saveFile(
                  dialogTitle: 'Save accounts as JSON',
                  fileName: 'accounts_plain.json',
                  type: FileType.custom,
                  allowedExtensions: ['json'],
                );
                if (result != null) {
                  exportAccountListToJsonPlain(Globals.accounts, result);
                }
              },
              AppLocalizations.of(context)!.settings_account_export,
            ),
          ]),
        ),

        /** Separatore */
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Divider(
              color: ColorUtils.secondaryFontColor,
            ),
          ),
        ),

        /** Info */
        Center(
          child: GestureDetector(
            child: Text(
              "build: ${Globals.buildVersion} on ${extractPlatformInfo(Platform.version)} - morpheuslauncher.it (cc by-nc-sa) 2023-${DateTime.now().year}",
              style: WidgetUtils.customTextStyle(
                12,
                FontWeight.w500,
                ColorUtils.secondaryFontColor,
              ),
            ),
            onTap: () {
              WidgetUtils.showMessageDialog(
                context,
                AppLocalizations.of(context)!.settings_credits_title,
                AppLocalizations.of(context)!.settings_credits_content,
                () => Navigator.pop(context),
              );
            },
          ),
        ),

        /** Links vari */
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              linkIcon(MorpheusIcons.globe, 'https://morpheuslauncher.it'),
              linkIcon(MorpheusIcons.discord, 'https://discord.gg/aerXnBe'),
              linkIcon(
                MorpheusIcons.github_mark,
                'https://github.com/MorpheusLauncher',
              ),
              linkIcon(
                MorpheusIcons.patreon,
                'https://www.patreon.com/c/Lampadina_17',
              ),
              linkIcon(MorpheusIcons.kofi, 'https://ko-fi.com/lampadina_17'),
            ],
          ),
        ),
      ],
    );
  }

  Widget linkIcon(IconData icon, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: HoverIcon(icon: icon, url: url),
    );
  }

  String extractPlatformInfo(String versionString) {
    RegExp regex = RegExp(r'([a-zA-Z0-9]+_[a-zA-Z0-9]+)');
    RegExpMatch? match = regex.firstMatch(versionString);

    return match != null ? match.group(0)! : 'N/A';
  }

  /////////// ACCOUNT //////////////

  Widget _buildAccountsPage() {
    return Row(children: [
      buildNavbar(),
      const SizedBox(width: 8),
      /** Lista account */
      Expanded(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: buildAccountList(),
        ),
      ),
      const SizedBox(width: 10),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          /** Mostra la skin del player a destra */
          if (Globals.getAccount() != null && ThreeDimensionalViewer.objs.isNotEmpty) ...[
            Sp3dRenderer(
              const Size(150, 280),
              const Sp3dV2D(75, 125),
              ThreeDimensionalViewer.world,
              Sp3dCamera(Sp3dV3D(0, 0, 3000), 1500),
              Sp3dLight(Sp3dV3D(0, 0, 0), syncCam: true),
              allowUserWorldZoom: false,
              allowUserWorldRotation: true,
              useClipping: true,
            ),
          ],
          const SizedBox(height: 5),

          /** Pulsante Cambia Skin */
          WidgetUtils.buildButton(
            Icons.brush,
            ColorUtils.dynamicPrimaryForegroundColor,
            ColorUtils.primaryFontColor,
            () async {
              if (Globals.getAccount()!.isPremium) {
                WidgetUtils.showPopup(
                  context,
                  AppLocalizations.of(context)!.account_skin_uploader_type_title,
                  <Widget>[
                    Text(
                      AppLocalizations.of(context)!.account_skin_uploader_msg,
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
                        "Slim",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Comfortaa',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        FilePickerResult? result = await FilePicker.pickFiles();
                        if (result != null) {
                          File file = File(result.files.single.path!);
                          WidgetUtils.showMessageDialog(
                            context,
                            AppLocalizations.of(context)!.account_skin_uploader_title,
                            await uploadSkin(context, "slim", Globals.getAccount()!, file.path.replaceAll("\\", "/")),
                            () => Navigator.pop(context),
                          );
                        }
                      },
                    ),
                    TextButton(
                      child: const Text(
                        "Classic",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Comfortaa',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        FilePickerResult? result = await FilePicker.pickFiles();
                        if (result != null) {
                          File file = File(result.files.single.path!);
                          WidgetUtils.showMessageDialog(
                            context,
                            AppLocalizations.of(context)!.account_skin_uploader_title,
                            await uploadSkin(context, "classic", Globals.getAccount()!, file.path.replaceAll("\\", "/")),
                            () => Navigator.pop(context),
                          );
                        }
                      },
                    ),
                    TextButton(
                      child: Text(
                        AppLocalizations.of(context)!.generic_cancel,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Comfortaa',
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                      onPressed: () async => Navigator.pop(context),
                    ),
                  ],
                );
              } else {
                WidgetUtils.showPopup(
                  context,
                  AppLocalizations.of(context)!.generic_error_msg,
                  [
                    Text(
                      AppLocalizations.of(context)!.account_skin_error_msg,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Comfortaa',
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                  [
                    TextButton(
                      onPressed: () async {
                        await launchUrl(Uri.parse(
                          "https://www.minecraft.net/it-it/store/minecraft-java-bedrock-edition-pc",
                        ));
                        Navigator.pop(context);
                      },
                      child: Text(
                        AppLocalizations.of(context)!.account_skin_buy_game,
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Comfortaa',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "OK",
                        style: TextStyle(
                          fontSize: 14,
                          fontFamily: 'Comfortaa',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),

          /** Pulsanti add remove */
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              /** Aggiungi Account */
              WidgetUtils.buildButton(
                Icons.add,
                ColorUtils.dynamicPrimaryForegroundColor,
                ColorUtils.primaryFontColor,
                () {
                  /** Selezione tipo di account */
                  WidgetUtils.showPopup(
                    context,
                    AppLocalizations.of(context)!.account_add_button,
                    <Widget>[
                      Text(
                        AppLocalizations.of(context)!.account_add_type,
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
                          "Offline",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Comfortaa',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          AccountUtils.addSP(
                            context,
                            () => {
                              setState(() {
                                if (Globals.usernamecontroller.text.isNotEmpty) {
                                  Globals.accounts.add(
                                    Account(
                                      username: Globals.usernamecontroller.text,
                                      uuid: getOfflinePlayerUuid(
                                        Globals.usernamecontroller.text,
                                      ).toString(),
                                      accessToken: "0",
                                      refreshToken: "",
                                      isPremium: false,
                                      isSlimSkin: isOfflineSlimSkin(Globals.usernamecontroller.text),
                                      isElyBy: false,
                                    ),
                                  );
                                }
                                saveAccounts();
                                Globals.usernamecontroller.text = "";
                              }),
                              rebuild(),
                            },
                          );
                        },
                      ),
                      TextButton(
                        child: const Text(
                          "Offline (Ely.by)",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Comfortaa',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          AccountUtils.addElyBy(
                            context,
                            (
                              username,
                              uuid,
                              accesstoken,
                              refreshtoken,
                              isSlimSkin,
                            ) =>
                                {
                              setState(
                                () {
                                  Globals.accounts.add(
                                    Account(
                                      username: username,
                                      uuid: uuid,
                                      accessToken: accesstoken,
                                      refreshToken: refreshtoken,
                                      isPremium: false,
                                      isSlimSkin: isSlimSkin,
                                      isElyBy: true,
                                    ),
                                  );
                                  saveAccounts();
                                },
                              ),
                              rebuild(),
                            },
                          );
                        },
                      ),
                      TextButton(
                        child: const Text(
                          "Premium",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Comfortaa',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onPressed: () {
                          AccountUtils.addPremium(
                            context,
                            (
                              username,
                              uuid,
                              accesstoken,
                              refreshtoken,
                              isPremium,
                              isSlimSkin,
                            ) =>
                                {
                              setState(
                                () {
                                  Globals.accounts.add(
                                    Account(
                                      username: username,
                                      uuid: uuid,
                                      accessToken: accesstoken,
                                      refreshToken: refreshtoken,
                                      isPremium: isPremium,
                                      isSlimSkin: isSlimSkin,
                                      isElyBy: false,
                                    ),
                                  );
                                },
                              ),
                              rebuild(),
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
              /** Remove Account */
              WidgetUtils.buildButton(
                Icons.remove,
                ColorUtils.dynamicPrimaryForegroundColor,
                ColorUtils.primaryFontColor,
                () {
                  setState(() {
                    if (Globals.accounts.isNotEmpty) {
                      Globals.accounts.removeAt(Globals.AccountSelected);
                      saveAccounts();
                    } else {
                      WidgetUtils.showMessageDialog(
                        context,
                        AppLocalizations.of(context)!.generic_error_msg,
                        AppLocalizations.of(context)!.account_remove_error,
                        () => Navigator.pop(context),
                      );
                    }
                    Globals.AccountSelected = 0;
                  });
                  rebuild();
                },
              ),
            ],
          ),
        ],
      ),
      const SizedBox(width: 10),
    ]);
  }

  ListView buildAccountList() {
    return ListView(
      children: [
        if (Globals.accounts.isNotEmpty) ...[
          /** Lista degli account */
          _buildResponsiveTileGrid(
            [
              for (var account in Globals.accounts)
                buildAccountEntry(
                  account.username,
                  account.isPremium,
                  account.isElyBy,
                  Globals.accounts.indexOf(account),
                ),
            ],
            minTileWidth: 280,
          ),
        ] else ...[
          /** mostra il messaggio quando non ci sono account */
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Text(
              AppLocalizations.of(context)!.account_empty_msg,
              textAlign: TextAlign.center,
              style: WidgetUtils.customTextStyle(
                14,
                FontWeight.w300,
                ColorUtils.primaryFontColor,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget buildAccountEntry(String username, bool premium, bool elyby, int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
      child: SizedBox(
        height: 55,
        width: double.infinity,
        child: Material(
          elevation: 15,
          color: ColorUtils.dynamicPrimaryForegroundColor,
          shadowColor: ColorUtils.defaultShadowColor,
          borderRadius: const BorderRadius.all(Radius.circular(Globals.borderRadius)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      opacity: 0.8,
                      image: CachedNetworkImageProvider("${Urls.skinURL}/head/$username"),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WidgetUtils.customTextStyle(18, FontWeight.w500, ColorUtils.primaryFontColor),
                    ),
                    Text(
                      premium ? "Premium" : (elyby ? "ElyBy" : "Offline"),
                      maxLines: 1,
                      style: WidgetUtils.customTextStyle(14, FontWeight.w300, ColorUtils.secondaryFontColor),
                    ),
                  ],
                ),
              ),
              WidgetUtils.buildButton(
                Icons.check,
                Globals.AccountSelected == index ? ColorUtils.dynamicAccentColor : ColorUtils.dynamicSecondaryForegroundColor,
                Globals.AccountSelected == index ? Colors.white : (Globals.darkModeTheme ? Colors.white.withAlpha(80) : Colors.black.withAlpha(80)),
                () {
                  setState(() => Globals.AccountSelected = index);
                  rebuild();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HoverIcon extends StatefulWidget {
  final IconData icon;
  final String url;

  const HoverIcon({super.key, required this.icon, required this.url});

  @override
  _HoverIconState createState() => _HoverIconState();
}

class _HoverIconState extends State<HoverIcon> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () async {
          if (!await launchUrl(Uri.parse(widget.url))) {
            throw 'Unable to open the link: ${widget.url}';
          }
        },
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 100),
          tween: ColorTween(
            begin: _hovering ? ColorUtils.secondaryFontColor.withAlpha(128) : ColorUtils.secondaryFontColor.withAlpha(255),
            end: _hovering ? ColorUtils.secondaryFontColor.withAlpha(255) : ColorUtils.secondaryFontColor.withAlpha(128),
          ),
          builder: (context, color, child) => Icon(
            widget.icon,
            color: color,
          ),
        ),
      ),
    );
  }
}

class AccountUtils {
  //////////////////////////////////
  /////// ACCOUNT MANAGER //////////
  //////////////////////////////////

  static void addSP(
    dynamic context,
    Function callback,
  ) {
    Navigator.pop(context);
    WidgetUtils.showPopup(
      context,
      AppLocalizations.of(context)!.account_add_offline,
      <Widget>[
        Material(
          elevation: 10,
          color: Colors.transparent,
          shadowColor: ColorUtils.defaultShadowColor,
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: WidgetUtils.buildSettingTextItem(
            null,
            Colors.white /* Sfondo della textbox */,
            Colors.black /* Colore del font della textbox */,
            "Username",
            Globals.usernamecontroller,
            (value) => null,
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
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: () {
            callback();
            Navigator.pop(context);
          },
        ),
      ],
    );
  }

  static Future<void> addElyBy(
    context,
    Function(
      dynamic username,
      dynamic uuid,
      dynamic accessToken,
      dynamic refreshToken,
      dynamic isSlimSkin,
    ) callback,
  ) async {
    const clientID = "morpheus-launcher3";
    const redirectUri = "${Urls.morpheusBaseURL}/elyby";
    final authUrl = "${Urls.elybyBaseURL}/oauth2/v1?client_id=$clientID"
        "&redirect_uri=${Uri.encodeComponent(redirectUri)}"
        "&response_type=code"
        "&scope=account_email account_info offline_access";

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 5100);

    // Lanciatore universale per url
    await launchUrl(Uri.parse(authUrl));

    await for (HttpRequest request in server) {
      if (request.uri.path == "/callback") {
        final accessToken = request.uri.queryParameters["accessToken"];
        final refreshToken = request.uri.queryParameters["refreshToken"];

        if (accessToken == null || refreshToken == null) {
          request.response
            ..statusCode = 400
            ..write("Missing tokens")
            ..close();
          continue;
        }

        final htmlPage = await rootBundle.loadString('assets/pages/elyby_success.html');

        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write(htmlPage)
          ..close();

        final userResponse = await http.get(
          Uri.parse("${Urls.elybyBaseURL}/api/account/v1/info"),
          headers: {"Authorization": "Bearer $accessToken"},
        );

        if (userResponse.statusCode == 200) {
          final userData = jsonDecode(userResponse.body);
          final username = userData["username"];
          final uuid = userData["uuid"];

          bool isSlimSkin = false;

          try {
            final skinUrl = Uri.parse('${Urls.elybySkinsURL}/textures/$username');
            final skinResponse = await http.get(skinUrl);

            if (skinResponse.statusCode == 200 && skinResponse.body.isNotEmpty) {
              final data = jsonDecode(skinResponse.body);

              if (data.containsKey('SKIN')) {
                final skin = data['SKIN'];
                final model = skin['metadata']?['model'];
                isSlimSkin = model == 'slim';
              }
            }
          } catch (e) {}

          callback(username, uuid, accessToken, refreshToken, isSlimSkin);
        }

        await server.close(force: true);
        Navigator.pop(context);
        break;
      } else {
        request.response
          ..statusCode = 404
          ..write("Not found")
          ..close();
      }
    }
  }

  static Future<void> refreshPremium(
    dynamic context,
  ) async {
    if (Globals.getAccount()?.isPremium == true) {
      Globals.consolecontroller.append("[LAUNCHER]: ${AppLocalizations.of(context)!.account_token_refresh}\n");

      try {
        var minecraftAuth = await doMicrosoftRefresh(context, Globals.getAccount()!.refreshToken);
        if (!minecraftAuth.toString().startsWith("[MC]:")) {
          var minecraftToken = minecraftAuth['access_token'];
          var minecraft = await fetchMinecraftProfile(context, minecraftToken);

          if (!minecraft.toString().startsWith("[MC]:")) {
            Globals.getAccount()?.accessToken = minecraftToken;
            saveAccounts();
          } else {
            WidgetUtils.showMessageDialog(
              context,
              AppLocalizations.of(context)!.generic_error_msg,
              "$minecraft",
              () => Navigator.pop(context),
            );
          }
        }
      } catch (e) {
        Globals.consolecontroller.append("[LAUNCHER]: ${AppLocalizations.of(context)!.account_token_fail}\n");
      }
    }
  }

  static Future<void> addPremium(
    dynamic context,
    Function(
      dynamic username,
      dynamic uuid,
      dynamic accesstoken,
      dynamic refreshtoken,
      bool isPremium,
      bool isSlimSkin,
    ) callback,
  ) async {
    String str = await doMicrosoftConsent(context);

    if (!str.startsWith("[MS]:")) {
      Map<String, dynamic> data = json.decode(str);
      final String userCode = data['user_code'];
      final String deviceCode = data['device_code'];
      final String verificationUri = data['verification_uri'];

      print(verificationUri);
      print(userCode);

      Navigator.pop(context);

      WidgetUtils.showPopup(
        context,
        AppLocalizations.of(context)!.account_add_premium,
        <Widget>[
          Text(
            "${AppLocalizations.of(context)!.account_add_link1}: $verificationUri\n\n${AppLocalizations.of(context)!.account_add_link2} $userCode",
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
              AppLocalizations.of(context)!.account_add_copy,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Comfortaa',
                fontWeight: FontWeight.w300,
              ),
            ),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: userCode));
              if (!await launchUrl(Uri.parse(verificationUri))) {
                throw Exception(
                  "${AppLocalizations.of(context)!.account_add_fail}: $verificationUri",
                );
              }
            },
          ),
          TextButton(
            child: const Text(
              "OK",
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Comfortaa',
                fontWeight: FontWeight.w300,
              ),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      );

      Timer.periodic(const Duration(seconds: 3), (timer) async {
        var data = await getToken(
          context,
          'urn:ietf:params:oauth:grant-type:device_code',
          null,
          deviceCode,
        );
        if (data != null) {
          if (!data.toString().startsWith("[MS]:")) {
            var microsoftAccess = data['access_token'];
            var microsoftRefresh = data['refresh_token'];
            var minecraftAuth = await doXboxLiveAuth(context, microsoftAccess);
            if (!minecraftAuth.toString().startsWith("[MC]:")) {
              var minecraftToken = minecraftAuth['access_token'];
              var minecraft = await fetchMinecraftProfile(context, minecraftToken);

              if (!minecraft.toString().startsWith("[MC]:")) {
                // print('ID: ${minecraft['id']}');
                // print('Name: ${minecraft['name']}');
                // print('Skins: ${minecraft['skins']}');
                // print('Capes: ${minecraft['capes']}');
                // print('Profile actions: ${minecraft['profileActions']}');
                bool slim = minecraft['skins'][0]["variant"].toString().toUpperCase().contains("SLIM");
                callback(
                  minecraft['name'], // username
                  minecraft['id'], // uuid
                  minecraftToken, // token (gioco)
                  microsoftRefresh, // token (ms refresh)
                  true, // premium
                  slim, // skin type
                );
                saveAccounts();
                Navigator.pop(context);
              } else {
                WidgetUtils.showMessageDialog(
                  context,
                  AppLocalizations.of(context)!.generic_error_msg,
                  "$minecraft",
                  () => Navigator.pop(context),
                );
              }
            } else {
              WidgetUtils.showMessageDialog(
                context,
                AppLocalizations.of(context)!.generic_error_msg,
                "$minecraftAuth",
                () => Navigator.pop(context),
              );
            }
            timer.cancel();
          }
        }
      });
    } else {
      WidgetUtils.showMessageDialog(
        context,
        AppLocalizations.of(context)!.generic_error_msg,
        str,
        () => Navigator.pop(context),
      );
    }
  }
}
