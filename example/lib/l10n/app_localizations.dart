import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it'),
    Locale('pl')
  ];

  /// No description provided for @generic_error_msg.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get generic_error_msg;

  /// No description provided for @generic_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get generic_cancel;

  /// No description provided for @home_favourite_title.
  ///
  /// In en, this message translates to:
  /// **'Pinned Versions'**
  String get home_favourite_title;

  /// No description provided for @home_news_title.
  ///
  /// In en, this message translates to:
  /// **'Changelog'**
  String get home_news_title;

  /// No description provided for @home_news_empty_msg.
  ///
  /// In en, this message translates to:
  /// **'Cannot fetch minecraft changelog from mojang, please allow this program through your firewall'**
  String get home_news_empty_msg;

  /// No description provided for @morpheus_products_empty.
  ///
  /// In en, this message translates to:
  /// **'Unable to fetch morpheus products'**
  String get morpheus_products_empty;

  /// No description provided for @vanilla_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No vanilla minecraft versions found'**
  String get vanilla_empty_title;

  /// No description provided for @vanilla_release_title.
  ///
  /// In en, this message translates to:
  /// **'Latest release'**
  String get vanilla_release_title;

  /// No description provided for @vanilla_snapshot_title.
  ///
  /// In en, this message translates to:
  /// **'Latest snapshot'**
  String get vanilla_snapshot_title;

  /// No description provided for @modded_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No modded minecraft versions found'**
  String get modded_empty_title;

  /// No description provided for @modded_installed_title.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get modded_installed_title;

  /// No description provided for @modded_available_versions_title.
  ///
  /// In en, this message translates to:
  /// **'Modded versions available'**
  String get modded_available_versions_title;

  /// No description provided for @modded_modrinth_button.
  ///
  /// In en, this message translates to:
  /// **'Modpacks on Modrinth'**
  String get modded_modrinth_button;

  /// No description provided for @modded_modrinth_title.
  ///
  /// In en, this message translates to:
  /// **'Modrinth Modpacks'**
  String get modded_modrinth_title;

  /// No description provided for @modded_modrinth_search.
  ///
  /// In en, this message translates to:
  /// **'Search modpacks...'**
  String get modded_modrinth_search;

  /// No description provided for @modded_modrinth_section_title.
  ///
  /// In en, this message translates to:
  /// **'Modpacks'**
  String get modded_modrinth_section_title;

  /// No description provided for @modded_modrinth_empty.
  ///
  /// In en, this message translates to:
  /// **'No modpacks found'**
  String get modded_modrinth_empty;

  /// No description provided for @modpack_details_title.
  ///
  /// In en, this message translates to:
  /// **'Modpack Details'**
  String get modpack_details_title;

  /// No description provided for @modpack_author_by.
  ///
  /// In en, this message translates to:
  /// **'by {author}'**
  String modpack_author_by(String author);

  /// No description provided for @modpack_stats_downloads.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get modpack_stats_downloads;

  /// No description provided for @modpack_stats_updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get modpack_stats_updated;

  /// No description provided for @modpack_stats_size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get modpack_stats_size;

  /// No description provided for @modpack_download_button.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get modpack_download_button;

  /// No description provided for @modpack_description_title.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get modpack_description_title;

  /// No description provided for @modpack_mod_list_title.
  ///
  /// In en, this message translates to:
  /// **'Mod List'**
  String get modpack_mod_list_title;

  /// No description provided for @modpack_unknown_author.
  ///
  /// In en, this message translates to:
  /// **'Unknown author'**
  String get modpack_unknown_author;

  /// No description provided for @modpack_unknown_mod.
  ///
  /// In en, this message translates to:
  /// **'Unknown mod'**
  String get modpack_unknown_mod;

  /// No description provided for @settings_only_release_switch.
  ///
  /// In en, this message translates to:
  /// **'Show only releases'**
  String get settings_only_release_switch;

  /// No description provided for @settings_dark_mode_switch.
  ///
  /// In en, this message translates to:
  /// **'Enable dark theme'**
  String get settings_dark_mode_switch;

  /// No description provided for @settings_follow_system_color.
  ///
  /// In en, this message translates to:
  /// **'Accent color'**
  String get settings_follow_system_color;

  /// No description provided for @settings_check_java_title.
  ///
  /// In en, this message translates to:
  /// **'Does java work?'**
  String get settings_check_java_title;

  /// No description provided for @settings_check_java_yes.
  ///
  /// In en, this message translates to:
  /// **'Yes, your java works'**
  String get settings_check_java_yes;

  /// No description provided for @settings_check_java_no.
  ///
  /// In en, this message translates to:
  /// **'No, please select the correct java executable for your os'**
  String get settings_check_java_no;

  /// No description provided for @settings_java_path_msg.
  ///
  /// In en, this message translates to:
  /// **'Java Executable Path'**
  String get settings_java_path_msg;

  /// No description provided for @settings_java_ram_msg.
  ///
  /// In en, this message translates to:
  /// **'Java maximum RAM allocation'**
  String get settings_java_ram_msg;

  /// No description provided for @settings_java_advanced_settings.
  ///
  /// In en, this message translates to:
  /// **'Java advanced settings'**
  String get settings_java_advanced_settings;

  /// No description provided for @settings_appearance_label.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_appearance_label;

  /// No description provided for @settings_theme.
  ///
  /// In en, this message translates to:
  /// **'Launcher theme'**
  String get settings_theme;

  /// No description provided for @settings_misc_label.
  ///
  /// In en, this message translates to:
  /// **'Miscellaneous'**
  String get settings_misc_label;

  /// No description provided for @settings_console_switch.
  ///
  /// In en, this message translates to:
  /// **'Show console on game start'**
  String get settings_console_switch;

  /// No description provided for @settings_custom_folder_title.
  ///
  /// In en, this message translates to:
  /// **'Custom game folder'**
  String get settings_custom_folder_title;

  /// No description provided for @settings_custom_folder.
  ///
  /// In en, this message translates to:
  /// **'Game directory'**
  String get settings_custom_folder;

  /// No description provided for @settings_open_game_folder.
  ///
  /// In en, this message translates to:
  /// **'Open game folder'**
  String get settings_open_game_folder;

  /// No description provided for @settings_credits_title.
  ///
  /// In en, this message translates to:
  /// **'Acknowledgments'**
  String get settings_credits_title;

  /// No description provided for @settings_credits_content.
  ///
  /// In en, this message translates to:
  /// **'This software has been developed using various open-source libraries: \n\nmaterial_color_utilities, flutter_localization, cached_network_image, simple_3d_renderer, shared_preferences, flutter_markdown, dropdown_button2, bitsdojo_window, flutter_switch, url_launcher, system_theme, flutter_html, text_divider, file_picker, process_run, file_selector, http_parser, provider, archive, encrypt, crypto, image, http, intl, blur, cupertino_icons. \n\nWe sincerely thank everyone who contributed to the development of these libraries, making the creation of this software possible.'**
  String get settings_credits_content;

  /// No description provided for @settings_diagnostic_title.
  ///
  /// In en, this message translates to:
  /// **'Diagnostic data'**
  String get settings_diagnostic_title;

  /// No description provided for @settings_diagnostic_copy.
  ///
  /// In en, this message translates to:
  /// **'Copy log'**
  String get settings_diagnostic_copy;

  /// No description provided for @settings_clear_cache.
  ///
  /// In en, this message translates to:
  /// **'Clear skin caches'**
  String get settings_clear_cache;

  /// No description provided for @settings_force_classpath.
  ///
  /// In en, this message translates to:
  /// **'Force classpath mode'**
  String get settings_force_classpath;

  /// No description provided for @settings_account_label.
  ///
  /// In en, this message translates to:
  /// **'Account management'**
  String get settings_account_label;

  /// No description provided for @settings_account_import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get settings_account_import;

  /// No description provided for @settings_account_export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get settings_account_export;

  /// No description provided for @account_skin_buy_game.
  ///
  /// In en, this message translates to:
  /// **'buy minecraft'**
  String get account_skin_buy_game;

  /// No description provided for @account_skin_error_msg.
  ///
  /// In en, this message translates to:
  /// **'Only premium accounts can change skin.\nConsider buying minecraft java edition at minecraft.net'**
  String get account_skin_error_msg;

  /// No description provided for @account_empty_msg.
  ///
  /// In en, this message translates to:
  /// **'Before you can play minecraft, you should add an SP or Premium account'**
  String get account_empty_msg;

  /// No description provided for @account_add_button.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get account_add_button;

  /// No description provided for @account_add_type.
  ///
  /// In en, this message translates to:
  /// **'What type of account do you want to add?'**
  String get account_add_type;

  /// No description provided for @account_add_premium.
  ///
  /// In en, this message translates to:
  /// **'Link a Premium account'**
  String get account_add_premium;

  /// No description provided for @account_add_offline.
  ///
  /// In en, this message translates to:
  /// **'Add an SP account'**
  String get account_add_offline;

  /// No description provided for @account_add_link1.
  ///
  /// In en, this message translates to:
  /// **'Please open in your browser'**
  String get account_add_link1;

  /// No description provided for @account_add_link2.
  ///
  /// In en, this message translates to:
  /// **'And enter this code'**
  String get account_add_link2;

  /// No description provided for @account_add_copy.
  ///
  /// In en, this message translates to:
  /// **'Open link and copy the code'**
  String get account_add_copy;

  /// No description provided for @account_add_fail.
  ///
  /// In en, this message translates to:
  /// **'Could not open'**
  String get account_add_fail;

  /// No description provided for @account_remove_error.
  ///
  /// In en, this message translates to:
  /// **'you can\'t remove an inexistent item :P'**
  String get account_remove_error;

  /// No description provided for @account_required_title.
  ///
  /// In en, this message translates to:
  /// **'Minecraft account required'**
  String get account_required_title;

  /// No description provided for @account_required_msg.
  ///
  /// In en, this message translates to:
  /// **'Please add an SP or Premium account before launching the game'**
  String get account_required_msg;

  /// No description provided for @account_token_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refreshing microsoft account token'**
  String get account_token_refresh;

  /// No description provided for @account_token_fail.
  ///
  /// In en, this message translates to:
  /// **'Unable to refresh microsoft account token'**
  String get account_token_fail;

  /// No description provided for @account_post_fail.
  ///
  /// In en, this message translates to:
  /// **'Error while running post request'**
  String get account_post_fail;

  /// No description provided for @account_get_fail.
  ///
  /// In en, this message translates to:
  /// **'Error while running get request'**
  String get account_get_fail;

  /// No description provided for @account_skin_uploader_type_title.
  ///
  /// In en, this message translates to:
  /// **'Choose Skin Type'**
  String get account_skin_uploader_type_title;

  /// No description provided for @account_skin_uploader_title.
  ///
  /// In en, this message translates to:
  /// **'Skin uploader'**
  String get account_skin_uploader_title;

  /// No description provided for @account_skin_uploader_msg.
  ///
  /// In en, this message translates to:
  /// **'classic (like Steve), slim (like Alex)'**
  String get account_skin_uploader_msg;

  /// No description provided for @account_skin_success.
  ///
  /// In en, this message translates to:
  /// **'Skin Succesfully changed!'**
  String get account_skin_success;

  /// No description provided for @account_skin_file_fail.
  ///
  /// In en, this message translates to:
  /// **'File not found at'**
  String get account_skin_file_fail;

  /// No description provided for @account_xsts_2148916233_fail.
  ///
  /// In en, this message translates to:
  /// **'The account doesn\'t have an Xbox account.'**
  String get account_xsts_2148916233_fail;

  /// No description provided for @account_xsts_2148916235_fail.
  ///
  /// In en, this message translates to:
  /// **'The account is from a country where Xbox Live is not available/banned'**
  String get account_xsts_2148916235_fail;

  /// No description provided for @account_xsts_2148916237_fail.
  ///
  /// In en, this message translates to:
  /// **'The account needs adult verification on Xbox page. (South Korea)'**
  String get account_xsts_2148916237_fail;

  /// No description provided for @account_xsts_2148916238_fail.
  ///
  /// In en, this message translates to:
  /// **'The account is a child (under 18) and cannot proceed unless the account is added to a Family by an adult.'**
  String get account_xsts_2148916238_fail;

  /// No description provided for @console_game_kill_msg.
  ///
  /// In en, this message translates to:
  /// **'Killed minecraft process'**
  String get console_game_kill_msg;

  /// No description provided for @console_clear_msg.
  ///
  /// In en, this message translates to:
  /// **'Cleared console log'**
  String get console_clear_msg;

  /// No description provided for @console_exit_title.
  ///
  /// In en, this message translates to:
  /// **'Console exit confirmation'**
  String get console_exit_title;

  /// No description provided for @console_exit_msg1.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to close console?'**
  String get console_exit_msg1;

  /// No description provided for @console_exit_msg2.
  ///
  /// In en, this message translates to:
  /// **'if you close the console you can\'t read what the game does anymore'**
  String get console_exit_msg2;

  /// No description provided for @console_exit_kill.
  ///
  /// In en, this message translates to:
  /// **'Kill game and Exit'**
  String get console_exit_kill;

  /// No description provided for @console_exit_only.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get console_exit_only;

  /// No description provided for @console_crash_msg.
  ///
  /// In en, this message translates to:
  /// **'Seems that minecraft has crashed! do you want to analyze the crashlog?'**
  String get console_crash_msg;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'de',
        'en',
        'es',
        'fr',
        'it',
        'pl'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
