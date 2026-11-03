import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../services/base_datos_service.dart';
import '../services/preferencias_service.dart';
import '../widgets/dialogos.dart';
import '../widgets/formulario_usuario.dart';
import 'principal_screen.dart';

class BienvenidaScreen extends StatefulWidget {
  final VoidCallback alCambiarAjustes;
  const BienvenidaScreen({super.key, required this.alCambiarAjustes});

  @override
  State<BienvenidaScreen> createState() => _BienvenidaScreenState();
}

class _BienvenidaScreenState extends State<BienvenidaScreen> {
  bool guardando = false;

  Future<void> registrar(Usuario datos, String contrasena, int objetivo) async {
    setState(() => guardando = true);
    try {
      final usuario = await BaseDatosService.instancia.registrar(
        datos,
        contrasena,
      );
      await PreferenciasService.instancia.guardarObjetivo(
        usuario.id!,
        objetivo,
      );
      if (!mounted) return;
      // Quitamos también el login para que atrás no vuelva al registro.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => PrincipalScreen(
            usuario: usuario,
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
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: FormularioUsuario(
          pedirObjetivo: true,
          guardando: guardando,
          alGuardar: registrar,
        ),
      ),
    );
  }
}
