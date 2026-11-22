// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get advanced => 'Avanzado';

  @override
  String get app_name => 'TeditoX';

  @override
  String get new_file => 'Archivo nuevo';

  @override
  String get open => 'Abrir';

  @override
  String get save => 'Guardar';

  @override
  String get save_as => 'Guardar como';

  @override
  String get settings => 'Configuración';

  @override
  String get recent_files => 'Recientes';

  @override
  String get modified => 'Modificado';

  @override
  String get saved => 'Guardado';

  @override
  String get encoding => 'Codificación';

  @override
  String get line_endings => 'Finales de línea';

  @override
  String get wrap_lines => 'Ajustar líneas';

  @override
  String get line_numbers => 'Números de línea';

  @override
  String get theme => 'Tema';

  @override
  String get font => 'Fuente';

  @override
  String get editor_font_size => 'Tamaño de fuente del editor';

  @override
  String get word_count => 'Conteo palabras/caracteres/líneas';

  @override
  String get clear => 'Limpiar';

  @override
  String get clear_recent_files => 'Limpiar Archivos Recientes';

  @override
  String get clear_recent_files_confirmation =>
      '¿Estás seguro de que quieres limpiar todos los archivos recientes? Esta acción no se puede deshacer.';

  @override
  String get restore => 'Restaurar';

  @override
  String get discard => 'Descartar';

  @override
  String get unsaved_recovery_found => 'Se encontró recuperación sin guardar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get unsaved_changes => 'Cambios sin guardar';

  @override
  String get unsaved_changes_message =>
      'Tiene cambios sin guardar. ¿Guardar antes de salir?';

  @override
  String get remove => 'Quitar';

  @override
  String get details => 'Detalles';

  @override
  String get last_opened => 'Última apertura';

  @override
  String get last_modified => 'Última modificación';

  @override
  String get size => 'Tamaño';

  @override
  String get yes => 'Sí';

  @override
  String get no => 'No';

  @override
  String get editor => 'Editor';

  @override
  String get about => 'Acerca de';

  @override
  String get undo_depth => 'Profundidad de deshacer';

  @override
  String get max_file_size => 'Máximo tamaño de archivo';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get system => 'Sistema';

  @override
  String get language => 'Idioma';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get more_actions => 'Más acciones';

  @override
  String get new_file_name => 'sinnombre.txt';

  @override
  String get file_operations => 'Operaciones de archivo';

  @override
  String get navigation => 'Navegación';

  @override
  String get version => 'Versión';

  @override
  String get license => 'Licencia';

  @override
  String get privacy_policy => 'Política de Privacidad';

  @override
  String get view_license => 'Ver Licencia';

  @override
  String get view_privacy_policy => 'Ver Política de Privacidad';

  @override
  String get app_description => 'Editor de texto plano simple';

  @override
  String get third_party_licenses => 'Licencias de terceros';

  @override
  String get view_third_party_licenses => 'Ver Licencias de Terceros';

  @override
  String could_not_launch_url(String url) {
    return 'No se pudo abrir $url';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String get redo => 'Rehacer';

  @override
  String get no_recent_files => 'No hay archivos recientes';

  @override
  String get open_file_error => 'Error abriendo archivo';

  @override
  String open_file_error_message(String path) {
    return 'Se produjo un error al intentar abrir el archivo en $path.';
  }

  @override
  String get ok => 'OK';

  @override
  String file_too_large(String limit) {
    return 'Este archivo supera el límite de $limit. Puedes aumentarlo en Ajustes.';
  }

  @override
  String file_not_found(String name) {
    return 'No se encontró $name. Se quitó de los archivos recientes.';
  }

  @override
  String file_unreadable(String name) {
    return 'No se pudo leer $name.';
  }

  @override
  String get file_unreadable_unknown => 'este archivo';

  @override
  String get reopen_with_encoding => 'Reabrir con codificación';

  @override
  String get restore_last_file => 'Reabrir el último archivo al iniciar';

  @override
  String get find => 'Buscar';

  @override
  String get find_hint => 'Buscar';

  @override
  String get find_next => 'Siguiente';

  @override
  String get find_previous => 'Anterior';

  @override
  String get find_match_case => 'Coincidir mayúsculas';

  @override
  String get find_whole_word => 'Palabra completa';

  @override
  String get find_no_matches => 'Sin coincidencias';

  @override
  String find_match_count(int current, int total) {
    return '$current/$total';
  }

  @override
  String get replace => 'Reemplazar';

  @override
  String get replace_hint => 'Reemplazar';

  @override
  String get replace_all => 'Reemplazar todo';

  @override
  String get close => 'Cerrar';

  @override
  String get share => 'Compartir';

  @override
  String get share_copied =>
      'Compartir no está disponible aquí. El texto se copió.';

  @override
  String get convert_format => 'Guardar con codificación';

  @override
  String convert_format_applied(String endings, String encoding) {
    return 'El próximo guardado usará $endings y $encoding.';
  }

  @override
  String get keyboard_shortcuts =>
      'Atajos: Ctrl/Cmd+S guardar, Shift+S guardar como, O abrir, N nuevo, F buscar, Z deshacer, Shift+Z o Y rehacer, Esc cerrar búsqueda.';
}
