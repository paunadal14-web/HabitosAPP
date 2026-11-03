import 'package:flutter/material.dart';

import '../models/habito.dart';
import '../models/estadistica.dart';
import '../services/base_datos_service.dart';
import '../widgets/dialogos.dart';

class EstadisticaFormScreen extends StatefulWidget {
  final Estadistica? estadistica;
  final List<Habito> habitos;
  const EstadisticaFormScreen({
    super.key,
    this.estadistica,
    required this.habitos,
  });

  @override
  State<EstadisticaFormScreen> createState() => _EstadisticaFormScreenState();
}

class _EstadisticaFormScreenState extends State<EstadisticaFormScreen> {
  final formulario = GlobalKey<FormState>();
  final rachaController = TextEditingController();
  final totalController = TextEditingController();
  int? habitoId;
  bool guardando = false;

  @override
  void initState() {
    super.initState();
    habitoId = widget.estadistica?.habitoId ?? widget.habitos.firstOrNull?.id;
    rachaController.text = (widget.estadistica?.rachaActual ?? 0).toString();
    totalController.text = (widget.estadistica?.totalDias ?? 0).toString();
  }

  @override
  void dispose() {
    rachaController.dispose();
    totalController.dispose();
    super.dispose();
  }

  String? validarNumero(String? valor) {
    final numero = int.tryParse(valor ?? '');
    return numero == null || numero < 0
        ? 'Escribe un número igual o mayor que 0.'
        : null;
  }

  Future<void> guardar() async {
    if (!formulario.currentState!.validate()) return;
    final racha = int.parse(rachaController.text);
    final total = int.parse(totalController.text);
    if (racha > total) {
      mostrarMensaje(context, 'La racha no puede superar el total de días.');
      return;
    }
    setState(() => guardando = true);
    try {
      await BaseDatosService.instancia.guardarEstadistica(
        Estadistica(
          id: widget.estadistica?.id,
          habitoId: habitoId!,
          rachaActual: racha,
          totalDias: total,
        ),
      );
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
        title: Text(
          widget.estadistica == null
              ? 'Crear estadística'
              : 'Editar estadística',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formulario,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<int>(
                initialValue: habitoId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Hábito'),
                items: widget.habitos
                    .map(
                      (habito) => DropdownMenuItem(
                        value: habito.id!,
                        child: Text(
                          '#${habito.id} ${habito.nombre} (usuario ${habito.usuarioId})',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: guardando
                    ? null
                    : (valor) => setState(() => habitoId = valor),
                validator: (valor) =>
                    valor == null ? 'Selecciona un hábito.' : null,
              ),
              TextFormField(
                controller: rachaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Racha actual'),
                validator: validarNumero,
              ),
              TextFormField(
                controller: totalController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total de días completados',
                ),
                validator: validarNumero,
              ),
              const SizedBox(height: 20),
              const Text(
                'Al marcar un día o cambiar las fechas del hábito, los números se volverán a calcular con su historial.',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: guardando ? null : guardar,
                child: Text(guardando ? 'Guardando...' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
