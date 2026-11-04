import 'dart:convert';

class Habito {
  final int? id;
  final int usuarioId;
  final String nombre;
  final String color;
  final List<String> fechasCompletadas;

  Habito({
    this.id,
    required this.usuarioId,
    required this.nombre,
    required this.color,
    required this.fechasCompletadas,
  });

  // Guardamos solo el día para no contar varias veces la misma fecha.
  static String fechaDelDia(DateTime fecha) {
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '${fecha.year}-$mes-$dia';
  }

  bool get completadoHoy =>
      fechasCompletadas.contains(fechaDelDia(DateTime.now()));

  Map<String, Object?> toMap() {
    return {
      'usuario_id': usuarioId,
      'nombre': nombre.trim(),
      'color': color,
      // SQLite no tiene listas, así que las fechas se guardan como texto JSON.
      'fechas_completadas': jsonEncode(fechasCompletadas),
    };
  }

  factory Habito.fromMap(Map<String, Object?> datos) {
    return Habito(
      id: datos['id'] as int,
      usuarioId: datos['usuario_id'] as int,
      nombre: datos['nombre'] as String,
      color: datos['color'] as String,
      fechasCompletadas: List<String>.from(
        jsonDecode(datos['fechas_completadas'] as String) as List,
      ),
    );
  }
}
