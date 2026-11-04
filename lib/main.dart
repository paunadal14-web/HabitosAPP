import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'pantallas/login_page.dart';
import 'servicios/base_datos_service.dart';
import 'servicios/preferencias_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // En Windows y Linux necesitamos esta versión de SQLite.
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final preferencias = PreferenciasService.instancia;
  bool cargando = true;
  String? error;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    try {
      if (kIsWeb) {
        throw Exception(
          'Abre HabitosApp en Android o Windows para usar la base de datos local.',
        );
      }
      await preferencias.cargar();
      await BaseDatosService.instancia.abrir();
      await preferencias.registrarApertura();
      if (!mounted) return;
      setState(() => cargando = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        cargando = false;
        error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void actualizarAjustes() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final preparada = !cargando && error == null;
    return MaterialApp(
      title: 'HabitosApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: preparada && preferencias.oscuro
          ? ThemeMode.dark
          : ThemeMode.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            preparada ? preferencias.tamanoLetra : 1.0,
          ),
        ),
        child: child!,
      ),
      home: cargando
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : error != null
          ? Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(error!),
                ),
              ),
            )
          : LoginPage(alCambiarAjustes: actualizarAjustes),
    );
  }
}
