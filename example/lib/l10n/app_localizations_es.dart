// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get generic_error_msg => 'Se ha producido un error';

  @override
  String get generic_cancel => 'Cancelar';

  @override
  String get home_favourite_title => 'Versiones Favoritas';

  @override
  String get home_news_title => 'Registro de cambios';

  @override
  String get home_news_empty_msg =>
      'No se puede recuperar el registro de cambios de Mojang, por favor permite este programa en tu firewall';

  @override
  String get morpheus_products_empty =>
      'No se pueden recuperar los productos morpheus';

  @override
  String get vanilla_empty_title => 'No se encontró ninguna versión Vanilla';

  @override
  String get vanilla_release_title => 'Última versión';

  @override
  String get vanilla_snapshot_title => 'Último snapshot';

  @override
  String get modded_empty_title => 'No se encontró ninguna versión modificada';

  @override
  String get modded_installed_title => 'Instaladas';

  @override
  String get modded_available_versions_title =>
      'Versiones modificadas disponibles';

  @override
  String get modded_modrinth_button => 'Modpacks en Modrinth';

  @override
  String get modded_modrinth_title => 'Modpacks de Modrinth';

  @override
  String get modded_modrinth_search => 'Buscar modpacks...';

  @override
  String get modded_modrinth_section_title => 'Modpacks';

  @override
  String get modded_modrinth_empty => 'No se trovaron modpacks';

  @override
  String get modpack_details_title => 'Detalles del Modpack';

  @override
  String modpack_author_by(String author) {
    return 'por $author';
  }

  @override
  String get modpack_stats_downloads => 'Descargas';

  @override
  String get modpack_stats_updated => 'Actualizado';

  @override
  String get modpack_stats_size => 'Tamaño';

  @override
  String get modpack_download_button => 'Descargar';

  @override
  String get modpack_description_title => 'Descripción';

  @override
  String get modpack_mod_list_title => 'Lista de mods';

  @override
  String get modpack_unknown_author => 'Autor desconocido';

  @override
  String get modpack_unknown_mod => 'Mod desconocida';

  @override
  String get settings_only_release_switch => 'Mostrar solo versiones estables';

  @override
  String get settings_dark_mode_switch => 'Usar modo oscuro';

  @override
  String get settings_follow_system_color => 'Color de detalles';

  @override
  String get settings_check_java_title => '¿Funciona tu Java?';

  @override
  String get settings_check_java_yes => 'Sí, tu Java funciona';

  @override
  String get settings_check_java_no =>
      'No. Por favor, selecciona el Java adecuado para tu sistema';

  @override
  String get settings_java_path_msg => 'Ruta del ejecutable de Java';

  @override
  String get settings_java_ram_msg => 'RAM máxima que puede usar Java';

  @override
  String get settings_java_advanced_settings =>
      'Configuración avanzada de Java';

  @override
  String get settings_appearance_label => 'Apariencia';

  @override
  String get settings_theme => 'Tema del lanzador';

  @override
  String get settings_misc_label => 'Varios';

  @override
  String get settings_console_switch =>
      'Mostrar la consola al iniciar el juego';

  @override
  String get settings_custom_folder_title => 'Carpeta de juego personalizada';

  @override
  String get settings_custom_folder => 'Directorio del juego';

  @override
  String get settings_open_game_folder => 'Abrir carpeta del juego';

  @override
  String get settings_credits_title => 'Agradecimientos';

  @override
  String get settings_credits_content =>
      'Este software ha sido desarrollado utilizando diversas bibliotecas de código abierto: \n\nmaterial_color_utilities, flutter_localization, cached_network_image, simple_3d_renderer, shared_preferences, flutter_markdown, dropdown_button2, bitsdojo_window, flutter_switch, url_launcher, system_theme, flutter_html, text_divider, file_picker, process_run, file_selector, http_parser, provider, archive, encrypt, crypto, image, http, intl, blur, cupertino_icons. \n\nAgradecemos sinceramente a todos los que contribuyeron al desarrollo de estas bibliotecas, haciendo posible la creación de este software.';

  @override
  String get settings_diagnostic_title => 'Datos de diagnóstico';

  @override
  String get settings_diagnostic_copy => 'Copiar registro';

  @override
  String get settings_clear_cache => 'Borrar cachés de skins';

  @override
  String get settings_force_classpath => 'Forzar el uso de classpath';

  @override
  String get settings_account_label => 'Gestión de la cuenta';

  @override
  String get settings_account_import => 'Importar';

  @override
  String get settings_account_export => 'Exportar';

  @override
  String get account_skin_buy_game => 'Comprar Minecraft';

  @override
  String get account_skin_error_msg =>
      'Solo las cuentas premium pueden cambiar la skin.\nConsidera comprar el juego a través de minecraft.net';

  @override
  String get account_empty_msg =>
      'Antes de poder jugar a Minecraft, debes agregar una cuenta de un solo jugador o premium';

  @override
  String get account_add_button => 'Agregar cuenta';

  @override
  String get account_add_type => '¿Qué tipo de cuenta quieres agregar?';

  @override
  String get account_add_premium => 'Conecta una cuenta Premium';

  @override
  String get account_add_offline => 'Agregar una cuenta SP';

  @override
  String get account_add_link1 => 'Por favor, abre esto en tu navegador';

  @override
  String get account_add_link2 =>
      'Y pega este código, o utiliza el botón de abajo.';

  @override
  String get account_add_copy => 'Abre el enlace y copia el código';

  @override
  String get account_add_fail => 'No se pudo abrir';

  @override
  String get account_remove_error =>
      'No puedes eliminar un elemento que no existe :P';

  @override
  String get account_required_title => 'Se requiere cuenta de Minecraft';

  @override
  String get account_required_msg =>
      'Agrega una cuenta de un solo jugador o premium antes de iniciar el juego';

  @override
  String get account_token_refresh => 'Actualización del token de Minecraft';

  @override
  String get account_token_fail =>
      'No se pudo actualizar el token de la cuenta de Microsoft';

  @override
  String get account_post_fail =>
      'Se produjo un error durante la solicitud POST';

  @override
  String get account_get_fail => 'Se produjo un error durante la solicitud GET';

  @override
  String get account_skin_uploader_type_title => 'Selecciona el tipo de piel';

  @override
  String get account_skin_uploader_title => 'Subir piel';

  @override
  String get account_skin_uploader_msg =>
      'clásica (como Steve), delgada (como Alex)';

  @override
  String get account_skin_success => '¡La piel se ha actualizado!';

  @override
  String get account_skin_file_fail => 'Archivo no encontrado en';

  @override
  String get account_xsts_2148916233_fail =>
      'La cuenta no tiene un perfil de Xbox.';

  @override
  String get account_xsts_2148916235_fail =>
      'La cuenta proviene de un país donde no está disponible o está prohibida';

  @override
  String get account_xsts_2148916237_fail =>
      'La cuenta requiere la verificación de un adulto en la página de Xbox. (Corea del sur)';

  @override
  String get account_xsts_2148916238_fail =>
      'La cuenta es menor de edad y no puede proceder a menos que un adulto la agregue a la familia.';

  @override
  String get console_game_kill_msg => 'Proceso cerrado forzosamente';

  @override
  String get console_clear_msg => 'Consola de registros limpia';

  @override
  String get console_exit_title => 'Confirmar cierre de consola';

  @override
  String get console_exit_msg1 =>
      '¿Estás seguro de que quieres cerrar la consola?';

  @override
  String get console_exit_msg2 =>
      'Si lo haces, ¡no podrás entender lo que está haciendo el juego!';

  @override
  String get console_exit_kill => 'Terminar el juego y cerrar';

  @override
  String get console_exit_only => 'Cerrar';

  @override
  String get console_crash_msg =>
      '¡Parece que Minecraft se ha bloqueado! ¿Quieres analizar el registro de fallos?';
}
