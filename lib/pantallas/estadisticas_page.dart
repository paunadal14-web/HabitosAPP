import 'package:flutter/material.dart';

import '../modelos/usuario.dart';
import '../modelos/habito.dart';
import '../modelos/estadistica.dart';
import '../servicios/base_datos_service.dart';
import '../servicios/preferencias_service.dart';
import '../widgets/dialogos.dart';
import '../widgets/dato_estadistica.dart';
import 'estadistica_form_page.dart';

class EstadisticasPage extends StatefulWidget {
  final Usuario usuario;
  final bool administracion;
  const EstadisticasPage({
    super.key,
    required this.usuario,
    this.administracion = false,
  });

  @override
  State<EstadisticasPage> createState() => _EstadisticasPageState();
}

class _EstadisticasPageState extends State<EstadisticasPage> {
  final baseDatos = BaseDatosService.instancia;
  List<Estadistica> estadisticas = [];
  List<Habito> habitos = [];
  bool cargando = true;
  bool borrando = false;
  String? errorCarga;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    try {
      final listaHabitos = await baseDatos.obtenerHabitos(
        soloPropios: !widget.administracion,
      );
      final lista = await baseDatos.obtenerEstadisticas(
        soloPropios: !widget.administracion,
      );
      if (!mounted) return;
      setState(() {
        habitos = listaHabitos;
        estadisticas = lista;
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

  String nombreHabito(int id) {
    for (final habito in habitos) {
      if (habito.id == id) {
        return widget.usuario.esAdministrador && widget.administracion
            ? '${habito.nombre} (usuario ${habito.usuarioId})'
            : habito.nombre;
      }
    }
    return 'Hábito $id';
  }

  Future<void> editar([Estadistica? estadistica]) async {
    final disponibles = <Habito>[];
    for (final habito in habitos) {
      final yaExiste = estadisticas.any((fila) => fila.habitoId == habito.id);
      if (!yaExiste || estadistica?.habitoId == habito.id) {
        disponibles.add(habito);
      }
    }
    if (disponibles.isEmpty) {
      mostrarMensaje(
        context,
        'Todos los hábitos tienen estadísticas. Puedes editar las existentes.',
      );
      return;
    }
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EstadisticaFormPage(estadistica: estadistica, habitos: disponibles),
      ),
    );
    if (mounted) await cargar();
  }

  Future<void> borrar(Estadistica estadistica) async {
    final confirmado = await confirmarBorrado(
      context,
      '¿Borrar esta estadística? Se conserva el hábito y sus fechas.',
    );
    if (!confirmado || !mounted) return;
    setState(() => borrando = true);
    try {
      await baseDatos.borrarEstadistica(estadistica.id!);
      await cargar();
    } catch (e) {
      if (mounted) mostrarMensaje(context, e);
    } finally {
      if (mounted) setState(() => borrando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preferencias = PreferenciasService.instancia;
    final ultima =
        DateTime.tryParse(preferencias.ultimaApertura)
            ?.toLocal()
            .toString()
            .split('.')
            .first ??
        '-';
    return Scaffold(
      appBar: AppBar(title: const Text('Estadísticas')),
      floatingActionButton:
          widget.usuario.esAdministrador && widget.administracion
          ? FloatingActionButton(
              tooltip: 'Crear estadística',
              onPressed: cargando || borrando ? null : () => editar(),
              child: const Icon(Icons.add),
            )
          : null,
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : errorCarga != null
          ? Center(child: Text(errorCarga!))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
              children: [
                Text(
                  'Aperturas de esta instalación: ${preferencias.aperturas}',
                ),
                Text('Última apertura: $ultima'),
                const SizedBox(height: 20),
                if (estadisticas.isEmpty)
                  const Text('Todavía no hay estadísticas.'),
                for (final estadistica in estadisticas)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreHabito(estadistica.habitoId),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DatoEstadistica(
                            etiqueta: 'Racha actual',
                            valor: '${estadistica.rachaActual}',
                            icono: Icons.local_fire_department_outlined,
                          ),
                          DatoEstadistica(
                            etiqueta: 'Días completados',
                            valor: '${estadistica.totalDias}',
                            icono: Icons.event_available,
                            color: Colors.green,
                          ),
                          if (widget.usuario.esAdministrador &&
                              widget.administracion)
                            Wrap(
                              spacing: 12,
                              children: [
                                TextButton(
                                  onPressed: borrando
                                      ? null
                                      : () => editar(estadistica),
                                  child: const Text('Editar'),
                                ),
                                TextButton(
                                  onPressed: borrando
                                      ? null
                                      : () => borrar(estadistica),
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
    );
  }
}
