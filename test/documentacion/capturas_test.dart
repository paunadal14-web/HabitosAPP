import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitos_app/modelos/usuario.dart';
import 'package:habitos_app/modelos/habito.dart';
import 'package:habitos_app/servicios/base_datos_service.dart';
import 'package:habitos_app/servicios/preferencias_service.dart';
import 'package:habitos_app/pantallas/login_page.dart';
import 'package:habitos_app/pantallas/editar_habito_page.dart';

// Este archivo solo genera las capturas de la memoria con datos temporales.
const fase = String.fromEnvironment('CAPTURAS_FASE', defaultValue: 'despues');
final borde = GlobalKey();
final db = BaseDatosService.instancia;
late Usuario pauchava;

Usuario cuenta(String usuario, String nombre) => Usuario(
  usuario: usuario,
  nombre: nombre,
  apellidos: 'Ejemplo',
  email: '$usuario@example.com',
  fechaCreacion: DateTime.now().toIso8601String(),
);

Future<void> esperar(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    if (finder.evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
  }
  expect(finder, findsWidgets);
}

Future<void> montar(WidgetTester tester, Widget pantalla) async {
  await tester.pumpWidget(
    RepaintBoundary(
      key: borde,
      child: MaterialApp(
        key: UniqueKey(),
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          fontFamily: 'Roboto',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        home: pantalla,
      ),
    ),
  );
}

Future<void> captura(WidgetTester tester, String nombre) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  await tester.runAsync(() async {
    final render =
        borde.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final imagen = await render.toImage(pixelRatio: 2);
    final datos = await imagen.toByteData(format: ui.ImageByteFormat.png);
    final carpeta = Directory('output/pdf/capturas');
    await carpeta.create(recursive: true);
    await File('${carpeta.path}/$nombre.png')
        .writeAsBytes(datos!.buffer.asUint8List());
    imagen.dispose();
  });
}

Future<void> pulsar(WidgetTester tester, String texto) async {
  await tester.ensureVisible(find.text(texto).last);
  await tester.pumpAndSettle();
  final chip = find.ancestor(
    of: find.text(texto).last,
    matching: find.byType(ChoiceChip),
  );
  await tester.tap(chip.evaluate().isEmpty ? find.text(texto).last : chip);
  await tester.pump();
}

