import 'package:flutter/material.dart';
import 'package:servblu/widgets/build_header.dart';

class CarteiraScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BuildHeader(
            title: 'Minha Carteira',
            backPage: false,
            refresh: false,
          ),
          // Conteúdo abaixo removido intencionalmente
        ],
      ),
    );
  }
}
