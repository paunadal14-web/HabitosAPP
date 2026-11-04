import 'package:flutter/material.dart';

import '../modelos/usuario.dart';
import '../modelos/habito.dart';
import '../servicios/base_datos_service.dart';
import '../servicios/preferencias_service.dart';
import '../widgets/dialogos.dart';
import 'editar_habito_page.dart';
import 'login_page.dart';
import 'administracion_page.dart';
import '../widgets/tarjeta_habito.dart';
import 'estadisticas_page.dart';
import 'ajustes_page.dart';

class HabitosPage extends StatefulWidget {
  final Usuario usuario;
  final bool administracion;
  final VoidCallback alCambiarAjustes;
  const HabitosPage({
    super.key,
    required this.usuario,
    this.administracion = false,
    required this.alCambiarAjustes,
  });

  @override
  State<HabitosPage> createState() => _HabitosPageState();
}

class _HabitosPageState extends State<HabitosPage> with WidgetsBindingObserver {
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
      final lista = await baseDatos.obtenerHabitos(
        soloPropios: !widget.administracion,
      );
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
            LoginPage(alCambiarAjustes: widget.alCambiarAjustes),
      ),
      (ruta) => false,
    );
  }

  Future<void> editarHabito([Habito? habito]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditarHabitoPage(
          usuario: usuario,
          habito: habito,
          usuarios: usuarios,
        ),
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

  Future<void> abrirAdministracion() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AdministracionPage(alCambiarAjustes: widget.alCambiarAjustes),
      ),
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
        builder: (context) => AjustesPage(
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
        title: Text(
          widget.administracion ? 'Todos los hábitos' : 'Mis hábitos',
        ),
        actions: [
          IconButton(
            tooltip: 'Estadísticas',
            icon: const Icon(Icons.bar_chart),
            onPressed: ocupado
                ? null
                : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EstadisticasPage(
                        usuario: usuario,
                        administracion: widget.administracion,
                      ),
                    ),
                  ),
          ),
          if (usuario.esAdministrador && !widget.administracion)
            IconButton(
              tooltip: 'Administración',
              icon: const Icon(Icons.admin_panel_settings),
              onPressed: ocupado ? null : abrirAdministracion,
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
                  if (widget.administracion)
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
                    TarjetaHabito(
                      nombre: habito.nombre,
                      color: colorDelHabito(habito.color),
                      completadoHoy: habito.completadoHoy,
                      detalle: widget.administracion
                          ? 'Usuario: ${nombreDelUsuario(habito.usuarioId)}'
                          : 'Días registrados: ${habito.fechasCompletadas.length}',
                      habilitado: !ocupado,
                      alCompletar: (valor) => marcar(habito, valor),
                      alEditar: () => editarHabito(habito),
                      alEliminar: () => borrar(habito),
                    ),
                ],
              ),
            ),
    );
  }
}