Future<void> volver(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final sdk = Platform.environment['FLUTTER_ROOT'] ?? r'C:\Src\flutter';
    final fuente = FontLoader('Roboto');
    for (final archivo in [
      'roboto-regular.ttf',
      'roboto-bold.ttf',
      'roboto-medium.ttf',
    ]) {
      fuente.addFont(
        File('$sdk/bin/cache/artifacts/material_fonts/$archivo')
            .readAsBytes()
            .then((datos) => ByteData.sublistView(datos)),
      );
    }
    await fuente.load();
    final iconos = FontLoader('MaterialIcons');
    iconos.addFont(
      File('$sdk/bin/cache/artifacts/material_fonts/materialicons-regular.otf')
          .readAsBytes()
          .then((datos) => ByteData.sublistView(datos)),
    );
    await iconos.load();
    final mono = FontLoader('Consolas');
    mono.addFont(
      File(r'C:\Windows\Fonts\consola.ttf')
          .readAsBytes()
          .then((datos) => ByteData.sublistView(datos)),
    );
    await mono.load();
    SharedPreferences.setMockInitialValues({});
    await PreferenciasService.instancia.cargar();
    await PreferenciasService.instancia.registrarApertura();
    await db.abrir(ruta: inMemoryDatabasePath);
    await db.registrar(cuenta('admin', 'Administrador'), 'clave123');
    pauchava = await db.registrar(cuenta('pauchava', 'Pau'), 'clave123');
    final luis = await db.registrar(cuenta('luis', 'Luis'), 'clave123');
    await db.guardarHabito(
      Habito(
        usuarioId: luis.id!,
        nombre: 'Caminar 30 minutos',
        color: 'Naranja',
        fechasCompletadas: [],
      ),
    );
    db.cerrarSesion();
  });
  tearDownAll(() async {
    await db.cerrar();
  });

  testWidgets(
    'capturas y recorrido de la interfaz con SQLite temporal',
    (tester) async {
      final sombrasAnteriores = debugDisableShadows;
      debugDisableShadows = false;
      try {
        tester.view.physicalSize = const Size(420, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await montar(tester, LoginPage(alCambiarAjustes: () {}));
        await esperar(tester, find.text('Entrar'));
        await captura(tester, fase == 'antes' ? 'antes_login' : '01_login');

        if (fase == 'antes') {
          await montar(
            tester,
            EditarHabitoPage(usuario: pauchava, usuarios: []),
          );
          await tester.enterText(
            find.byType(TextFormField).first,
            'Beber agua',
          );
          await captura(tester, 'antes_habito');
          return;
        }

        await pulsar(tester, 'Crear cuenta');
        await esperar(tester, find.text('Registrarse'));
        for (final dato in [
          'pauchava',
          'Pau',
          'Ejemplo',
          'pauchava@example.com',
          'clave123',
          '5',
        ].asMap().entries) {
          await tester.enterText(
            find.byType(TextFormField).at(dato.key),
            dato.value,
          );
        }
        await captura(tester, '02_registro');
        await volver(tester);
        await tester.enterText(find.byType(TextFormField).at(0), 'pauchava');
        await tester.enterText(find.byType(TextFormField).at(1), 'clave123');
        await pulsar(tester, 'Entrar');
        await esperar(tester, find.text('Hola, Pau'));
        expect(find.byTooltip('Administración'), findsNothing);
        expect(find.text('Caminar 30 minutos'), findsNothing);
        await captura(tester, '03_lista_vacia');

        await tester.tap(find.byTooltip('Crear hábito'));
        await esperar(tester, find.text('Guardar hábito'));
        await tester.enterText(find.byType(TextFormField).first, 'Beber agua');
        await captura(tester, '04_crear');
        await pulsar(tester, 'Guardar hábito');
        await esperar(tester, find.text('Mis hábitos'));
        await esperar(tester, find.text('Beber agua'));
        await captura(tester, '05_creado');
        await tester.tap(find.byType(Checkbox).first);
        await esperar(tester, find.text('Completado hoy'));
        await captura(tester, '06_completado');

        await pulsar(tester, 'Editar');
        await esperar(tester, find.text('Editar hábito'));
        await tester.enterText(
          find.byType(TextFormField).first,
          'Beber 2 litros de agua',
        );
        await pulsar(tester, 'Verde');
        await captura(tester, '07_editar');
        await pulsar(tester, 'Guardar hábito');
        await esperar(tester, find.text('Mis hábitos'));
        await esperar(tester, find.text('Beber 2 litros de agua'));
        await captura(tester, '08_editado');
        await tester.tap(find.byTooltip('Crear hábito'));
        await esperar(tester, find.text('Guardar hábito'));
        await tester.enterText(
          find.byType(TextFormField).first,
          'Leer 20 minutos',
        );
        await pulsar(tester, 'Guardar hábito');
        await esperar(tester, find.text('Mis hábitos'));
        await esperar(tester, find.text('Leer 20 minutos'));
        await captura(tester, '09_dos_habitos');
        await tester.tap(find.byTooltip('Estadísticas'));
        await esperar(tester, find.text('Racha actual'));
        await captura(tester, '10_estadisticas');
        await volver(tester);

        await tester.tap(find.text('Eliminar').last);
        await esperar(tester, find.text('Confirmar borrado'));
        await captura(tester, '11_confirmacion');
        await pulsar(tester, 'Borrar');
        await esperar(tester, find.text('Leer 20 minutos'));
        await esperar(tester, find.text('Pendiente hoy'));
        expect(find.text('Beber 2 litros de agua'), findsNothing);
        await captura(tester, '12_eliminado');
        await tester.tap(find.byTooltip('Ajustes'));
        await esperar(tester, find.text('Guardar ajustes'));
        await captura(tester, '13_ajustes');
        await volver(tester);
        await tester.tap(find.byTooltip('Cerrar sesión'));
        await esperar(tester, find.text('Entrar'));
        await tester.enterText(find.byType(TextFormField).at(0), 'admin');
        await tester.enterText(find.byType(TextFormField).at(1), 'clave123');
        await pulsar(tester, 'Entrar');
        await esperar(tester, find.byTooltip('Administración'));
        await tester.tap(find.byTooltip('Administración'));
        await esperar(tester, find.text('Gestionar usuarios'));
        await captura(tester, '14_admin');
        await pulsar(tester, 'Gestionar usuarios');
        await esperar(tester, find.text('pauchava'));
        await captura(tester, '15_usuarios');
        await tester.tap(find.byTooltip('Crear usuario'));
        await esperar(tester, find.text('Guardar usuario'));
        await captura(tester, '16_usuario_form');
        await volver(tester);
        await volver(tester);
        await pulsar(tester, 'Gestionar hábitos');
        await esperar(tester, find.text('Caminar 30 minutos'));
        expect(find.text('Leer 20 minutos'), findsOneWidget);
        await captura(tester, '17_habitos_admin');
        await volver(tester);
        await pulsar(tester, 'Gestionar estadísticas');
        await esperar(tester, find.text('Racha actual'));
        await captura(tester, '18_estadisticas_admin');
        await tester.tap(find.text('Editar').first);
        await esperar(tester, find.text('Guardar estadística'));
        await captura(tester, '19_estadistica_form');

        final filas = <String>['lib/'];
        void recorrer(Directory carpeta, String prefijo) {
          final elementos = carpeta.listSync()
            ..sort((a, b) => a.path.compareTo(b.path));
          for (final elemento in elementos) {
            final nombre = elemento.path.split(Platform.pathSeparator).last;
            filas.add('$prefijo$nombre${elemento is Directory ? '/' : ''}');
            if (elemento is Directory) recorrer(elemento, '$prefijo    ');
          }
        }

        recorrer(Directory('lib'), '    ');
        tester.view.physicalSize = const Size(600, 1000);
        await montar(
          tester,
          Scaffold(
            appBar: AppBar(title: const Text('Organización del proyecto')),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                filas.join('\n'),
                style: const TextStyle(
                  fontFamily: 'Consolas',
                  fontSize: 17,
                  height: 1.35,
                ),
              ),
            ),
          ),
        );
        await captura(tester, '20_carpetas');
      } finally {
        debugDisableShadows = sombrasAnteriores;
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
    skip: !const bool.fromEnvironment('GENERAR_CAPTURAS'),
  );
}
