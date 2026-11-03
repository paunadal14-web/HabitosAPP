import 'package:flutter/material.dart';

import '../models/usuario.dart';

class FormularioUsuario extends StatefulWidget {
  final Usuario? usuario;
  final bool permitirRol;
  final bool pedirObjetivo;
  final bool guardando;
  final Future<void> Function(Usuario, String, int) alGuardar;

  const FormularioUsuario({
    super.key,
    this.usuario,
    this.permitirRol = false,
    this.pedirObjetivo = false,
    required this.guardando,
    required this.alGuardar,
  });

  @override
  State<FormularioUsuario> createState() => _FormularioUsuarioState();
}

class _FormularioUsuarioState extends State<FormularioUsuario> {
  final formulario = GlobalKey<FormState>();
  final usuarioController = TextEditingController();
  final nombreController = TextEditingController();
  final apellidosController = TextEditingController();
  final emailController = TextEditingController();
  final contrasenaController = TextEditingController();
  final objetivoController = TextEditingController(text: '5');
  String rol = 'usuario';

  @override
  void initState() {
    super.initState();
    final usuario = widget.usuario;
    if (usuario != null) {
      usuarioController.text = usuario.usuario;
      nombreController.text = usuario.nombre;
      apellidosController.text = usuario.apellidos;
      emailController.text = usuario.email;
      rol = usuario.rol;
    }
  }

  @override
  void dispose() {
    usuarioController.dispose();
    nombreController.dispose();
    apellidosController.dispose();
    emailController.dispose();
    contrasenaController.dispose();
    objetivoController.dispose();
    super.dispose();
  }

  String? obligatorio(String? valor) {
    return valor == null || valor.trim().isEmpty ? 'Rellena este campo.' : null;
  }

  void guardar() {
    if (!formulario.currentState!.validate()) return;
    final usuario = Usuario(
      id: widget.usuario?.id,
      usuario: usuarioController.text,
      nombre: nombreController.text,
      apellidos: apellidosController.text,
      email: emailController.text,
      fechaCreacion:
          widget.usuario?.fechaCreacion ?? DateTime.now().toIso8601String(),
      rol: rol,
    );
    widget.alGuardar(
      usuario,
      contrasenaController.text,
      int.tryParse(objetivoController.text) ?? 5,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formulario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: usuarioController,
            decoration: const InputDecoration(labelText: 'Usuario'),
            validator: obligatorio,
          ),
          TextFormField(
            controller: nombreController,
            decoration: const InputDecoration(labelText: 'Nombre'),
            validator: obligatorio,
          ),
          TextFormField(
            controller: apellidosController,
            decoration: const InputDecoration(labelText: 'Apellidos'),
            validator: obligatorio,
          ),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (valor) {
              if (valor == null ||
                  !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                      .hasMatch(valor.trim())) {
                return 'Escribe un email válido.';
              }
              return null;
            },
          ),
          TextFormField(
            controller: contrasenaController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: widget.usuario == null
                  ? 'Contraseña (mínimo 6 caracteres)'
                  : 'Nueva contraseña (opcional)',
            ),
            validator: (valor) {
              if (widget.usuario != null && (valor == null || valor.isEmpty)) {
                return null;
              }
              return valor == null || valor.length < 6
                  ? 'Escribe al menos 6 caracteres.'
                  : null;
            },
          ),
          if (widget.pedirObjetivo)
            TextFormField(
              controller: objetivoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Objetivo diario de hábitos',
              ),
              validator: (valor) {
                final numero = int.tryParse(valor ?? '');
                return numero == null || numero <= 0
                    ? 'Escribe un número mayor que 0.'
                    : null;
              },
            ),
          if (widget.permitirRol)
            DropdownButtonFormField<String>(
              initialValue: rol,
              decoration: const InputDecoration(labelText: 'Rol'),
              items: const [
                DropdownMenuItem(value: 'usuario', child: Text('Usuario')),
                DropdownMenuItem(
                  value: 'administrador',
                  child: Text('Administrador'),
                ),
              ],
              onChanged: (valor) => setState(() => rol = valor!),
            ),
          if (widget.usuario != null) ...[
            const SizedBox(height: 16),
            Text('Fecha de creación: ${widget.usuario!.fechaCreacion}'),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.guardando ? null : guardar,
            child: Text(widget.guardando ? 'Guardando...' : 'Guardar'),
          ),
        ],
      ),
    );
  }
}
