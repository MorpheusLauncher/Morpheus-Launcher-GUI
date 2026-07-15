// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get generic_error_msg => 'Ein Fehler ist aufgetreten';

  @override
  String get generic_cancel => 'Abbrechen';

  @override
  String get home_favourite_title => 'Favorisierte Versionen';

  @override
  String get home_news_title => 'Änderungsprotokoll';

  @override
  String get home_news_empty_msg =>
      'Kann das Minecraft-Änderungsprotokoll von Mojang nicht abrufen. Bitte erlauben Sie diesem Programm den Zugriff durch Ihre Firewall';

  @override
  String get morpheus_products_empty =>
      'Produkte von morpheus konnten nicht abgerufen werden';

  @override
  String get vanilla_empty_title =>
      'Keine Vanilla-Minecraft-Versionen gefunden';

  @override
  String get vanilla_release_title => 'Neueste Version';

  @override
  String get vanilla_snapshot_title => 'Neueste Snapshot-Version';

  @override
  String get modded_empty_title =>
      'Keine modifizierten Minecraft-Versionen gefunden';

  @override
  String get modded_installed_title => 'Installiert';

  @override
  String get modded_available_versions_title =>
      'Verfügbare modifizierte Versionen';

  @override
  String get modded_modrinth_button => 'Modpacks auf Modrinth';

  @override
  String get modded_modrinth_title => 'Modrinth Modpacks';

  @override
  String get modded_modrinth_search => 'Modpacks suchen...';

  @override
  String get modded_modrinth_section_title => 'Modpacks';

  @override
  String get modded_modrinth_empty => 'Keine Modpacks gefunden';

  @override
  String get modpack_details_title => 'Modpack-Details';

  @override
  String modpack_author_by(String author) {
    return 'von $author';
  }

  @override
  String get modpack_stats_downloads => 'Downloads';

  @override
  String get modpack_stats_updated => 'Aktualisiert';

  @override
  String get modpack_stats_size => 'Größe';

  @override
  String get modpack_download_button => 'Herunterladen';

  @override
  String get modpack_description_title => 'Beschreibung';

  @override
  String get modpack_mod_list_title => 'Mod-Liste';

  @override
  String get modpack_unknown_author => 'Unbekannter Autor';

  @override
  String get modpack_unknown_mod => 'Unbekannte Mod';

  @override
  String get settings_only_release_switch => 'Nur Veröffentlichungen anzeigen';

  @override
  String get settings_dark_mode_switch => 'Dunkles Thema aktivieren';

  @override
  String get settings_follow_system_color => 'Detailfarbe';

  @override
  String get settings_check_java_title => 'Funktioniert Java?';

  @override
  String get settings_check_java_yes => 'Ja, Ihr Java funktioniert';

  @override
  String get settings_check_java_no =>
      'Nein, wählen Sie bitte die richtige Java-Datei für Ihr Betriebssystem aus';

  @override
  String get settings_java_path_msg => 'Pfad zur Java-Ausführbaren Datei';

  @override
  String get settings_java_ram_msg => 'Maximale RAM-Zuweisung für Java';

  @override
  String get settings_java_advanced_settings => 'Erweiterte Java-Einstellungen';

  @override
  String get settings_appearance_label => 'Erscheinungsbild';

  @override
  String get settings_theme => 'Launcher-Thema';

  @override
  String get settings_misc_label => 'Verschiedenes';

  @override
  String get settings_console_switch => 'Konsole beim Spielstart anzeigen';

  @override
  String get settings_custom_folder_title => 'Benutzerdefinierter Spieleordner';

  @override
  String get settings_custom_folder => 'Spielverzeichnis';

  @override
  String get settings_open_game_folder => 'Spielordner öffnen';

  @override
  String get settings_credits_title => 'Danksagungen';

  @override
  String get settings_credits_content =>
      'Diese Software wurde unter Verwendung verschiedener Open-Source-Bibliotheken entwickelt: \n\nmaterial_color_utilities, flutter_localization, cached_network_image, simple_3d_renderer, shared_preferences, flutter_markdown, dropdown_button2, bitsdojo_window, flutter_switch, url_launcher, system_theme, flutter_html, text_divider, file_picker, process_run, file_selector, http_parser, provider, archive, encrypt, crypto, image, http, intl, blur, cupertino_icons. \n\nWir danken allen herzlich, die zu der Entwicklung dieser Bibliotheken beigetragen haben und damit die Realisierung dieser Software ermöglicht haben.';

  @override
  String get settings_diagnostic_title => 'Diagnosedaten';

  @override
  String get settings_diagnostic_copy => 'Protokoll kopieren';

  @override
  String get settings_clear_cache => 'Skin-Caches leeren';

  @override
  String get settings_force_classpath =>
      'Erzwinge die Verwendung des Classpath';

  @override
  String get settings_account_label => 'Kontoverwaltung';

  @override
  String get settings_account_import => 'Importieren';

  @override
  String get settings_account_export => 'Exportieren';

  @override
  String get account_skin_buy_game => 'Minecraft kaufen';

  @override
  String get account_skin_error_msg =>
      'Nur Premium-Konten können den Skin ändern. Erwägen Sie den Kauf von Minecraft Java Edition auf minecraft.net';

  @override
  String get account_empty_msg =>
      'Bevor Sie Minecraft spielen können, sollten Sie ein SP- oder Premium-Konto hinzufügen';

  @override
  String get account_add_button => 'Konto hinzufügen';

  @override
  String get account_add_type => 'Welchen Kontotyp möchten Sie hinzufügen?';

  @override
  String get account_add_premium => 'Verbinde einen Premium-Account';

  @override
  String get account_add_offline => 'Füge ein SP-Konto hinzu';

  @override
  String get account_add_link1 => 'Bitte öffnen Sie in Ihrem Browser';

  @override
  String get account_add_link2 => 'Und geben Sie diesen Code ein';

  @override
  String get account_add_copy => 'Link öffnen und Code kopieren';

  @override
  String get account_add_fail => 'Konnte nicht geöffnet werden';

  @override
  String get account_remove_error =>
      'Sie können keinen nicht vorhandenen Gegenstand entfernen :P';

  @override
  String get account_required_title => 'Minecraft-Konto erforderlich';

  @override
  String get account_required_msg =>
      'Bitte fügen Sie ein SP- oder Premium-Konto hinzu, bevor Sie das Spiel starten';

  @override
  String get account_token_refresh => 'Aktualisiere Microsoft-Konto-Token';

  @override
  String get account_token_fail =>
      'Konnte Microsoft-Konto-Token nicht aktualisieren';

  @override
  String get account_post_fail => 'Fehler beim Ausführen der POST-Anfrage';

  @override
  String get account_get_fail => 'Fehler beim Ausführen der GET-Anfrage';

  @override
  String get account_skin_uploader_type_title => 'Skin-Typ auswählen';

  @override
  String get account_skin_uploader_title => 'Skin-Uploader';

  @override
  String get account_skin_uploader_msg =>
      'Klassisch (wie Steve), schlank (wie Alex)';

  @override
  String get account_skin_success => 'Skin erfolgreich geändert!';

  @override
  String get account_skin_file_fail => 'Datei nicht gefunden unter';

  @override
  String get account_xsts_2148916233_fail => 'Das Konto hat kein Xbox-Konto.';

  @override
  String get account_xsts_2148916235_fail =>
      'Das Konto stammt aus einem Land, in dem Xbox Live nicht verfügbar/verboten ist';

  @override
  String get account_xsts_2148916237_fail =>
      'Das Konto benötigt eine Altersverifikation auf der Xbox-Seite. (Südkorea)';

  @override
  String get account_xsts_2148916238_fail =>
      'Das Konto ist ein Kind (unter 18) und kann nur fortgesetzt werden, wenn das Konto von einem Erwachsenen zu einer Familie hinzugefügt wird.';

  @override
  String get console_game_kill_msg => 'Minecraft-Prozess beendet';

  @override
  String get console_clear_msg => 'Konsole gelöscht';

  @override
  String get console_exit_title => 'Bestätigung zum Verlassen der Konsole';

  @override
  String get console_exit_msg1 =>
      'Sind Sie sicher, dass Sie die Konsole schließen möchten?';

  @override
  String get console_exit_msg2 =>
      'Wenn Sie die Konsole schließen, können Sie nicht mehr lesen, was das Spiel tut';

  @override
  String get console_exit_kill => 'Spiel beenden und verlassen';

  @override
  String get console_exit_only => 'Verlassen';

  @override
  String get console_crash_msg =>
      'Es scheint, dass Minecraft abgestürzt ist! Möchtest du das Absturzprotokoll analysieren?';
}
