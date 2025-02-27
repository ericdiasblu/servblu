import 'package:flutter/material.dart';

class BuildServicesProfile extends StatelessWidget {
  final String? nomeServico;
  final String? descServico;
  final Color corContainer;
  final Color corTexto;

  const BuildServicesProfile(
      {super.key, required this.nomeServico, required this.descServico, required this.corContainer, required this.corTexto});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: 0.05,
          child: Container(
            width: 190,
            height: 100,
            decoration: BoxDecoration(
              color: corContainer,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.all(20),
          width: 190, // Definindo a largura para o Container
          height: 110, // Definindo a altura para o Container
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.only(bottom: 2),
                child: Text(
                  "$nomeServico",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: corTexto,
                  ),
                ),
              ),
              // Remover SizedBox e usar o Container diretamente
              Container(
                // Definindo largura e permitindo quebra de linha
                width: 190,
                child: Text(
                  "$descServico",
                  style: TextStyle(
                    fontSize: 13,
                    color: corTexto,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  // Use ellipsis para mostrar "..."
                  softWrap: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
