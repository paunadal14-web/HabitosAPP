import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app/modelos/habito.dart';
import 'package:habitos_app/modelos/estadistica.dart';

void main() {
  Estadistica calcular(List<String> fechas) {
    return Estadistica.calcular(
      Habito(
        id: 1,
        usuarioId: 1,
        nombre: 'Leer',
        color: 'Azul',
        fechasCompletadas: fechas,
      ),
      ahora: DateTime(2026, 11, 3),
    );
  }

  test('racha que incluye hoy, sin contar fechas repetidas', () {
    final resultado = calcular([
      '2026-11-01',
      '2026-11-02',
      '2026-11-03',
      '2026-11-03',
    ]);
    expect(resultado.rachaActual, 3);
    expect(resultado.totalDias, 3);
  });

  test('la racha sigue si solo falta completar hoy', () {
    expect(calcular(['2026-11-01', '2026-11-02']).rachaActual, 2);
  });

  test('una interrupción corta la racha y conserva el total', () {
    final resultado = calcular(['2026-10-30', '2026-11-01']);
    expect(resultado.rachaActual, 0);
    expect(resultado.totalDias, 2);
    expect(calcular([]).rachaActual, 0);
  });
}
