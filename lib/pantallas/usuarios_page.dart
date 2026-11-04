import 'package:flutter/material.dart';

import '../modelos/usuario.dart';
import '../servicios/base_datos_service.dart';
import '../widgets/dialogos.dart';
import 'usuario_form_page.dart';

class UsuariosPage extends StatefulWidget {
  const UsuariosPage({super.key});

  @override
  State<UsuariosPage> createState() => _UsuariosPageState();
}

class _UsuariosPageState extends State<UsuariosPage> {
  final baseDatos = BaseDatosService.instancia;
  List<Usuario> usuarios = [];
  bool cargando = true;
  bool borrando = false;
  String? errorCarga;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    try {
      final actual = await baseDatos.usuarioActual();
      if (!actual.esAdministrador) {
        if (mounted) Navigator.pop(context);
        return;
      }
      final lista = await baseDatos.obtenerUsuarios();
      if (!mounted) return;
      setState(() {
        usuarios = lista;
        cargando = false;
        errorCarga = null;
      });
    } catch (e) {
      if (!mounted) return;
      // Si hemos borrado nuestra cuenta, volvemos a la principal para salir.
      try {
        await baseDatos.usuarioActual();
        if (mounted) {
          setState(() {
            errorCarga = e.toString();
            cargando = false;
          });
        }
      } catch (_) {
        if (mounted) Navigator.pop(context);
      }
    }
  }

  Future<void> editar([Usuario? usuario]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UsuarioFormPage(usuario: usuario),
      ),
    );
    if (mounted) await cargar();
  }

  Future<void> borrar(Usuario usuario) async {
    final confirmado = await confirmarBorrado(
      context,
      '¿Borrar a ${usuario.usuario}? También se borrarán sus hábitos y estadísticas.',
    );
    if (!confirmado || !mounted) return;
    setState(() => borrando = true);
    try {
      await baseDatos.borrarUsuario(usuario.id!);
      await cargar();
    } catch (e) {
      if (mounted) mostrarMensaje(context, e);
    } finally {
      if (mounted) setState(() => borrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Usuarios')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Crear usuario',
        onPressed: cargando || borrando ? null : () => editar(),
        child: const Icon(Icons.person_add),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : errorCarga != null
          ? Center(child: Text(errorCarga!))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              children: [
                for (final usuario in usuarios)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            usuario.usuario,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('${usuario.nombre} ${usuario.apellidos}'),
                          Text(usuario.email),
                          Text('Rol: ${usuario.rol}'),
                          Text('Creación: ${usuario.fechaCreacion}'),
                          Wrap(
                            spacing: 12,
                            children: [
                              TextButton(
                                onPressed: borrando
                                    ? null
                                    : () => editar(usuario),
                                child: const Text('Editar'),
                              ),
                              TextButton(
                                onPressed: borrando
                                    ? null
                                    : () => borrar(usuario),
                                child: const Text('Borrar'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
