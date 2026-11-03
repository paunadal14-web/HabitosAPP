import 'package:flutter/material.dart';

import '../models/usuario.dart';
import '../models/habito.dart';
import '../services/base_datos_service.dart';
import '../services/preferencias_service.dart';
import '../widgets/dialogos.dart';
import 'editar_screen.dart';
import 'login_screen.dart';
import 'usuarios_screen.dart';
import 'estadisticas_screen.dart';
import 'ajustes_screen.dart';

class PrincipalScreen extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback alCambiarAjustes;
  const PrincipalScreen({
    super.key,
    required this.usuario,
    required this.alCambiarAjustes,
  });

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen>
    with WidgetsBindingObserver {
  final baseDatos = BaseDatosService.instancia;
  final preferencias = PreferenciasService.instancia;
  late Usuario usuario;
  List<Habito> habitos = [];
  List<Usuario> usuarios = [];
  bool cargando = true;
  bool ocupado = false;
  String? errorCarga;

  @override
  void initState() {
    super.initState();
    usuario = widget.usuario;
    WidgetsBinding.instance.addObserver(this);
    cargar();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState estado) {
    // Al volver a la app, comprobamos de nuevo qué hábitos están hechos hoy.
    if (estado == AppLifecycleState.resumed) cargar();
  }

  Future<void> cargar() async {
    try {
      final actual = await baseDatos.usuarioActual();
      final lista = await baseDatos.obtenerHabitos();
      final listaUsuarios = actual.esAdministrador
          ? await baseDatos.obtenerUsuarios()
          : <Usuario>[];
      if (!mounted) return;
      setState(() {
        usuario = actual;
        habitos = lista;
        usuarios = listaUsuarios;
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

  void salir() {
    baseDatos.cerrarSesion();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LoginScreen(alCambiarAjustes: widget.alCambiarAjustes),
      ),
      (ruta) => false,
    );
  }

  Future<void> editarHabito([Habito? habito]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditarScreen(usuario: usuario, habito: habito, usuarios: usuarios),
      ),
    );
    if (mounted) await cargar();
  }

  Future<void> marcar(Habito habito, bool completado) async {
    setState(() => ocupado = true);
    try {
      await baseDatos.marcarHoy(habito.id!, completado);
      await cargar();
    } catch (e) {
      if (mounted) mostrarMensaje(context, e);
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  Future<void> borrar(Habito habito) async {
    final confirmado = await confirmarBorrado(
      context,
      '¿Borrar "${habito.nombre}" y sus estadísticas?',
    );
    if (!confirmado || !mounted) return;
    setState(() => ocupado = true);
    try {
      await baseDatos.borrarHabito(habito.id!);
      await cargar();
    } catch (e) {
      if (mounted) mostrarMensaje(context, e);
    } finally {
      if (mounted) setState(() => ocupado = false);
    }
  }

  Future<void> abrirUsuarios() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const UsuariosScreen()),
    );
    if (!mounted) return;
    try {
      await baseDatos.usuarioActual();
      await cargar();
    } catch (e) {
      if (mounted) salir();
    }
  }

  Future<void> abrirAjustes() async {
    final borrado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AjustesScreen(
          usuario: usuario,
          alCambiarAjustes: widget.alCambiarAjustes,
        ),
      ),
    );
    if (!mounted) return;
    if (borrado == true) {
      salir();
    } else {
      setState(() {});
    }
  }

  Color colorDelHabito(String color) {
    if (color == 'Verde') return Colors.green;
    if (color == 'Naranja') return Colors.orange;
    return Colors.blue;
  }

  String nombreDelUsuario(int id) {
    for (final persona in usuarios) {
      if (persona.id == id) return persona.usuario;
    }
    return usuario.usuario;
  }

  @override
  Widget build(BuildContext context) {
    var completados = 0;
    final visibles = <Habito>[];
    for (final habito in habitos) {
      if (habito.usuarioId == usuario.id && habito.completadoHoy) completados++;
      if (!preferencias.ocultarCompletados || !habito.completadoHoy) {
        visibles.add(habito);
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('HabitosApp'),
        actions: [
          IconButton(
            tooltip: 'Estadísticas',
            icon: const Icon(Icons.bar_chart),
            onPressed: ocupado
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EstadisticasScreen(usuario: usuario),
                    ),
                  ),
          ),
          if (usuario.esAdministrador)
            IconButton(
              tooltip: 'Usuarios',
              icon: const Icon(Icons.people),
              onPressed: ocupado ? null : abrirUsuarios,
            ),
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings),
            onPressed: ocupado ? null : abrirAjustes,
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: ocupado ? null : salir,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Crear hábito',
        onPressed: cargando || ocupado ? null : () => editarHabito(),
        child: const Icon(Icons.add),
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : errorCarga != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorCarga!),
                  TextButton(
                    onPressed: cargar,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: cargar,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
                children: [
                  Text(
                    'Hola, ${usuario.nombre}',
                    style: const TextStyle(fontSize: 24),
                  ),
                  Text(
                    'Tu progreso de hoy: $completados de ${preferencias.objetivo(usuario.id!)} hábitos',
                  ),
                  if (usuario.esAdministrador)
                    const Text(
                      'Administrador: se muestran los hábitos de todos los usuarios.',
                    ),
                  const SizedBox(height: 20),
                  if (visibles.isEmpty)
                    Text(
                      habitos.isEmpty
                          ? 'Todavía no hay hábitos. Pulsa + para crear uno.'
                          : 'No hay hábitos pendientes para mostrar.',
                    ),
                  for (final habito in visibles)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                habito.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              secondary: Icon(
                                Icons.circle,
                                color: colorDelHabito(habito.color),
                              ),
                              value: habito.completadoHoy,
                              onChanged: ocupado
                                  ? null
                                  : (valor) => marcar(habito, valor!),
                            ),
                            Text('Color: ${habito.color}'),
                            if (usuario.esAdministrador)
                              Text(
                                'Usuario: ${nombreDelUsuario(habito.usuarioId)}',
                              ),
                            Text(
                              habito.fechasCompletadas.isEmpty
                                  ? 'Sin días completados'
                                  : 'Fechas: ${habito.fechasCompletadas.join(', ')}',
                            ),
                            Wrap(
                              spacing: 12,
                              children: [
                                TextButton(
                                  onPressed: ocupado
                                      ? null
                                      : () => editarHabito(habito),
                                  child: const Text('Editar'),
                                ),
                                TextButton(
                                  onPressed: ocupado
                                      ? null
                                      : () => borrar(habito),
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
            ),
    );
  }
}
