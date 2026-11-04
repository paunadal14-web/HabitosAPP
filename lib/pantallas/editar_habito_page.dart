import 'package:flutter/material.dart';

import '../modelos/habito.dart';
import '../modelos/usuario.dart';
import '../servicios/base_datos_service.dart';
import '../widgets/dialogos.dart';
import '../widgets/campo_texto_app.dart';
import '../widgets/boton_principal.dart';

class EditarHabitoPage extends StatefulWidget {
  final Usuario usuario;
  final Habito? habito;
  final List<Usuario> usuarios;
  const EditarHabitoPage({
    super.key,
    required this.usuario,
    this.habito,
    required this.usuarios,
  });

  @override
  State<EditarHabitoPage> createState() => _EditarHabitoPageState();
}

class _EditarHabitoPageState extends State<EditarHabitoPage> {
  final formulario = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final fechasController = TextEditingController();
  String colorSeleccionado = 'Azul';
  late int usuarioId;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    nombreController.text = widget.habito?.nombre ?? '';
    fechasController.text = widget.habito?.fechasCompletadas.join(', ') ?? '';
    colorSeleccionado = widget.habito?.color ?? 'Azul';
    usuarioId = widget.habito?.usuarioId ?? widget.usuario.id!;
  }

  @override
  void dispose() {
    nombreController.dispose();
    fechasController.dispose();
    super.dispose();
  }

  String? validarFechas(String? texto) {
    if (texto == null || texto.trim().isEmpty) return null;
    for (final parte in texto.split(',')) {
      final valor = parte.trim();
      final fecha = DateTime.tryParse(valor);
      if (fecha == null ||
          Habito.fechaDelDia(fecha) != valor ||
          valor.compareTo(Habito.fechaDelDia(DateTime.now())) > 0) {
        return 'Usa fechas válidas hasta hoy: 2026-11-01, 2026-11-02';
      }
    }
    return null;
  }

  Future<void> guardar() async {
    if (!formulario.currentState!.validate()) return;
    setState(() => guardando = true);
    try {
      var fechas = widget.habito?.fechasCompletadas ?? <String>[];
      if (widget.usuario.esAdministrador) {
        fechas = [];
        for (final parte in fechasController.text.split(',')) {
          if (parte.trim().isNotEmpty && !fechas.contains(parte.trim())) {
            fechas.add(parte.trim());
          }
        }
        fechas.sort();
      }
      final habito = Habito(
        id: widget.habito?.id,
        usuarioId: usuarioId,
        nombre: nombreController.text,
        color: colorSeleccionado,
        fechasCompletadas: fechas,
      );
      await BaseDatosService.instancia.guardarHabito(habito);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) mostrarMensaje(context, e);
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const colores = {
      'Azul': Colors.blue,
      'Verde': Colors.green,
      'Naranja': Colors.orange,
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.habito == null ? 'Crear hábito' : 'Editar hábito'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CampoTextoApp(
                controller: nombreController,
                etiqueta: 'Nombre del hábito',
                validador: (valor) => valor == null || valor.trim().isEmpty
                    ? 'Escribe un nombre.'
                    : null,
                habilitado: !guardando,
              ),
              const SizedBox(height: 20),
              const Text('Selecciona un color:'),
              Wrap(
                spacing: 8,
                children: [
                  for (final color in colores.entries)
                    ChoiceChip(
                      avatar: Icon(Icons.circle, color: color.value, size: 16),
                      label: Text(color.key),
                      selected: colorSeleccionado == color.key,
                      onSelected: guardando
                          ? null
                          : (_) =>
                                setState(() => colorSeleccionado = color.key),
                    ),
                ],
              ),
              if (widget.usuario.esAdministrador) ...[
                const SizedBox(height: 20),
                DropdownButtonFormField<int>(
                  initialValue: usuarioId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Usuario del hábito',
                  ),
                  items: widget.usuarios
                      .map(
                        (usuario) => DropdownMenuItem(
                          value: usuario.id!,
                          child: Text(usuario.usuario),
                        ),
                      )
                      .toList(),
                  onChanged: (valor) => setState(() => usuarioId = valor!),
                ),
                const SizedBox(height: 16),
                CampoTextoApp(
                  controller: fechasController,
                  maxLineas: 3,
                  etiqueta: 'Fechas completadas',
                  pista: '2026-11-01, 2026-11-02',
                  ayuda: 'Separa las fechas con comas.',
                  validador: validarFechas,
                  habilitado: !guardando,
                ),
              ],
              const SizedBox(height: 24),
              BotonPrincipal(
                texto: guardando ? 'Guardando...' : 'Guardar hábito',
                alPulsar: guardar,
                habilitado: !guardando,
              ),
              TextButton(
                onPressed: guardando ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
