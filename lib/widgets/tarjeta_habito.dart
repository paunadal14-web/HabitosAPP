import 'package:flutter/material.dart';

class TarjetaHabito extends StatelessWidget {
  final String nombre;
  final Color color;
  final bool completadoHoy;
  final IconData icono;
  final ValueChanged<bool> alCompletar;
  final VoidCallback alEditar;
  final VoidCallback alEliminar;
  final String? detalle;
  final bool habilitado;

  const TarjetaHabito({
    super.key,
    required this.nombre,
    required this.color,
    required this.completadoHoy,
    this.icono = Icons.check_circle_outline,
    required this.alCompletar,
    required this.alEditar,
    required this.alEliminar,
    this.detalle,
    this.habilitado = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icono, color: color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Checkbox(
                  value: completadoHoy,
                  activeColor: color,
                  onChanged: habilitado ? (valor) => alCompletar(valor!) : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              completadoHoy ? 'Completado hoy' : 'Pendiente hoy',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: completadoHoy ? Colors.green.shade700 : null,
              ),
            ),
            if (detalle != null) Text(detalle!),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: [
                TextButton.icon(
                  onPressed: habilitado ? alEditar : null,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: habilitado ? alEliminar : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Eliminar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
