import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:habitos_app/modelos/usuario.dart';
import 'package:habitos_app/modelos/habito.dart';
import 'package:habitos_app/modelos/estadistica.dart';
import 'package:habitos_app/servicios/base_datos_service.dart';

Usuario datosUsuario(String nombre, {String rol = 'usuario'}) {
  return Usuario(
    usuario: nombre,
    nombre: nombre,
    apellidos: 'Prueba',
    email: '$nombre@example.com',
    fechaCreacion: DateTime.now().toIso8601String(),
    rol: rol,
  );
}

void main() {
  late BaseDatosService db;
  late Usuario admin;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    db = BaseDatosService();
    await db.abrir(ruta: inMemoryDatabasePath);
    admin = await db.registrar(datosUsuario('admin'), 'clave123');
  });

  tearDown(() async {
    await db.cerrar();
  });

  test('registro, login y CRUD de usuarios con permisos', () async {
    expect(admin.esAdministrador, isTrue);
    final ana = await db.registrar(
      datosUsuario('ana', rol: 'administrador'),
      'clave456',
    );
    expect(ana.rol, 'usuario');
    await expectLater(db.obtenerUsuarios(), throwsException);
    await expectLater(
      db.guardarUsuario(datosUsuario('otro'), 'clave123'),
      throwsException,
    );
    await expectLater(db.borrarUsuario(admin.id!), throwsException);
    await expectLater(db.borrarTodo(), throwsException);
    await expectLater(db.iniciarSesion('ana', 'incorrecta'), throwsException);
    await expectLater(
      db.registrar(datosUsuario('ANA'), 'clave123'),
      throwsException,
    );
    await db.iniciarSesion('ADMIN', 'clave123');
    expect((await db.obtenerUsuarios()).length, 2);
    await expectLater(db.borrarUsuario(admin.id!), throwsException);
    await db.guardarUsuario(
      Usuario(
        id: ana.id,
        usuario: 'ana2',
        nombre: 'Ana',
        apellidos: 'Nuevos',
        email: 'ana2@example.com',
        fechaCreacion: ana.fechaCreacion,
      ),
      'nueva123',
    );
    await expectLater(db.iniciarSesion('ana', 'clave456'), throwsException);
    expect((await db.iniciarSesion('ana2', 'nueva123')).apellidos, 'Nuevos');
    await db.iniciarSesion('admin', 'clave123');
    await db.guardarUsuario(datosUsuario('creado'), 'clave123');
    expect((await db.obtenerUsuarios()).length, 3);
    await db.borrarUsuario(ana.id!);
    expect((await db.obtenerUsuarios()).length, 2);
    db.cerrarSesion();
    await expectLater(db.obtenerHabitos(), throwsException);
  });

  test('cada usuario accede solamente a sus hábitos y estadísticas', () async {
    final ana = await db.registrar(datosUsuario('ana'), 'clave456');
    await db.guardarHabito(
      Habito(
        usuarioId: ana.id!,
        nombre: 'Caminar',
        color: 'Verde',
        fechasCompletadas: [],
      ),
    );
    final habitoAna = (await db.obtenerHabitos()).single;
    await db.marcarHoy(habitoAna.id!, true);
    await db.marcarHoy(habitoAna.id!, true);
    expect((await db.obtenerEstadisticas()).single.totalDias, 1);
    final luis = await db.registrar(datosUsuario('luis'), 'clave789');
    expect(await db.obtenerHabitos(), isEmpty);
    expect(await db.obtenerEstadisticas(), isEmpty);
    await expectLater(db.marcarHoy(habitoAna.id!, true), throwsException);
    await expectLater(db.borrarHabito(habitoAna.id!), throwsException);
    await expectLater(
      db.guardarHabito(
        Habito(
          id: habitoAna.id,
          usuarioId: luis.id!,
          nombre: 'Ajeno',
          color: 'Azul',
          fechasCompletadas: [],
        ),
      ),
      throwsException,
    );
    await expectLater(
      db.guardarHabito(
        Habito(
          usuarioId: ana.id!,
          nombre: 'Ajeno',
          color: 'Azul',
          fechasCompletadas: [],
        ),
      ),
      throwsException,
    );
    await expectLater(
      db.guardarEstadistica(
        Estadistica(habitoId: habitoAna.id!, rachaActual: 3, totalDias: 5),
      ),
      throwsException,
    );
    await expectLater(db.borrarEstadistica(1), throwsException);
    await db.iniciarSesion('ana', 'clave456');
    await db.guardarHabito(
      Habito(
        id: habitoAna.id,
        usuarioId: ana.id!,
        nombre: 'Pasear',
        color: 'Naranja',
        fechasCompletadas: [],
      ),
    );
    expect((await db.obtenerHabitos()).single.fechasCompletadas.length, 1);
    await db.marcarHoy(habitoAna.id!, false);
    expect((await db.obtenerEstadisticas()).single.totalDias, 0);
    await db.iniciarSesion('admin', 'clave123');
    expect(await db.obtenerHabitos(soloPropios: true), isEmpty);
    expect(await db.obtenerEstadisticas(soloPropios: true), isEmpty);
    await db.guardarHabito(
      Habito(
        id: habitoAna.id,
        usuarioId: luis.id!,
        nombre: 'De Luis',
        color: 'Azul',
        fechasCompletadas: [],
      ),
    );
    await db.iniciarSesion('ana', 'clave456');
    expect(await db.obtenerHabitos(), isEmpty);
    await db.iniciarSesion('luis', 'clave789');
    expect((await db.obtenerHabitos()).single.nombre, 'De Luis');
    await db.borrarHabito(habitoAna.id!);
    expect(await db.obtenerEstadisticas(), isEmpty);
  });

  test(
    'administrador gestiona historial y CRUD completo de estadísticas',
    () async {
      final hoy = Habito.fechaDelDia(DateTime.now());
      await db.guardarHabito(
        Habito(
          usuarioId: admin.id!,
          nombre: 'Agua',
          color: 'Azul',
          fechasCompletadas: [hoy],
        ),
      );
      final habito = (await db.obtenerHabitos()).single;
      var estadistica = (await db.obtenerEstadisticas()).single;
      expect(estadistica.rachaActual, 1);
      await db.guardarEstadistica(
        Estadistica(
          id: estadistica.id,
          habitoId: habito.id!,
          rachaActual: 0,
          totalDias: 1,
        ),
      );
      expect((await db.obtenerEstadisticas()).single.rachaActual, 0);
      await db.guardarEstadistica(
        Estadistica(
          id: estadistica.id,
          habitoId: habito.id!,
          rachaActual: 3,
          totalDias: 8,
        ),
      );
      expect((await db.obtenerEstadisticas()).single.totalDias, 8);
      await db.borrarEstadistica(estadistica.id!);
      expect(await db.obtenerEstadisticas(), isEmpty);
      await db.guardarEstadistica(
        Estadistica(habitoId: habito.id!, rachaActual: 2, totalDias: 4),
      );
      await expectLater(
        db.guardarEstadistica(
          Estadistica(habitoId: habito.id!, rachaActual: 0, totalDias: 0),
        ),
        throwsException,
      );
      estadistica = (await db.obtenerEstadisticas()).single;
      await expectLater(
        db.guardarEstadistica(
          Estadistica(
            id: estadistica.id,
            habitoId: habito.id!,
            rachaActual: 5,
            totalDias: 2,
          ),
        ),
        throwsException,
      );
      await db.marcarHoy(habito.id!, false);
      expect((await db.obtenerEstadisticas()).single.totalDias, 0);
      await db.guardarHabito(
        Habito(
          id: habito.id,
          usuarioId: admin.id!,
          nombre: 'Leer',
          color: 'Verde',
          fechasCompletadas: ['2020-01-01'],
        ),
      );
      expect((await db.obtenerEstadisticas()).single.totalDias, 1);
      expect((await db.obtenerEstadisticas()).single.rachaActual, 0);
      await db.borrarHabito(habito.id!);
      expect(await db.obtenerEstadisticas(), isEmpty);
    },
  );

  test(
    'borrar usuario elimina sus hábitos y permite restablecer la app',
    () async {
      final ana = await db.registrar(datosUsuario('ana'), 'clave456');
      await db.guardarHabito(
        Habito(
          usuarioId: ana.id!,
          nombre: 'Leer',
          color: 'Verde',
          fechasCompletadas: [],
        ),
      );
      await db.iniciarSesion('admin', 'clave123');
      expect((await db.obtenerHabitos()).length, 1);
      await db.borrarUsuario(ana.id!);
      expect(await db.obtenerHabitos(), isEmpty);
      expect(await db.obtenerEstadisticas(), isEmpty);
      await db.borrarTodo();
      expect(await db.hayUsuarios(), isFalse);
      await expectLater(db.usuarioActual(), throwsException);
      final primero = await db.registrar(datosUsuario('nuevo'), 'clave123');
      expect(primero.id, 1);
      expect(primero.esAdministrador, isTrue);
    },
  );

  test(
    'los datos siguen guardados después de cerrar y reabrir SQLite',
    () async {
      final carpeta = await Directory.systemTemp.createTemp('habitos_prueba_');
      final ruta = join(carpeta.path, 'prueba.db');
      final persistente = BaseDatosService();
      try {
        await persistente.abrir(ruta: ruta);
        final usuario = await persistente.registrar(
          datosUsuario('persistente'),
          'clave123',
        );
        await persistente.guardarHabito(
          Habito(
            usuarioId: usuario.id!,
            nombre: 'Dormir',
            color: 'Naranja',
            fechasCompletadas: [],
          ),
        );
        final id = (await persistente.obtenerHabitos()).single.id!;
        await persistente.marcarHoy(id, true);
        await persistente.cerrar();
        await persistente.abrir(ruta: ruta);
        await persistente.iniciarSesion('persistente', 'clave123');
        expect(
          (await persistente.obtenerHabitos()).single.completadoHoy,
          isTrue,
        );
        expect((await persistente.obtenerEstadisticas()).single.totalDias, 1);
        final conexion = await databaseFactoryFfi.openDatabase(ruta);
        final fila = (await conexion.query('usuarios')).single;
        expect(fila['contrasena'], isNot('clave123'));
        expect((fila['contrasena'] as String).startsWith(r'$2'), isTrue);
      } finally {
        await persistente.cerrar();
        await carpeta.delete(recursive: true);
      }
    },
  );
}
