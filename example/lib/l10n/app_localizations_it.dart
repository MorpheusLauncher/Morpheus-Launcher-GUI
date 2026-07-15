// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get generic_error_msg => 'Si è verificato un errore';

  @override
  String get generic_cancel => 'Annulla';

  @override
  String get home_favourite_title => 'Versioni Preferite';

  @override
  String get home_news_title => 'Changelog';

  @override
  String get home_news_empty_msg =>
      'Impossibile recuperare il changelog da mojang, perfavore consenti questo programma nel tuo firewall';

  @override
  String get morpheus_products_empty =>
      'Impossibile recuperare i prodotti morpheus';

  @override
  String get vanilla_empty_title => 'Nessuna versione vanilla trovata';

  @override
  String get vanilla_release_title => 'Ultima release';

  @override
  String get vanilla_snapshot_title => 'Ultimo snapshot';

  @override
  String get modded_empty_title => 'Nessuna versione moddata trovata';

  @override
  String get modded_installed_title => 'Installate';

  @override
  String get modded_available_versions_title => 'Versioni moddate disponibili';

  @override
  String get modded_modrinth_button => 'Modpacks su Modrinth';

  @override
  String get modded_modrinth_title => 'Modpacks di Modrinth';

  @override
  String get modded_modrinth_search => 'Cerca modpack...';

  @override
  String get modded_modrinth_section_title => 'Modpack';

  @override
  String get modded_modrinth_empty => 'Nessun modpack trovato';

  @override
  String get modpack_details_title => 'Dettagli Modpack';

  @override
  String modpack_author_by(String author) {
    return 'di $author';
  }

  @override
  String get modpack_stats_downloads => 'Download';

  @override
  String get modpack_stats_updated => 'Aggiornato';

  @override
  String get modpack_stats_size => 'Dimensione';

  @override
  String get modpack_download_button => 'Scarica';

  @override
  String get modpack_description_title => 'Descrizione';

  @override
  String get modpack_mod_list_title => 'Lista mod';

  @override
  String get modpack_unknown_author => 'Autore sconosciuto';

  @override
  String get modpack_unknown_mod => 'Mod sconosciuta';

  @override
  String get settings_only_release_switch => 'Mostra solo release';

  @override
  String get settings_dark_mode_switch => 'Usa tema scuro';

  @override
  String get settings_follow_system_color => 'Colore dettagli';

  @override
  String get settings_check_java_title => 'Il tuo java funziona?';

  @override
  String get settings_check_java_yes => 'Sì, il tuo java funziona';

  @override
  String get settings_check_java_no =>
      'No. perfavore seleziona il java adeguato per il tuo sistema';

  @override
  String get settings_java_path_msg => 'Percorso dell\' eseguibile Java';

  @override
  String get settings_java_ram_msg => 'Ram massima che java può usare';

  @override
  String get settings_java_advanced_settings => 'Impostazioni java avanzate';

  @override
  String get settings_appearance_label => 'Aspetto';

  @override
  String get settings_theme => 'Tema del launcher';

  @override
  String get settings_misc_label => 'Varie';

  @override
  String get settings_console_switch =>
      'Mostra la console all\'avvio del gioco';

  @override
  String get settings_custom_folder_title => 'Cartella di gioco personalizzata';

  @override
  String get settings_custom_folder => 'Cartella del gioco';

  @override
  String get settings_open_game_folder => 'Apri cartella di gioco';

  @override
  String get settings_credits_title => 'Ringraziamenti';

  @override
  String get settings_credits_content =>
      'Questo software è stato sviluppato utilizzando diverse librerie open source: \n\nmaterial_color_utilities, flutter_localization, cached_network_image, simple_3d_renderer, shared_preferences, flutter_markdown, dropdown_button2, bitsdojo_window, flutter_switch, url_launcher, system_theme, flutter_html, text_divider, file_picker, process_run, file_selector, http_parser, provider, archive, encrypt, crypto, image, http, intl, blur, cupertino_icons. \n\nRingraziamo sinceramente tutti coloro che hanno contribuito allo sviluppo di queste librerie, rendendo possibile la realizzazione di questo software.';

  @override
  String get settings_diagnostic_title => 'Dati diagnostici';

  @override
  String get settings_diagnostic_copy => 'Copia log';

  @override
  String get settings_clear_cache => 'Pulisci cache delle skin';

  @override
  String get settings_force_classpath => 'Forza l\'utilizzo di classpath';

  @override
  String get settings_account_label => 'Gestione account';

  @override
  String get settings_account_import => 'Importa';

  @override
  String get settings_account_export => 'Esporta';

  @override
  String get account_skin_buy_game => 'Acquista Minecraft';

  @override
  String get account_skin_error_msg =>
      'Solo gli account premium possono cambiare la skin.\nConsidera di comprare il gioco tramite minecraft.net';

  @override
  String get account_empty_msg =>
      'Prima di poter giocare a minecraft, devi aggiungere un account SP o Premium';

  @override
  String get account_add_button => 'Aggiungi account';

  @override
  String get account_add_type => 'Che tipo di account vuoi aggiungere?';

  @override
  String get account_add_premium => 'Collega un account Premium';

  @override
  String get account_add_offline => 'Aggiungi un account SP';

  @override
  String get account_add_link1 => 'Perfavore apri questo nel tuo browser';

  @override
  String get account_add_link2 =>
      'E incolla questo codice, in alternativa usa il bottone sottostante.';

  @override
  String get account_add_copy => 'Apri il link e copia il codice';

  @override
  String get account_add_fail => 'Impossibile aprire';

  @override
  String get account_remove_error =>
      'non puoi rimuovere un elemento non esistente :P';

  @override
  String get account_required_title => 'Account minecraft richiesto';

  @override
  String get account_required_msg =>
      'Aggiungi un account SP o Premium prima di avviare il gioco';

  @override
  String get account_token_refresh => 'Rinfrescamento del token minecraft';

  @override
  String get account_token_fail =>
      'Impossibile rinfrescare il token dell\'account microsoft';

  @override
  String get account_post_fail =>
      'Si è verificato un errore durante la richiesta POST';

  @override
  String get account_get_fail =>
      'Si è verificato un errore durante la richiesta GET';

  @override
  String get account_skin_uploader_type_title =>
      'Seleziona tipologia della skin';

  @override
  String get account_skin_uploader_title => 'Skin uploader';

  @override
  String get account_skin_uploader_msg =>
      'classica (come Steve), slim (come Alex)';

  @override
  String get account_skin_success => 'La skin è stata aggiornata!';

  @override
  String get account_skin_file_fail => 'File non trovato in';

  @override
  String get account_xsts_2148916233_fail =>
      'L\'account non ha un profilo Xbox.';

  @override
  String get account_xsts_2148916235_fail =>
      'L\'account proviende a un paese in cui non è disponibile o bannato';

  @override
  String get account_xsts_2148916237_fail =>
      'L\'account richiede la verifica di un adulto nella pagina Xbox. (Corea del sud)';

  @override
  String get account_xsts_2148916238_fail =>
      'L\'account è minorenne e non può procedere a meno che un adulto lo aggiunge alla famiglia.';

  @override
  String get console_game_kill_msg => 'Processo chiuso forzatamente';

  @override
  String get console_clear_msg => 'Console dei log pulita';

  @override
  String get console_exit_title => 'Conferma chiusura console';

  @override
  String get console_exit_msg1 => 'Sei sicuro di voler chiudere la console?';

  @override
  String get console_exit_msg2 =>
      'se lo farai non potrai più capire cosa sta facendo il gioco!';

  @override
  String get console_exit_kill => 'Termina il gioco e Chiudi';

  @override
  String get console_exit_only => 'Chiudi';

  @override
  String get console_crash_msg =>
      'Sembra che Minecraft sia andato in crash! Vuoi analizzare i crashlog?';
}
