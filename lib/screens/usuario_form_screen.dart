import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/base_datos_service.dart';
import '../widgets/dialogos.dart';
import '../widgets/formulario_usuario.dart';

class UsuarioFormScreen extends StatefulWidget {
  final Usuario? usuario;
  const UsuarioFormScreen({super.key, this.usuario});

  @override
  State<UsuarioFormScreen> createState() => _UsuarioFormScreenState();
}

class _UsuarioFormScreenState extends State<UsuarioFormScreen> {
  bool guardando = false;

  Future<void> guardar(Usuario usuario, String contrasena, int objetivo) async {
    setState(() => guardando = true);
    try {
      await BaseDatosService.instancia.guardarUsuario(usuario, contrasena);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e);
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.usuario == null ? 'Crear usuario' : 'Editar usuario',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FormularioUsuario(
          usuario: widget.usuario,
          permitirRol: true,
          guardando: guardando,
          alGuardar: guardar,
        ),
      ),
    );
  }
}
