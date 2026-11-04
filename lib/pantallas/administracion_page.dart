import 'package:flutter/material.dart';

import '../modelos/usuario.dart';
import '../servicios/base_datos_service.dart';
import '../widgets/boton_principal.dart';
import 'usuarios_page.dart';
import 'habitos_page.dart';
import 'estadisticas_page.dart';

class AdministracionPage extends StatefulWidget {
  final VoidCallback alCambiarAjustes;
  const AdministracionPage({super.key, required this.alCambiarAjustes});

  @override
  State<AdministracionPage> createState() => _AdministracionPageState();
}

class _AdministracionPageState extends State<AdministracionPage> {
  Usuario? administrador;
  String? error;

  @override
  void initState() {
    super.initState();
    comprobarAcceso();
  }

  Future<void> comprobarAcceso() async {
    try {
      final usuario = await BaseDatosService.instancia.usuarioActual();
      if (!usuario.esAdministrador) {
        throw Exception('Esta pantalla es solo para administradores.');
      }
      if (mounted) setState(() => administrador = usuario);
    } catch (e) {
      if (mounted) {
        setState(() {
          administrador = null;
          error = e.toString();
        });
      }
    }
  }

  Future<void> abrir(Widget pantalla) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => pantalla),
    );
    if (mounted) await comprobarAcceso();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = administrador;
    return Scaffold(
      appBar: AppBar(title: const Text('Administración')),
      body: error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(error!),
              ),
            )
          : usuario == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  size: 56,
                  color: Colors.indigo,
                ),
                const SizedBox(height: 16),
                Text(
                  'Administrador: ${usuario.usuario}',
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Desde aquí puedes consultar, crear, editar y eliminar los datos de cualquier cuenta.',
                ),
                const SizedBox(height: 24),
                BotonPrincipal(
                  texto: 'Gestionar usuarios',
                  alPulsar: () => abrir(const UsuariosPage()),
                ),
                BotonPrincipal(
                  texto: 'Gestionar hábitos',
                  alPulsar: () => abrir(
                    HabitosPage(
                      usuario: usuario,
                      administracion: true,
                      alCambiarAjustes: widget.alCambiarAjustes,
                    ),
                  ),
                ),
                BotonPrincipal(
                  texto: 'Gestionar estadísticas',
                  alPulsar: () => abrir(
                    EstadisticasPage(usuario: usuario, administracion: true),
                  ),
                ),
              ],
            ),
    );
  }
}
