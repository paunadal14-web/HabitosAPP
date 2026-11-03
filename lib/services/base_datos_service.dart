import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/usuario.dart';
import '../models/habito.dart';
import '../models/estadistica.dart';

class BaseDatosService {
  static final instancia = BaseDatosService();
  late Database _db;
  int? _sesionId;

  Future<void> abrir({String? ruta}) async {
    if (ruta == null) {
      final carpeta = await getApplicationSupportDirectory();
      ruta = join(carpeta.path, 'habitos.db');
    }
    _db = await openDatabase(
      ruta,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE usuarios (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario TEXT NOT NULL UNIQUE COLLATE NOCASE,
            nombre TEXT NOT NULL,
            apellidos TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE COLLATE NOCASE,
            contrasena TEXT NOT NULL,
            fecha_creacion TEXT NOT NULL,
            rol TEXT NOT NULL CHECK (rol IN ('administrador', 'usuario'))
          )
        ''');
        await db.execute('''
          CREATE TABLE habitos (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario_id INTEGER NOT NULL,
            nombre TEXT NOT NULL,
            color TEXT NOT NULL,
            fechas_completadas TEXT NOT NULL DEFAULT '[]',
            FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE estadisticas (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habito_id INTEGER NOT NULL UNIQUE,
            racha_actual INTEGER NOT NULL CHECK (racha_actual >= 0),
            total_dias INTEGER NOT NULL CHECK (total_dias >= racha_actual),
            ajuste_manual INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY (habito_id) REFERENCES habitos(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<void> cerrar() async {
    _sesionId = null;
    await _db.close();
  }

  void cerrarSesion() {
    _sesionId = null;
  }

  Future<bool> hayUsuarios() async {
    final datos = await _db.query('usuarios', columns: ['id'], limit: 1);
    return datos.isNotEmpty;
  }

  void _validarUsuario(Usuario usuario) {
    if (usuario.usuario.trim().isEmpty ||
        usuario.nombre.trim().isEmpty ||
        usuario.apellidos.trim().isEmpty ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(usuario.email.trim())) {
      throw Exception('Revisa los datos del usuario.');
    }
  }

  String _prepararContrasena(String contrasena) {
    if (contrasena.length < 6 || utf8.encode(contrasena).length > 72) {
      throw Exception('La contraseña debe tener entre 6 y 72 bytes.');
    }
    // Guardamos un hash, no la contraseña que se ha escrito.
    return BCrypt.hashpw(contrasena, BCrypt.gensalt(logRounds: 12));
  }

  Future<Usuario> registrar(Usuario usuario, String contrasena) async {
    _validarUsuario(usuario);
    final hash = _prepararContrasena(contrasena);
    try {
      final id = await _db.transaction((txn) async {
        final existentes = await txn.query(
          'usuarios',
          columns: ['id'],
          limit: 1,
        );
        final datos = usuario.toMap();
        // La primera cuenta permite empezar a administrar la app.
        datos['rol'] = existentes.isEmpty ? 'administrador' : 'usuario';
        datos['fecha_creacion'] = DateTime.now().toIso8601String();
        datos['contrasena'] = hash;
        return txn.insert('usuarios', datos);
      });
      _sesionId = id;
      return await usuarioActual();
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw Exception('Ese usuario o email ya está registrado.');
      }
      rethrow;
    }
  }

  Future<Usuario> iniciarSesion(String usuario, String contrasena) async {
    final datos = await _db.query(
      'usuarios',
      where: 'usuario = ?',
      whereArgs: [usuario.trim()],
    );
    if (datos.isEmpty ||
        utf8.encode(contrasena).length > 72 ||
        !BCrypt.checkpw(contrasena, datos.first['contrasena'] as String)) {
      throw Exception('Usuario o contraseña incorrectos.');
    }
    _sesionId = datos.first['id'] as int;
    return Usuario.fromMap(datos.first);
  }

  Future<Usuario> usuarioActual() async {
    if (_sesionId == null) {
      throw Exception('Debes iniciar sesión.');
    }
    final datos = await _db.query(
      'usuarios',
      where: 'id = ?',
      whereArgs: [_sesionId],
    );
    if (datos.isEmpty) {
      throw Exception('Debes iniciar sesión.');
    }
    return Usuario.fromMap(datos.first);
  }

  Future<void> _comprobarAdministrador() async {
    final usuario = await usuarioActual();
    if (!usuario.esAdministrador) {
      throw Exception('Esta opción es solo para administradores.');
    }
  }

  Future<List<Usuario>> obtenerUsuarios() async {
    await _comprobarAdministrador();
    final datos = await _db.query(
      'usuarios',
      orderBy: 'usuario COLLATE NOCASE',
    );
    return datos.map((fila) => Usuario.fromMap(fila)).toList();
  }

  Future<void> _comprobarUltimoAdministrador(int id) async {
    final administradores = await _db.query(
      'usuarios',
      where: 'rol = ?',
      whereArgs: ['administrador'],
    );
    if (administradores.length == 1 && administradores.first['id'] == id) {
      throw Exception('Debe quedar al menos un administrador.');
    }
  }

  Future<void> guardarUsuario(Usuario usuario, String contrasena) async {
    await _comprobarAdministrador();
    _validarUsuario(usuario);
    final datos = usuario.toMap();
    if (usuario.id == null || contrasena.isNotEmpty) {
      datos['contrasena'] = _prepararContrasena(contrasena);
    }
    if (usuario.id != null && !usuario.esAdministrador) {
      await _comprobarUltimoAdministrador(usuario.id!);
    }
    try {
      if (usuario.id == null) {
        datos['fecha_creacion'] = DateTime.now().toIso8601String();
        await _db.insert('usuarios', datos);
      } else {
        await _db.update(
          'usuarios',
          datos,
          where: 'id = ?',
          whereArgs: [usuario.id],
        );
      }
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw Exception('Ese usuario o email ya está registrado.');
      }
      rethrow;
    }
  }

  Future<void> borrarUsuario(int id) async {
    await _comprobarAdministrador();
    await _comprobarUltimoAdministrador(id);
    // Al borrar un usuario se borran también sus hábitos y estadísticas.
    await _db.delete('usuarios', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Habito>> obtenerHabitos() async {
    final usuario = await usuarioActual();
    final datos = await _db.query(
      'habitos',
      where: usuario.esAdministrador ? null : 'usuario_id = ?',
      whereArgs: usuario.esAdministrador ? null : [usuario.id],
      orderBy: 'id DESC',
    );
    return datos.map((fila) => Habito.fromMap(fila)).toList();
  }

  Future<Habito> _comprobarHabito(int id) async {
    final usuario = await usuarioActual();
    final datos = await _db.query('habitos', where: 'id = ?', whereArgs: [id]);
    if (datos.isEmpty) throw Exception('No se ha encontrado el hábito.');
    final habito = Habito.fromMap(datos.first);
    // Comprobamos el dueño aquí, además de ocultar las opciones en pantalla.
    if (!usuario.esAdministrador && habito.usuarioId != usuario.id) {
      throw Exception('Solo puedes acceder a tus hábitos.');
    }
    return habito;
  }

  Future<void> guardarHabito(Habito habito) async {
    final usuario = await usuarioActual();
    if (habito.nombre.trim().isEmpty ||
        !['Azul', 'Verde', 'Naranja'].contains(habito.color)) {
      throw Exception('Revisa el nombre y el color del hábito.');
    }
    if (!usuario.esAdministrador && habito.usuarioId != usuario.id) {
      throw Exception('Solo puedes guardar tus hábitos.');
    }
    Habito? anterior;
    if (habito.id != null) anterior = await _comprobarHabito(habito.id!);
    final datos = habito.toMap();
    if (!usuario.esAdministrador) {
      datos['fechas_completadas'] = jsonEncode(
        anterior?.fechasCompletadas ?? [],
      );
    } else {
      for (final valor in habito.fechasCompletadas) {
        final fecha = DateTime.tryParse(valor);
        if (fecha == null ||
            Habito.fechaDelDia(fecha) != valor ||
            valor.compareTo(Habito.fechaDelDia(DateTime.now())) > 0) {
          throw Exception('Hay una fecha completada que no es válida.');
        }
      }
      datos['fechas_completadas'] = jsonEncode(
        habito.fechasCompletadas.toSet().toList(),
      );
    }
    await _db.transaction((txn) async {
      var id = habito.id;
      if (habito.id == null) {
        id = await txn.insert('habitos', datos);
      } else {
        await txn.update(
          'habitos',
          datos,
          where: 'id = ?',
          whereArgs: [habito.id],
        );
      }
      if (anterior == null ||
          jsonEncode(anterior.fechasCompletadas) !=
              datos['fechas_completadas']) {
        datos['id'] = id;
        final resumen = Estadistica.calcular(Habito.fromMap(datos)).toMap();
        resumen['ajuste_manual'] = 0;
        final filas = await txn.query(
          'estadisticas',
          where: 'habito_id = ?',
          whereArgs: [id],
        );
        if (filas.isEmpty) {
          await txn.insert('estadisticas', resumen);
        } else {
          await txn.update(
            'estadisticas',
            resumen,
            where: 'habito_id = ?',
            whereArgs: [id],
          );
        }
      }
    });
  }

  Future<void> borrarHabito(int id) async {
    await _comprobarHabito(id);
    await _db.delete('habitos', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> marcarHoy(int id, bool completado) async {
    final habito = await _comprobarHabito(id);
    final fechas = List<String>.from(habito.fechasCompletadas);
    final hoy = Habito.fechaDelDia(DateTime.now());
    fechas.remove(hoy);
    if (completado) fechas.add(hoy);
    final actualizado = Habito(
      id: id,
      usuarioId: habito.usuarioId,
      nombre: habito.nombre,
      color: habito.color,
      fechasCompletadas: fechas,
    );
    final estadistica = Estadistica.calcular(actualizado);
    // Se guardan las fechas y el resumen juntos para que coincidan.
    await _db.transaction((txn) async {
      await txn.update(
        'habitos',
        {'fechas_completadas': jsonEncode(fechas)},
        where: 'id = ?',
        whereArgs: [id],
      );
      final filas = await txn.query(
        'estadisticas',
        where: 'habito_id = ?',
        whereArgs: [id],
      );
      if (filas.isEmpty) {
        await txn.insert('estadisticas', estadistica.toMap());
      } else {
        final datos = estadistica.toMap();
        datos['ajuste_manual'] = 0;
        await txn.update(
          'estadisticas',
          datos,
          where: 'habito_id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  Future<List<Estadistica>> obtenerEstadisticas() async {
    final usuario = await usuarioActual();
    // El JOIN permite filtrar las estadísticas por el dueño del hábito.
    final datos = await _db.rawQuery('''
      SELECT e.* FROM estadisticas e
      INNER JOIN habitos h ON h.id = e.habito_id
      ${usuario.esAdministrador ? '' : 'WHERE h.usuario_id = ?'}
      ORDER BY e.id
    ''', usuario.esAdministrador ? [] : [usuario.id]);
    final resultado = <Estadistica>[];
    for (final fila in datos) {
      final estadistica = Estadistica.fromMap(fila);
      final habito = await _comprobarHabito(estadistica.habitoId);
      final calculada = Estadistica.calcular(habito);
      // Una racha termina aunque no se vuelva a marcar el hábito.
      // Si el administrador corrigió los números, se mantienen hasta marcarlo.
      final totalReal = habito.fechasCompletadas.toSet().length;
      if (fila['ajuste_manual'] == 0 &&
          estadistica.rachaActual != calculada.rachaActual) {
        await _db.update(
          'estadisticas',
          {'racha_actual': calculada.rachaActual},
          where: 'id = ?',
          whereArgs: [estadistica.id],
        );
        resultado.add(
          Estadistica(
            id: estadistica.id,
            habitoId: habito.id!,
            rachaActual: calculada.rachaActual,
            totalDias: totalReal,
          ),
        );
      } else {
        resultado.add(estadistica);
      }
    }
    return resultado;
  }

  Future<void> guardarEstadistica(Estadistica estadistica) async {
    await _comprobarAdministrador();
    await _comprobarHabito(estadistica.habitoId);
    if (estadistica.rachaActual < 0 ||
        estadistica.totalDias < estadistica.rachaActual) {
      throw Exception('La racha no puede superar el total de días.');
    }
    try {
      final datos = estadistica.toMap();
      datos['ajuste_manual'] = 1;
      if (estadistica.id == null) {
        await _db.insert('estadisticas', datos);
      } else {
        await _db.update(
          'estadisticas',
          datos,
          where: 'id = ?',
          whereArgs: [estadistica.id],
        );
      }
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw Exception(
          'Ese hábito ya tiene una estadística. Puedes editarla.',
        );
      }
      rethrow;
    }
  }

  Future<void> borrarEstadistica(int id) async {
    await _comprobarAdministrador();
    await _db.delete('estadisticas', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> borrarTodo() async {
    await _comprobarAdministrador();
    await _db.transaction((txn) async {
      await txn.delete('usuarios');
      await txn.delete('sqlite_sequence');
    });
    _sesionId = null;
  }
}
