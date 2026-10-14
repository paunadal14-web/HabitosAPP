
import 'package:flutter/material.dart';
import 'editar_screen.dart';

class PrincipalScreen extends StatefulWidget {
  final String nombreUsuario;
  final String objetivoDiario;

  const PrincipalScreen({
    super.key,
    required this.nombreUsuario,
    required this.objetivoDiario,
  });

  @override
  State<PrincipalScreen> createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  // Datos del hábito de ejemplo
  String nombreHabito = 'Beber agua';
  String colorHabito = 'Azul';

  // Abrimos la pantalla de edición
  Future<void> editarHabito() async {
    final resultado = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => EditarScreen(
          nombreActual: nombreHabito,
          colorActual: colorHabito,
        ),
      ),
    );

    if (!mounted) return;

    // Si hemos guardado, actualizamos los datos
    if (resultado != null) {
      setState(() {
        nombreHabito = resultado['nombre']!;
        colorHabito = resultado['color']!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantalla principal'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${widget.nombreUsuario}',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 10),
            Text('Objetivo diario: ${widget.objetivoDiario}'),
            const SizedBox(height: 30),

            // Ficha del hábito
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop),
                      const SizedBox(width: 10),
                      Text(
                        nombreHabito,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text('Color: $colorHabito'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: editarHabito,
                    child: const Text('Editar hábito'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
