import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habitos_app/models/usuario.dart';
import 'package:habitos_app/widgets/formulario_usuario.dart';
import 'package:habitos_app/screens/editar_screen.dart';

void main() {
  testWidgets('registro valida los campos antes de guardar', (tester) async {
    var guardado = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FormularioUsuario(
              pedirObjetivo: true,
              guardando: false,
              alGuardar: (usuario, contrasena, objetivo) async {
                guardado = true;
              },
            ),
          ),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(guardado, isFalse);
    expect(find.text('Rellena este campo.'), findsNWidgets(3));
    expect(find.text('Escribe un email válido.'), findsOneWidget);
  });

  testWidgets('registro recoge los datos y el objetivo', (tester) async {
    Usuario? guardado;
    var objetivoGuardado = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FormularioUsuario(
              pedirObjetivo: true,
              guardando: false,
              alGuardar: (usuario, contrasena, objetivo) async {
                guardado = usuario;
                objetivoGuardado = objetivo;
              },
            ),
          ),
        ),
      ),
    );
    final campos = find.byType(TextFormField);
    await tester.enterText(campos.at(0), 'ana');
    await tester.enterText(campos.at(1), 'Ana');
    await tester.enterText(campos.at(2), 'Prueba');
    await tester.enterText(campos.at(3), 'ana@example.com');
    await tester.enterText(campos.at(4), 'clave123');
    await tester.enterText(campos.at(5), '3');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(guardado?.usuario, 'ana');
    expect(guardado?.rol, 'usuario');
    expect(objetivoGuardado, 3);
  });

  testWidgets(
    'crear hábito no permite guardar un nombre vacío en pantalla pequeña',
    (tester) async {
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
        fechaCreacion: '2026-11-03',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: EditarScreen(usuario: usuario, usuarios: []),
        ),
      );
      await tester.tap(find.text('Naranja'));
      await tester.tap(find.text('Guardar'));
      await tester.pump();
      expect(find.text('Escribe un nombre.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
