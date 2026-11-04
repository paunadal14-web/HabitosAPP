import 'package:flutter/material.dart';

import '../servicios/base_datos_service.dart';
import '../widgets/campo_texto_app.dart';
import '../widgets/boton_principal.dart';
import '../widgets/dialogos.dart';
import 'registro_page.dart';
import 'habitos_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback alCambiarAjustes;
  const LoginPage({super.key, required this.alCambiarAjustes});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final formulario = GlobalKey<FormState>();
  final usuarioController = TextEditingController();
  final contrasenaController = TextEditingController();
  bool entrando = false;
  bool cargando = true;
  bool primeraCuenta = false;
  String? errorCarga;

  @override
  void initState() {
    super.initState();
    comprobarUsuarios();
  }

  Future<void> comprobarUsuarios() async {
    try {
      final hayUsuarios = await BaseDatosService.instancia.hayUsuarios();
      if (!mounted) return;
      setState(() {
        primeraCuenta = !hayUsuarios;
        cargando = false;
        errorCarga = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorCarga = e.toString();
        cargando = false;
      });
    }
  }

  @override
  void dispose() {
    usuarioController.dispose();
    contrasenaController.dispose();
    super.dispose();
  }

  String? obligatorio(String? valor) {
    return valor == null || valor.trim().isEmpty ? 'Rellena este campo.' : null;
  }

  Future<void> entrar() async {
    if (!formulario.currentState!.validate()) return;
    setState(() => entrando = true);
    try {
      final usuario = await BaseDatosService.instancia.iniciarSesion(
        usuarioController.text,
        contrasenaController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HabitosPage(
            usuario: usuario,
            alCambiarAjustes: widget.alCambiarAjustes,
          ),
        ),
      );
    } catch (e) {
      if (mounted) mostrarMensaje(context, e);
    } finally {
      if (mounted) setState(() => entrando = false);
    }
  }

  Future<void> abrirRegistro() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RegistroPage(alCambiarAjustes: widget.alCambiarAjustes),
      ),
    );
    if (mounted) await comprobarUsuarios();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('HabitosApp')),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : errorCarga != null
          ? Center(child: Text(errorCarga!))
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: formulario,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.indigo,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (primeraCuenta)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Text(
                              'Crea la primera cuenta. Será la administradora de esta instalación.',
                            ),
                          ),
                        CampoTextoApp(
                          etiqueta: 'Usuario',
                          controller: usuarioController,
                          validador: obligatorio,
                          habilitado: !entrando,
                        ),
                        CampoTextoApp(
                          etiqueta: 'Contraseña',
                          controller: contrasenaController,
                          ocultar: true,
                          validador: obligatorio,
                          habilitado: !entrando,
                          alEnviar: (_) {
                            if (!entrando) entrar();
                          },
                        ),
                        BotonPrincipal(
                          texto: entrando ? 'Entrando...' : 'Entrar',
                          alPulsar: entrar,
                          habilitado: !entrando,
                        ),
                        TextButton(
                          onPressed: entrando ? null : abrirRegistro,
                          child: const Text('Crear cuenta'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
