import 'package:shared_preferences/shared_preferences.dart';

class PreferenciasService {
  static final instancia = PreferenciasService();
  static const claveOscuro = 'tema_oscuro';
  static const claveLetra = 'tamano_letra';
  static const claveOcultar = 'ocultar_completados';
  static const claveAperturas = 'numero_aperturas';
  static const claveUltima = 'ultima_apertura';
  static const claveHistorial = 'historial_aperturas';
  static const claveObjetivo = 'objetivo_usuario_';
  late SharedPreferences _prefs;

  Future<void> cargar() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Las preferencias guardan ajustes. Los usuarios y hábitos van a SQLite.
  bool get oscuro => _prefs.getBool(claveOscuro) ?? false;
  double get tamanoLetra => _prefs.getDouble(claveLetra) ?? 1.0;
  bool get ocultarCompletados => _prefs.getBool(claveOcultar) ?? false;
  int get aperturas => _prefs.getInt(claveAperturas) ?? 0;
  String get ultimaApertura => _prefs.getString(claveUltima) ?? '';

  int objetivo(int usuarioId) {
    return _prefs.getInt('$claveObjetivo$usuarioId') ?? 5;
  }

  Future<void> guardarObjetivo(int usuarioId, int objetivo) async {
    await _prefs.setInt('$claveObjetivo$usuarioId', objetivo);
  }

  Future<void> guardarAjustes(bool oscuro, double letra, bool ocultar) async {
    await _prefs.setBool(claveOscuro, oscuro);
    await _prefs.setDouble(claveLetra, letra);
    await _prefs.setBool(claveOcultar, ocultar);
  }

  Future<void> registrarApertura() async {
    final ahora = DateTime.now().toIso8601String();
    final historial = List<String>.from(
      _prefs.getStringList(claveHistorial) ?? [],
    );
    historial.add(ahora);
    if (historial.length > 20) historial.removeAt(0);
    await _prefs.setInt(claveAperturas, aperturas + 1);
    await _prefs.setString(claveUltima, ahora);
    await _prefs.setStringList(claveHistorial, historial);
  }

  Future<void> borrarTodo() async {
    await _prefs.clear();
  }
}
