import 'package:flutter/material.dart';

class CampoTextoApp extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controller;
  final bool ocultar;
  final TextInputType tipoTeclado;
  final String? Function(String?)? validador;
  final ValueChanged<String>? alEnviar;
  final int maxLineas;
  final bool habilitado;
  final String? pista;
  final String? ayuda;

  const CampoTextoApp({
    super.key,
    required this.etiqueta,
    required this.controller,
    this.ocultar = false,
    this.tipoTeclado = TextInputType.text,
    this.validador,
    this.alEnviar,
    this.maxLineas = 1,
    this.habilitado = true,
    this.pista,
    this.ayuda,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: ocultar,
        keyboardType: tipoTeclado,
        validator: validador,
        onFieldSubmitted: alEnviar,
        maxLines: ocultar ? 1 : maxLineas,
        enabled: habilitado,
        decoration: InputDecoration(
          labelText: etiqueta,
          hintText: pista,
          helperText: ayuda,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
