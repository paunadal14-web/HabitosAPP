
import 'package:flutter/material.dart';
import 'principal_screen.dart';

class BienvenidaScreen extends StatefulWidget {
  const BienvenidaScreen({super.key});

  @override
  State<BienvenidaScreen> createState() => _BienvenidaScreenState();
}

class _BienvenidaScreenState extends State<BienvenidaScreen> {
  // Controladores de los campos de texto
  final nombreController = TextEditingController();
  final objetivoController = TextEditingController();

  // Liberamos los controladores
  @override
  void dispose() {
    nombreController.dispose();
    objetivoController.dispose();
    super.dispose();
  }

  // Pasamos los datos a la pantalla principal
  void comenzar() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrincipalScreen(
          nombreUsuario: nombreController.text,
          objetivoDiario: objetivoController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bienvenida'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'HabitosApp',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de usuario',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: objetivoController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Objetivo diario de hábitos',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),
              ElevatedButton(
                onPressed: comenzar,
                child: const Text('Comenzar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
