import 'package:flutter/material.dart';

import '../models/habito.dart';
import '../models/usuario.dart';
import '../services/base_datos_service.dart';
import '../widgets/dialogos.dart';

class EditarScreen extends StatefulWidget {
  final Usuario usuario;
  final Habito? habito;
  final List<Usuario> usuarios;
  const EditarScreen({
    super.key,
    required this.usuario,
    this.habito,
    required this.usuarios,
  });

  @override
  State<EditarScreen> createState() => _EditarScreenState();
}

class _EditarScreenState extends State<EditarScreen> {
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
              TextFormField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del hábito',
                ),
                validator: (valor) => valor == null || valor.trim().isEmpty
                    ? 'Escribe un nombre.'
                    : null,
              ),
              const SizedBox(height: 20),
              const Text('Selecciona un color:'),
              Wrap(
                spacing: 8,
                children: [
                  for (final color in ['Azul', 'Verde', 'Naranja'])
                    ChoiceChip(
                      label: Text(color),
                      selected: colorSeleccionado == color,
                      onSelected: guardando
                          ? null
                          : (_) => setState(() => colorSeleccionado = color),
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
                TextFormField(
                  controller: fechasController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Fechas completadas',
                    hintText: '2026-11-01, 2026-11-02',
                    helperText: 'Separa las fechas con comas.',
                  ),
                  validator: validarFechas,
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: guardando ? null : guardar,
                child: Text(guardando ? 'Guardando...' : 'Guardar'),
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
