
import 'package:flutter/material.dart';

class EditarScreen extends StatefulWidget {
  final String nombreActual;
  final String colorActual;

  const EditarScreen({
    super.key,
    required this.nombreActual,
    required this.colorActual,
  });

  @override
  State<EditarScreen> createState() => _EditarScreenState();
}

class _EditarScreenState extends State<EditarScreen> {
  late TextEditingController nombreController;
  late String colorSeleccionado;

  @override
  void initState() {
    super.initState();

    // Cargamos los datos actuales
    nombreController = TextEditingController(
      text: widget.nombreActual,
    );
    colorSeleccionado = widget.colorActual;
  }

  @override
  void dispose() {
    nombreController.dispose();
    super.dispose();
  }

  // Guardamos y devolvemos los datos a la principal
  void guardar() {
    Navigator.pop(context, {
      'nombre': nombreController.text,
      'color': colorSeleccionado,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar hábito'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre del hábito',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Selecciona un color:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 15),

            // Botones para seleccionar el color
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      colorSeleccionado = 'Azul';
                    });
                  },
                  child: const Text('Azul'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      colorSeleccionado = 'Verde';
                    });
                  },
                  child: const Text('Verde'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      colorSeleccionado = 'Naranja';
                    });
                  },
                  child: const Text('Naranja'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Color seleccionado: $colorSeleccionado'),
            const SizedBox(height: 30),

            // Botones para guardar o cancelar
            Row(
              children: [
                ElevatedButton(
                  onPressed: guardar,
                  child: const Text('Guardar'),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
