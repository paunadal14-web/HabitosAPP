import 'package:flutter/material.dart';

import '../modelos/usuario.dart';
import '../servicios/base_datos_service.dart';
import '../widgets/campo_texto_app.dart';
import '../widgets/boton_principal.dart';
import '../widgets/dialogos.dart';

class UsuarioFormPage extends StatefulWidget {
  final Usuario? usuario;
  const UsuarioFormPage({super.key, this.usuario});

  @override
  State<UsuarioFormPage> createState() => _UsuarioFormPageState();
}

class _UsuarioFormPageState extends State<UsuarioFormPage> {
  final formulario = GlobalKey<FormState>();
  final usuarioController = TextEditingController();
  final nombreController = TextEditingController();
  final apellidosController = TextEditingController();
  final emailController = TextEditingController();
  final contrasenaController = TextEditingController();
  String rol = 'usuario';
  bool guardando = false;

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

    super.dispose();
  }

  String? obligatorio(String? valor) {
    return valor == null || valor.trim().isEmpty ? 'Rellena este campo.' : null;
  }

  String? validarEmail(String? valor) {
    if (valor == null ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(valor.trim())) {
      return 'Escribe un email válido.';
    }
    return null;
  }

  String? validarContrasena(String? valor) {
    if (widget.usuario != null && (valor == null || valor.isEmpty)) return null;
    return valor == null || valor.length < 6
        ? 'Escribe al menos 6 caracteres.'
        : null;
  }

  Future<void> guardar() async {
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
    setState(() => guardando = true);
    try {
      await BaseDatosService.instancia.guardarUsuario(
        usuario,
        contrasenaController.text,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e);
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !guardando,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.usuario == null ? 'Crear usuario' : 'Editar usuario',
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Form(
                key: formulario,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CampoTextoApp(
                      etiqueta: 'Usuario',
                      controller: usuarioController,
                      validador: obligatorio,
                      habilitado: !guardando,
                    ),
                    CampoTextoApp(
                      etiqueta: 'Nombre',
                      controller: nombreController,
                      validador: obligatorio,
                      habilitado: !guardando,
                    ),
                    CampoTextoApp(
                      etiqueta: 'Apellidos',
                      controller: apellidosController,
                      validador: obligatorio,
                      habilitado: !guardando,
                    ),
                    CampoTextoApp(
                      etiqueta: 'Email',
                      controller: emailController,
                      tipoTeclado: TextInputType.emailAddress,
                      validador: validarEmail,
                      habilitado: !guardando,
                    ),
                    CampoTextoApp(
                      etiqueta: widget.usuario == null
                          ? 'Contraseña (mínimo 6 caracteres)'
                          : 'Nueva contraseña (opcional)',
                      controller: contrasenaController,
                      ocultar: true,
                      validador: validarContrasena,
                      habilitado: !guardando,
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: rol,
                      decoration: const InputDecoration(
                        labelText: 'Rol',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'usuario',
                          child: Text('Usuario'),
                        ),
                        DropdownMenuItem(
                          value: 'administrador',
                          child: Text('Administrador'),
                        ),
                      ],
                      onChanged: guardando
                          ? null
                          : (valor) => setState(() => rol = valor!),
                    ),
                    if (widget.usuario != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'Fecha de creación: ${widget.usuario!.fechaCreacion}',
                        ),
                      ),
                    const SizedBox(height: 16),
                    BotonPrincipal(
                      texto: guardando ? 'Guardando...' : 'Guardar usuario',
                      alPulsar: guardar,
                      habilitado: !guardando,
                    ),
                    TextButton(
                      onPressed: guardando
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
