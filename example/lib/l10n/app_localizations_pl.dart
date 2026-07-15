// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get generic_error_msg => 'Wystąpił błąd';

  @override
  String get generic_cancel => 'Anuluj';

  @override
  String get home_favourite_title => 'Ulubione wersje';

  @override
  String get home_news_title => 'Dziennik zmian';

  @override
  String get home_news_empty_msg =>
      'Nie można pobrać dziennika zmian Minecrafta od Mojangu. Proszę zezwolić na dostęp temu programowi przez zaporę ogniową';

  @override
  String get morpheus_products_empty => 'Nie można pobrać produktów morpheus';

  @override
  String get vanilla_empty_title => 'Nie znaleziono wersji Vanilla Minecrafta';

  @override
  String get vanilla_release_title => 'Najnowsza wersja';

  @override
  String get vanilla_snapshot_title => 'Najnowsza wersja snapshot';

  @override
  String get modded_empty_title =>
      'Nie znaleziono zmodowanych wersji Minecrafta';

  @override
  String get modded_installed_title => 'Zainstalowane';

  @override
  String get modded_available_versions_title => 'Dostępne zmodyfikowane wersje';

  @override
  String get modded_modrinth_button => 'Paczki modów na Modrinth';

  @override
  String get modded_modrinth_title => 'Paczki modów Modrinth';

  @override
  String get modded_modrinth_search => 'Szukaj paczek modów...';

  @override
  String get modded_modrinth_section_title => 'Paczki modów';

  @override
  String get modded_modrinth_empty => 'Nie znaleziono paczek modów';

  @override
  String get modpack_details_title => 'Szczegóły paczki modów';

  @override
  String modpack_author_by(String author) {
    return 'przez $author';
  }

  @override
  String get modpack_stats_downloads => 'Pobierania';

  @override
  String get modpack_stats_updated => 'Zaktualizowano';

  @override
  String get modpack_stats_size => 'Rozmiar';

  @override
  String get modpack_download_button => 'Pobierz';

  @override
  String get modpack_description_title => 'Opis';

  @override
  String get modpack_mod_list_title => 'Lista modów';

  @override
  String get modpack_unknown_author => 'Nieznany autor';

  @override
  String get modpack_unknown_mod => 'Nieznana modyfikacja';

  @override
  String get settings_only_release_switch => 'Pokaż tylko wydania';

  @override
  String get settings_dark_mode_switch => 'Włącz ciemny motyw';

  @override
  String get settings_follow_system_color => 'Kolor szczegółów';

  @override
  String get settings_check_java_title => 'Czy Java działa?';

  @override
  String get settings_check_java_yes => 'Tak, twoja Java działa';

  @override
  String get settings_check_java_no =>
      'Nie, proszę wybrać poprawny plik wykonywalny Java dla twojego systemu operacyjnego';

  @override
  String get settings_java_path_msg => 'Ścieżka do pliku wykonywalnego Java';

  @override
  String get settings_java_ram_msg => 'Maksymalna alokacja RAM dla Java';

  @override
  String get settings_java_advanced_settings => 'Zaawansowane ustawienia Java';

  @override
  String get settings_appearance_label => 'Wygląd';

  @override
  String get settings_theme => 'Motyw launchera';

  @override
  String get settings_misc_label => 'Różne';

  @override
  String get settings_console_switch => 'Pokaż konsolę przy uruchamianiu gry';

  @override
  String get settings_custom_folder_title => 'Niestandardowy folder gry';

  @override
  String get settings_custom_folder => 'Katalog gry';

  @override
  String get settings_open_game_folder => 'Otwórz folder gry';

  @override
  String get settings_credits_title => 'Podziękowania';

  @override
  String get settings_credits_content =>
      'To oprogramowanie zostało opracowane przy użyciu różnych bibliotek open source: \n\nmaterial_color_utilities, flutter_localization, cached_network_image, simple_3d_renderer, shared_preferences, flutter_markdown, dropdown_button2, bitsdojo_window, flutter_switch, url_launcher, system_theme, flutter_html, text_divider, file_picker, process_run, file_selector, http_parser, provider, archive, encrypt, crypto, image, http, intl, blur, cupertino_icons. \n\nSzczerze dziękujemy wszystkim, którzy przyczynili się do rozwoju tych bibliotek, umożliwiając stworzenie tego oprogramowania.';

  @override
  String get settings_diagnostic_title => 'Dane diagnostyczne';

  @override
  String get settings_diagnostic_copy => 'Kopiuj log';

  @override
  String get settings_clear_cache => 'Wyczyść pamięć podręczną skórek';

  @override
  String get settings_force_classpath => 'Wymuś użycie classpath';

  @override
  String get settings_account_label => 'Zarządzanie kontem';

  @override
  String get settings_account_import => 'Importuj';

  @override
  String get settings_account_export => 'Eksportuj';

  @override
  String get account_skin_buy_game => 'kup Minecraft';

  @override
  String get account_skin_error_msg =>
      'Zmiana skórki możliwa tylko dla kont premium. Rozważ zakup Minecraft Java Edition na minecraft.net';

  @override
  String get account_empty_msg =>
      'Przed rozpoczęciem gry w Minecrafta należy dodać konto SP lub premium';

  @override
  String get account_add_button => 'Dodaj konto';

  @override
  String get account_add_type => 'Jaki rodzaj konta chcesz dodać?';

  @override
  String get account_add_premium => 'Połącz konto Premium';

  @override
  String get account_add_offline => 'Dodaj konto SP';

  @override
  String get account_add_link1 => 'Proszę otworzyć w przeglądarce';

  @override
  String get account_add_link2 => 'I wpisz ten kod';

  @override
  String get account_add_copy => 'Otwórz link i skopiuj kod';

  @override
  String get account_add_fail => 'Nie udało się otworzyć';

  @override
  String get account_remove_error =>
      'Nie możesz usunąć nieistniejącego elementu :P';

  @override
  String get account_required_title => 'Wymagane konto Minecraft';

  @override
  String get account_required_msg =>
      'Przed uruchomieniem gry dodaj konto SP lub premium';

  @override
  String get account_token_refresh => 'Odświeżanie tokena konta Microsoft';

  @override
  String get account_token_fail => 'Nie można odświeżyć tokena konta Microsoft';

  @override
  String get account_post_fail => 'Błąd podczas wykonywania żądania POST';

  @override
  String get account_get_fail => 'Błąd podczas wykonywania żądania GET';

  @override
  String get account_skin_uploader_type_title => 'Wybierz typ skórki';

  @override
  String get account_skin_uploader_title => 'Przesyłanie skórki';

  @override
  String get account_skin_uploader_msg =>
      'klasyczny (jak Steve), smukły (jak Alex)';

  @override
  String get account_skin_success => 'Zmiana skórki pomyślna!';

  @override
  String get account_skin_file_fail => 'Nie znaleziono pliku pod adresem';

  @override
  String get account_xsts_2148916233_fail => 'Konto nie ma konta Xbox.';

  @override
  String get account_xsts_2148916235_fail =>
      'Konto pochodzi z kraju, w którym Xbox Live nie jest dostępne/zakazane';

  @override
  String get account_xsts_2148916237_fail =>
      'Konto wymaga weryfikacji dorosłego na stronie Xbox (Korea Południowa)';

  @override
  String get account_xsts_2148916238_fail =>
      'Konto jest dzieckiem (poniżej 18 roku życia) i nie może kontynuować, chyba że zostanie dodane do rodziny przez dorosłego.';

  @override
  String get console_game_kill_msg => 'Zabity proces Minecrafta';

  @override
  String get console_clear_msg => 'Wyczyszczono dziennik konsoli';

  @override
  String get console_exit_title => 'Potwierdzenie zamykania konsoli';

  @override
  String get console_exit_msg1 => 'Czy na pewno chcesz zamknąć konsolę?';

  @override
  String get console_exit_msg2 =>
      'Jeśli zamkniesz konsolę, nie będziesz mógł czytać, co robi gra';

  @override
  String get console_exit_kill => 'Zabij grę i zamknij';

  @override
  String get console_exit_only => 'Zamknij';

  @override
  String get console_crash_msg =>
      'Wygląda na to, że Minecraft uległ awarii! Czy chcesz przeanalizować dziennik awarii?';
}
