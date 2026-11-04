import 'package:flutter/material.dart';

import '../modelos/usuario.dart';
import '../servicios/base_datos_service.dart';
import '../servicios/preferencias_service.dart';
import '../widgets/dialogos.dart';
import '../widgets/campo_texto_app.dart';
import '../widgets/boton_principal.dart';

class AjustesPage extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback alCambiarAjustes;
  const AjustesPage({
    super.key,
    required this.usuario,
    required this.alCambiarAjustes,
  });

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  final preferencias = PreferenciasService.instancia;
  final objetivoController = TextEditingController();
  late bool oscuro;
  late bool ocultar;
  late double letra;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    oscuro = preferencias.oscuro;
    ocultar = preferencias.ocultarCompletados;
    letra = preferencias.tamanoLetra;
    objetivoController.text = preferencias
        .objetivo(widget.usuario.id!)
        .toString();
  }

  @override
  void dispose() {
    objetivoController.dispose();
    super.dispose();
  }

  Future<void> guardar() async {
    final objetivo = int.tryParse(objetivoController.text);
    if (objetivo == null || objetivo <= 0) {
      mostrarMensaje(context, 'El objetivo debe ser un número mayor que 0.');
      return;
    }
    setState(() => guardando = true);
    try {
      await preferencias.guardarObjetivo(widget.usuario.id!, objetivo);
      await preferencias.guardarAjustes(oscuro, letra, ocultar);
      widget.alCambiarAjustes();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e);
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  Future<void> borrarDatos() async {
    final confirmado = await confirmarBorrado(
      context,
      '¿Borrar todos los usuarios, hábitos, estadísticas y ajustes de esta instalación?',
    );
    if (!confirmado || !mounted) return;
    setState(() => guardando = true);
    try {
      await BaseDatosService.instancia.borrarTodo();
      await preferencias.borrarTodo();
      widget.alCambiarAjustes();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e);
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            title: const Text('Tema oscuro'),
            value: oscuro,
            onChanged: guardando
                ? null
                : (valor) => setState(() => oscuro = valor),
          ),
          Text('Tamaño de letra: ${(letra * 100).round()}%'),
          Slider(
            value: letra,
            min: 0.8,
            max: 1.4,
            divisions: 6,
            onChanged: guardando
                ? null
                : (valor) => setState(() => letra = valor),
          ),
          SwitchListTile(
            title: const Text('Ocultar hábitos completados hoy'),
            value: ocultar,
            onChanged: guardando
                ? null
                : (valor) => setState(() => ocultar = valor),
          ),
          CampoTextoApp(
            controller: objetivoController,
            tipoTeclado: TextInputType.number,
            etiqueta: 'Tu objetivo diario',
            habilitado: !guardando,
          ),
          const SizedBox(height: 24),
          BotonPrincipal(
            texto: guardando ? 'Guardando...' : 'Guardar ajustes',
            alPulsar: guardar,
            habilitado: !guardando,
          ),
          if (widget.usuario.esAdministrador) ...[
            const SizedBox(height: 30),
            OutlinedButton(
              onPressed: guardando ? null : borrarDatos,
              child: const Text('Borrar todos los datos'),
            ),
          ],
        ],
      ),
    );
  }
}
