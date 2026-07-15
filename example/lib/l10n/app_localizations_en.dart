// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get generic_error_msg => 'An error occurred';

  @override
  String get generic_cancel => 'Cancel';

  @override
  String get home_favourite_title => 'Pinned Versions';

  @override
  String get home_news_title => 'Changelog';

  @override
  String get home_news_empty_msg =>
      'Cannot fetch minecraft changelog from mojang, please allow this program through your firewall';

  @override
  String get morpheus_products_empty => 'Unable to fetch morpheus products';

  @override
  String get vanilla_empty_title => 'No vanilla minecraft versions found';

  @override
  String get vanilla_release_title => 'Latest release';

  @override
  String get vanilla_snapshot_title => 'Latest snapshot';

  @override
  String get modded_empty_title => 'No modded minecraft versions found';

  @override
  String get modded_installed_title => 'Installed';

  @override
  String get modded_available_versions_title => 'Modded versions available';

  @override
  String get modded_modrinth_button => 'Modpacks on Modrinth';

  @override
  String get modded_modrinth_title => 'Modrinth Modpacks';

  @override
  String get modded_modrinth_search => 'Search modpacks...';

  @override
  String get modded_modrinth_section_title => 'Modpacks';

  @override
  String get modded_modrinth_empty => 'No modpacks found';

  @override
  String get modpack_details_title => 'Modpack Details';

  @override
  String modpack_author_by(String author) {
    return 'by $author';
  }

  @override
  String get modpack_stats_downloads => 'Downloads';

  @override
  String get modpack_stats_updated => 'Updated';

  @override
  String get modpack_stats_size => 'Size';

  @override
  String get modpack_download_button => 'Download';

  @override
  String get modpack_description_title => 'Description';

  @override
  String get modpack_mod_list_title => 'Mod List';

  @override
  String get modpack_unknown_author => 'Unknown author';

  @override
  String get modpack_unknown_mod => 'Unknown mod';

  @override
  String get settings_only_release_switch => 'Show only releases';

  @override
  String get settings_dark_mode_switch => 'Enable dark theme';

  @override
  String get settings_follow_system_color => 'Accent color';

  @override
  String get settings_check_java_title => 'Does java work?';

  @override
  String get settings_check_java_yes => 'Yes, your java works';

  @override
  String get settings_check_java_no =>
      'No, please select the correct java executable for your os';

  @override
  String get settings_java_path_msg => 'Java Executable Path';

  @override
  String get settings_java_ram_msg => 'Java maximum RAM allocation';

  @override
  String get settings_java_advanced_settings => 'Java advanced settings';

  @override
  String get settings_appearance_label => 'Appearance';

  @override
  String get settings_theme => 'Launcher theme';

  @override
  String get settings_misc_label => 'Miscellaneous';

  @override
  String get settings_console_switch => 'Show console on game start';

  @override
  String get settings_custom_folder_title => 'Custom game folder';

  @override
  String get settings_custom_folder => 'Game directory';

  @override
  String get settings_open_game_folder => 'Open game folder';

  @override
  String get settings_credits_title => 'Acknowledgments';

  @override
  String get settings_credits_content =>
      'This software has been developed using various open-source libraries: \n\nmaterial_color_utilities, flutter_localization, cached_network_image, simple_3d_renderer, shared_preferences, flutter_markdown, dropdown_button2, bitsdojo_window, flutter_switch, url_launcher, system_theme, flutter_html, text_divider, file_picker, process_run, file_selector, http_parser, provider, archive, encrypt, crypto, image, http, intl, blur, cupertino_icons. \n\nWe sincerely thank everyone who contributed to the development of these libraries, making the creation of this software possible.';

  @override
  String get settings_diagnostic_title => 'Diagnostic data';

  @override
  String get settings_diagnostic_copy => 'Copy log';

  @override
  String get settings_clear_cache => 'Clear skin caches';

  @override
  String get settings_force_classpath => 'Force classpath mode';

  @override
  String get settings_account_label => 'Account management';

  @override
  String get settings_account_import => 'Import';

  @override
  String get settings_account_export => 'Export';

  @override
  String get account_skin_buy_game => 'buy minecraft';

  @override
  String get account_skin_error_msg =>
      'Only premium accounts can change skin.\nConsider buying minecraft java edition at minecraft.net';

  @override
  String get account_empty_msg =>
      'Before you can play minecraft, you should add an SP or Premium account';

  @override
  String get account_add_button => 'Add account';

  @override
  String get account_add_type => 'What type of account do you want to add?';

  @override
  String get account_add_premium => 'Link a Premium account';

  @override
  String get account_add_offline => 'Add an SP account';

  @override
  String get account_add_link1 => 'Please open in your browser';

  @override
  String get account_add_link2 => 'And enter this code';

  @override
  String get account_add_copy => 'Open link and copy the code';

  @override
  String get account_add_fail => 'Could not open';

  @override
  String get account_remove_error => 'you can\'t remove an inexistent item :P';

  @override
  String get account_required_title => 'Minecraft account required';

  @override
  String get account_required_msg =>
      'Please add an SP or Premium account before launching the game';

  @override
  String get account_token_refresh => 'Refreshing microsoft account token';

  @override
  String get account_token_fail => 'Unable to refresh microsoft account token';

  @override
  String get account_post_fail => 'Error while running post request';

  @override
  String get account_get_fail => 'Error while running get request';

  @override
  String get account_skin_uploader_type_title => 'Choose Skin Type';

  @override
  String get account_skin_uploader_title => 'Skin uploader';

  @override
  String get account_skin_uploader_msg =>
      'classic (like Steve), slim (like Alex)';

  @override
  String get account_skin_success => 'Skin Succesfully changed!';

  @override
  String get account_skin_file_fail => 'File not found at';

  @override
  String get account_xsts_2148916233_fail =>
      'The account doesn\'t have an Xbox account.';

  @override
  String get account_xsts_2148916235_fail =>
      'The account is from a country where Xbox Live is not available/banned';

  @override
  String get account_xsts_2148916237_fail =>
      'The account needs adult verification on Xbox page. (South Korea)';

  @override
  String get account_xsts_2148916238_fail =>
      'The account is a child (under 18) and cannot proceed unless the account is added to a Family by an adult.';

  @override
  String get console_game_kill_msg => 'Killed minecraft process';

  @override
  String get console_clear_msg => 'Cleared console log';

  @override
  String get console_exit_title => 'Console exit confirmation';

  @override
  String get console_exit_msg1 => 'Are you sure you want to close console?';

  @override
  String get console_exit_msg2 =>
      'if you close the console you can\'t read what the game does anymore';

  @override
  String get console_exit_kill => 'Kill game and Exit';

  @override
  String get console_exit_only => 'Exit';

  @override
  String get console_crash_msg =>
      'Seems that minecraft has crashed! do you want to analyze the crashlog?';
}
