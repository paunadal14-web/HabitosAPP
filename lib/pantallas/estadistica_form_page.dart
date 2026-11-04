import 'package:flutter/material.dart';

import '../modelos/habito.dart';
import '../modelos/estadistica.dart';
import '../servicios/base_datos_service.dart';
import '../widgets/dialogos.dart';
import '../widgets/campo_texto_app.dart';
import '../widgets/boton_principal.dart';

class EstadisticaFormPage extends StatefulWidget {
  final Estadistica? estadistica;
  final List<Habito> habitos;
  const EstadisticaFormPage({
    super.key,
    this.estadistica,
    required this.habitos,
  });

  @override
  State<EstadisticaFormPage> createState() => _EstadisticaFormPageState();
}

class _EstadisticaFormPageState extends State<EstadisticaFormPage> {
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
              CampoTextoApp(
                controller: rachaController,
                tipoTeclado: TextInputType.number,
                etiqueta: 'Racha actual',
                validador: validarNumero,
                habilitado: !guardando,
              ),
              CampoTextoApp(
                controller: totalController,
                tipoTeclado: TextInputType.number,
                etiqueta: 'Total de días completados',
                validador: validarNumero,
                habilitado: !guardando,
              ),
              const SizedBox(height: 20),
              const Text(
                'Al marcar un día o cambiar las fechas del hábito, los números se volverán a calcular con su historial.',
              ),
              const SizedBox(height: 20),
              BotonPrincipal(
                texto: guardando ? 'Guardando...' : 'Guardar estadística',
                alPulsar: guardar,
                habilitado: !guardando,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
