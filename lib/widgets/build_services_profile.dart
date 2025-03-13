import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/servico.dart';

class BuildServicesProfile extends StatelessWidget {
  final String nomeServico;
  final String descServico;
  final Color corContainer;
  final Color corTexto;
  final String? idServico;
  final VoidCallback? onTap;

  const BuildServicesProfile({
    Key? key,
    required this.nomeServico,
    required this.descServico,
    required this.corContainer,
    required this.corTexto,
    this.idServico,
    this.onTap,
  }) : super(key: key);

  // Construtor factory para criar a partir de um objeto Servico
  factory BuildServicesProfile.fromServico(Servico servico) {
    // Lista de cores para variar os cards
    final List<Color> cores = [
      Colors.purple.withOpacity(0.2),
      Colors.yellow.withOpacity(0.2),
      Colors.red.withOpacity(0.2),
      Colors.green.withOpacity(0.2),
      Colors.blue.withOpacity(0.2),
      Colors.orange.withOpacity(0.2),
    ];

    // Selecionar uma cor baseada no nome do serviço (para ter variedade mas ser consistente)
    final int indice = servico.nome.length % cores.length;
    final Color corContainer = cores[indice];
    final Color corTexto = cores[indice].withOpacity(1.0);

    return BuildServicesProfile(
      idServico: servico.idServico,
      nomeServico: servico.nome,
      descServico: servico.descricao,
      corContainer: corContainer,
      corTexto: corTexto,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 230,
        height: 110,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: corContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nomeServico,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: corTexto,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              descServico,
              style: TextStyle(
                color: Colors.black.withOpacity(0.7),
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}