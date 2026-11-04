import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app/modelos/usuario.dart';
import 'package:habitos_app/pantallas/registro_page.dart';
import 'package:habitos_app/pantallas/editar_habito_page.dart';
import 'package:habitos_app/widgets/campo_texto_app.dart';
import 'package:habitos_app/widgets/boton_principal.dart';
import 'package:habitos_app/widgets/tarjeta_habito.dart';
import 'package:habitos_app/widgets/dato_estadistica.dart';

void main() {
  testWidgets('registro valida sus campos antes de acceder a los datos', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: RegistroPage(alCambiarAjustes: () {})),
    );
    await tester.ensureVisible(find.text('Registrarse'));
    await tester.tap(find.text('Registrarse'));
    await tester.pump();
    expect(find.text('Rellena este campo.'), findsNWidgets(3));
    expect(find.text('Escribe un email válido.'), findsOneWidget);
    expect(find.byType(CampoTextoApp), findsNWidgets(6));
    expect(find.byType(BotonPrincipal), findsOneWidget);
  });

  testWidgets('CampoTextoApp sirve para texto normal y contraseña', (
    tester,
  ) async {
    final normal = TextEditingController();
    final secreto = TextEditingController();
    addTearDown(normal.dispose);
    addTearDown(secreto.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CampoTextoApp(etiqueta: 'Usuario', controller: normal),
              CampoTextoApp(
                etiqueta: 'Contraseña',
                controller: secreto,
                ocultar: true,
              ),
            ],
          ),
        ),
      ),
    );
    final campos = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(campos[0].obscureText, isFalse);
    expect(campos[1].obscureText, isTrue);
    await tester.enterText(find.byType(TextFormField).first, 'ana');
    expect(normal.text, 'ana');
  });

  testWidgets('cada tarjeta ejecuta los callbacks de su hábito', (
    tester,
  ) async {
    final acciones = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              for (final nombre in ['Agua', 'Leer'])
                TarjetaHabito(
                  nombre: nombre,
                  color: Colors.blue,
                  completadoHoy: nombre == 'Leer',
                  alCompletar: (valor) => acciones.add('$nombre:$valor'),
                  alEditar: () => acciones.add('editar:$nombre'),
                  alEliminar: () => acciones.add('eliminar:$nombre'),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('Editar').last);
    await tester.tap(find.text('Eliminar').first);
    await tester.tap(find.byType(Checkbox).first);
    expect(acciones, ['editar:Leer', 'eliminar:Agua', 'Agua:true']);
    expect(find.text('Pendiente hoy'), findsOneWidget);
    expect(find.text('Completado hoy'), findsOneWidget);
  });

  testWidgets('los datos estadísticos comparten diseño con valores distintos', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              DatoEstadistica(
                etiqueta: 'Racha actual',
                valor: '3',
                icono: Icons.local_fire_department,
              ),
              DatoEstadistica(
                etiqueta: 'Días completados',
                valor: '8',
                icono: Icons.event_available,
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(DatoEstadistica), findsNWidgets(2));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);
  });

  testWidgets(
    'BotonPrincipal ejecuta su acción y respeta el estado deshabilitado',
    (tester) async {
      var pulsaciones = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BotonPrincipal(texto: 'Entrar', alPulsar: () => pulsaciones++),
                BotonPrincipal(
                  texto: 'Guardar',
                  alPulsar: () => pulsaciones++,
                  habilitado: false,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('Entrar'));
      await tester.tap(find.text('Guardar'));
      expect(pulsaciones, 1);
    },
  );

  testWidgets('crear hábito valida el nombre y cabe en una pantalla pequeña', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final usuario = Usuario(
      id: 1,
      usuario: 'ana',
      nombre: 'Ana',
      apellidos: 'Prueba',
      email: 'ana@example.com',
      fechaCreacion: '2026-11-04',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: EditarHabitoPage(usuario: usuario, usuarios: []),
      ),
    );
    await tester.tap(find.text('Naranja'));
    await tester.tap(find.text('Guardar hábito'));
    await tester.pump();
    expect(find.text('Escribe un nombre.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
