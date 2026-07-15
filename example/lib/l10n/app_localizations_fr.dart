// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get generic_error_msg => 'Une erreur s\'est produite';

  @override
  String get generic_cancel => 'Annuler';

  @override
  String get home_favourite_title => 'Versions épinglées';

  @override
  String get home_news_title => 'Journal des modifications';

  @override
  String get home_news_empty_msg =>
      'Impossible de récupérer le journal des modifications de Minecraft depuis Mojang. Veuillez autoriser ce programme via votre pare-feu';

  @override
  String get morpheus_products_empty =>
      'Impossible de récupérer les produits morpheus';

  @override
  String get vanilla_empty_title =>
      'Aucune version de Minecraft Vanilla trouvée';

  @override
  String get vanilla_release_title => 'Dernière version';

  @override
  String get vanilla_snapshot_title => 'Dernier snapshot';

  @override
  String get modded_empty_title =>
      'Aucune version modifiée de Minecraft trouvée';

  @override
  String get modded_installed_title => 'Installées';

  @override
  String get modded_available_versions_title =>
      'Versions modifiées disponibles';

  @override
  String get modded_modrinth_button => 'Modpacks sur Modrinth';

  @override
  String get modded_modrinth_title => 'Modpacks Modrinth';

  @override
  String get modded_modrinth_search => 'Rechercher des modpacks...';

  @override
  String get modded_modrinth_section_title => 'Modpacks';

  @override
  String get modded_modrinth_empty => 'Aucun modpack trouvé';

  @override
  String get modpack_details_title => 'Détails du Modpack';

  @override
  String modpack_author_by(String author) {
    return 'par $author';
  }

  @override
  String get modpack_stats_downloads => 'Téléchargements';

  @override
  String get modpack_stats_updated => 'Mis à jour';

  @override
  String get modpack_stats_size => 'Taille';

  @override
  String get modpack_download_button => 'Télécharger';

  @override
  String get modpack_description_title => 'Description';

  @override
  String get modpack_mod_list_title => 'Liste des mods';

  @override
  String get modpack_unknown_author => 'Auteur inconnu';

  @override
  String get modpack_unknown_mod => 'Mod inconnue';

  @override
  String get settings_only_release_switch =>
      'Afficher uniquement les versions stables';

  @override
  String get settings_dark_mode_switch => 'Activer le thème sombre';

  @override
  String get settings_follow_system_color => 'Couleur des détails';

  @override
  String get settings_check_java_title => 'Java fonctionne-t-il ?';

  @override
  String get settings_check_java_yes => 'Oui, votre Java fonctionne';

  @override
  String get settings_check_java_no =>
      'Non, veuillez sélectionner le fichier exécutable Java correct pour votre système d\'exploitation';

  @override
  String get settings_java_path_msg => 'Chemin vers le fichier exécutable Java';

  @override
  String get settings_java_ram_msg => 'Allocation maximale de RAM pour Java';

  @override
  String get settings_java_advanced_settings => 'Paramètres avancés de Java';

  @override
  String get settings_appearance_label => 'Apparence';

  @override
  String get settings_theme => 'Thème du lanceur';

  @override
  String get settings_misc_label => 'Divers';

  @override
  String get settings_console_switch =>
      'Afficher la console au démarrage du jeu';

  @override
  String get settings_custom_folder_title => 'Dossier de jeu personnalisé';

  @override
  String get settings_custom_folder => 'Répertoire du jeu';

  @override
  String get settings_open_game_folder => 'Ouvrir le dossier du jeu';

  @override
  String get settings_credits_title => 'Remerciements';

  @override
  String get settings_credits_content =>
      'Ce logiciel a été développé en utilisant diverses bibliothèques open source: \n\nmaterial_color_utilities, flutter_localization, cached_network_image, simple_3d_renderer, shared_preferences, flutter_markdown, dropdown_button2, bitsdojo_window, flutter_switch, url_launcher, system_theme, flutter_html, text_divider, file_picker, process_run, file_selector, http_parser, provider, archive, encrypt, crypto, image, http, intl, blur, cupertino_icons. \n\nNous remercions sincèrement tous ceux qui ont contribué au développement de ces bibliothèques, rendant possible la création de ce logiciel.';

  @override
  String get settings_diagnostic_title => 'Données de diagnostic';

  @override
  String get settings_diagnostic_copy => 'Copier le journal';

  @override
  String get settings_clear_cache => 'Effacer les caches de skins';

  @override
  String get settings_force_classpath => 'Forcer l\'utilisation du classpath';

  @override
  String get settings_account_label => 'Gestion du compte';

  @override
  String get settings_account_import => 'Importer';

  @override
  String get settings_account_export => 'Exporter';

  @override
  String get account_skin_buy_game => 'acheter Minecraft';

  @override
  String get account_skin_error_msg =>
      'Seuls les comptes premium peuvent changer de skin. Pensez à acheter Minecraft Java Edition sur minecraft.net';

  @override
  String get account_empty_msg =>
      'Avant de jouer à Minecraft, vous devez ajouter un compte SP ou Premium';

  @override
  String get account_add_button => 'Ajouter un compte';

  @override
  String get account_add_type => 'Quel type de compte souhaitez-vous ajouter ?';

  @override
  String get account_add_premium => 'Connectez un compte Premium';

  @override
  String get account_add_offline => 'Ajouter un compte SP';

  @override
  String get account_add_link1 => 'Veuillez ouvrir dans votre navigateur';

  @override
  String get account_add_link2 => 'Et entrez ce code';

  @override
  String get account_add_copy => 'Ouvrez le lien et copiez le code';

  @override
  String get account_add_fail => 'Impossible d\'ouvrir';

  @override
  String get account_remove_error =>
      'Vous ne pouvez pas supprimer un élément inexistant :P';

  @override
  String get account_required_title => 'Compte Minecraft requis';

  @override
  String get account_required_msg =>
      'Veuillez ajouter un compte SP ou Premium avant de lancer le jeu';

  @override
  String get account_token_refresh =>
      'Actualisation du jeton du compte Microsoft';

  @override
  String get account_token_fail =>
      'Impossible d\'actualiser le jeton du compte Microsoft';

  @override
  String get account_post_fail =>
      'Erreur lors de l\'exécution de la requête POST';

  @override
  String get account_get_fail =>
      'Erreur lors de l\'exécution de la requête GET';

  @override
  String get account_skin_uploader_type_title => 'Choisissez le type de skin';

  @override
  String get account_skin_uploader_title => 'Uploader de skin';

  @override
  String get account_skin_uploader_msg =>
      'classique (comme Steve), fin (comme Alex)';

  @override
  String get account_skin_success => 'Changement de skin réussi !';

  @override
  String get account_skin_file_fail => 'Fichier introuvable à';

  @override
  String get account_xsts_2148916233_fail =>
      'Le compte n\'a pas de compte Xbox.';

  @override
  String get account_xsts_2148916235_fail =>
      'Le compte provient d\'un pays où Xbox Live n\'est pas disponible/interdit';

  @override
  String get account_xsts_2148916237_fail =>
      'Le compte nécessite une vérification adulte sur la page Xbox (Corée du Sud)';

  @override
  String get account_xsts_2148916238_fail =>
      'Le compte est un enfant (moins de 18 ans) et ne peut pas continuer à moins que le compte ne soit ajouté à une famille par un adulte.';

  @override
  String get console_game_kill_msg => 'Processus Minecraft arrêté';

  @override
  String get console_clear_msg => 'Journal de console effacé';

  @override
  String get console_exit_title => 'Confirmation de sortie de la console';

  @override
  String get console_exit_msg1 =>
      'Êtes-vous sûr de vouloir fermer la console ?';

  @override
  String get console_exit_msg2 =>
      'Si vous fermez la console, vous ne pourrez plus lire ce que le jeu fait';

  @override
  String get console_exit_kill => 'Arrêter le jeu et quitter';

  @override
  String get console_exit_only => 'Quitter';

  @override
  String get console_crash_msg =>
      'Il semble que Minecraft ait planté! Voulez-vous analyser le journal de crash?';
}
