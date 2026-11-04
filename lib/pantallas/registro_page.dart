import 'package:flutter/material.dart';

import '../modelos/usuario.dart';
import '../servicios/base_datos_service.dart';
import '../widgets/campo_texto_app.dart';
import '../widgets/boton_principal.dart';
import '../widgets/dialogos.dart';
import '../servicios/preferencias_service.dart';
import 'habitos_page.dart';

class RegistroPage extends StatefulWidget {
  final VoidCallback alCambiarAjustes;
  const RegistroPage({super.key, required this.alCambiarAjustes});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {
  final formulario = GlobalKey<FormState>();
  final usuarioController = TextEditingController();
  final nombreController = TextEditingController();
  final apellidosController = TextEditingController();
  final emailController = TextEditingController();
  final contrasenaController = TextEditingController();
  final objetivoController = TextEditingController(text: '5');
  bool guardando = false;

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

  String? validarEmail(String? valor) {
    if (valor == null ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(valor.trim())) {
      return 'Escribe un email válido.';
    }
    return null;
  }

  String? validarContrasena(String? valor) {
    return valor == null || valor.length < 6
        ? 'Escribe al menos 6 caracteres.'
        : null;
  }

  Future<void> guardar() async {
    if (!formulario.currentState!.validate()) return;
    final usuario = Usuario(
      usuario: usuarioController.text,
      nombre: nombreController.text,
      apellidos: apellidosController.text,
      email: emailController.text,
      fechaCreacion: DateTime.now().toIso8601String(),
    );
    setState(() => guardando = true);
    try {
      final nuevo = await BaseDatosService.instancia.registrar(
        usuario,
        contrasenaController.text,
      );
      await PreferenciasService.instancia.guardarObjetivo(
        nuevo.id!,
        int.parse(objetivoController.text),
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HabitosPage(
            usuario: nuevo,
            alCambiarAjustes: widget.alCambiarAjustes,
          ),
        ),
        (ruta) => false,
      );
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
        appBar: AppBar(title: const Text('Crear cuenta')),
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
                      etiqueta: 'Contraseña (mínimo 6 caracteres)',
                      controller: contrasenaController,
                      ocultar: true,
                      validador: validarContrasena,
                      habilitado: !guardando,
                    ),
                    CampoTextoApp(
                      etiqueta: 'Objetivo diario de hábitos',
                      controller: objetivoController,
                      tipoTeclado: TextInputType.number,
                      habilitado: !guardando,
                      validador: (valor) {
                        final numero = int.tryParse(valor ?? '');
                        return numero == null || numero <= 0
                            ? 'Escribe un número mayor que 0.'
                            : null;
                      },
                    ),
                    BotonPrincipal(
                      texto: guardando ? 'Guardando...' : 'Registrarse',
                      alPulsar: guardar,
                      habilitado: !guardando,
                    ),
                    TextButton(
                      onPressed: guardando
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Volver al inicio de sesión'),
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
