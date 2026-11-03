import 'package:flutter/material.dart';

import '../services/base_datos_service.dart';
import '../widgets/dialogos.dart';
import 'bienvenida_screen.dart';
import 'principal_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback alCambiarAjustes;
  const LoginScreen({super.key, required this.alCambiarAjustes});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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

  Future<void> entrar() async {
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
          builder: (context) => PrincipalScreen(
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        primeraCuenta
                            ? 'Bienvenido a HabitosApp'
                            : 'Iniciar sesión',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (primeraCuenta)
                        const Text(
                          'Crea la primera cuenta. Será la administradora de esta instalación.',
                        ),
                      if (!primeraCuenta) ...[
                        TextField(
                          controller: usuarioController,
                          decoration: const InputDecoration(
                            labelText: 'Usuario',
                          ),
                        ),
                        TextField(
                          controller: contrasenaController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                          ),
                          onSubmitted: (_) {
                            if (!entrando) entrar();
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: entrando ? null : entrar,
                          child: Text(entrando ? 'Entrando...' : 'Entrar'),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: entrando
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BienvenidaScreen(
                                      alCambiarAjustes: widget.alCambiarAjustes,
                                    ),
                                  ),
                                );
                              },
                        child: const Text('Crear cuenta'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
