import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitos_app/servicios/preferencias_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'ajustes y objetivos de cada cuenta se conservan al volver a cargar',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferencias = PreferenciasService();
      await preferencias.cargar();
      expect(preferencias.objetivo(1), 5);
      await preferencias.guardarAjustes(true, 1.2, true);
      await preferencias.guardarObjetivo(1, 3);
      await preferencias.guardarObjetivo(2, 7);
      await preferencias.registrarApertura();
      await preferencias.cargar();
      expect(preferencias.oscuro, isTrue);
      expect(preferencias.tamanoLetra, 1.2);
      expect(preferencias.ocultarCompletados, isTrue);
      expect(preferencias.objetivo(1), 3);
      expect(preferencias.objetivo(2), 7);
      expect(preferencias.aperturas, 1);
      expect(DateTime.tryParse(preferencias.ultimaApertura), isNotNull);
      final datos = await SharedPreferences.getInstance();
      expect(
        datos.getStringList(PreferenciasService.claveHistorial)!.length,
        1,
      );
      await preferencias.borrarTodo();
      expect(preferencias.aperturas, 0);
      expect(preferencias.oscuro, isFalse);
      expect(preferencias.objetivo(1), 5);
    },
  );
}
