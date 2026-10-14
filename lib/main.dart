
import 'package:flutter/material.dart';
import 'screens/bienvenida_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Widget principal de la aplicación
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HabitosApp',
      theme: ThemeData(
        // Color principal de la aplicación
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
      ),
      home: const BienvenidaScreen(),
    );
  }
}
