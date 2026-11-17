import 'package:flutter/material.dart';
class Editor extends StatelessWidget{

  TextEditingController controlador;
  String rotulo;
  String dica;
  IconData? icone;
  final String? Function(String?)? validador;

  Editor(this.controlador, this.rotulo, this.dica, {this.icone, this.validador}); // {} indica parâmetros nomeados

  @override
  Widget build(BuildContext context) {
    return  Padding(padding: EdgeInsets.all(16),
      child: TextFormField(
        controller: controlador,
        validator: (value) {
          if (value == null || value.isEmpty) return 'Campo obrigatório'; // regra geral
          if (validador != null) return validador!(value); // regra customizada
          if (value.length > 100) return 'Digite até 100 caracteres'; // regra default
          return null;
        },
        style: TextStyle(fontSize: 18),
        decoration: InputDecoration(
            icon: icone != null ? Icon(icone) : null,
            fillColor: Colors.white,
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
            labelText: rotulo,
            hintText: dica
        ),
      ),);
  }
}

