import 'habito.dart';

class Estadistica {
  final int? id;
  final int habitoId;
  final int rachaActual;
  final int totalDias;

  Estadistica({
    this.id,
    required this.habitoId,
    required this.rachaActual,
    required this.totalDias,
  });

  Map<String, Object?> toMap() {
    return {
      'habito_id': habitoId,
      'racha_actual': rachaActual,
      'total_dias': totalDias,
    };
  }

  factory Estadistica.fromMap(Map<String, Object?> datos) {
    return Estadistica(
      id: datos['id'] as int,
      habitoId: datos['habito_id'] as int,
      rachaActual: datos['racha_actual'] as int,
      totalDias: datos['total_dias'] as int,
    );
  }

  static Estadistica calcular(Habito habito, {DateTime? ahora}) {
    final fechas = habito.fechasCompletadas.toSet();
    final fecha = ahora ?? DateTime.now();
    var dia = DateTime(fecha.year, fecha.month, fecha.day);
    var racha = 0;

    // Si hoy aún no lo hemos hecho, la racha puede continuar desde ayer.
    if (!fechas.contains(Habito.fechaDelDia(dia))) {
      dia = DateTime(dia.year, dia.month, dia.day - 1);
    }
    while (fechas.contains(Habito.fechaDelDia(dia))) {
      racha++;
      dia = DateTime(dia.year, dia.month, dia.day - 1);
    }
    return Estadistica(
      habitoId: habito.id!,
      rachaActual: racha,
      totalDias: fechas.length,
    );
  }
}
