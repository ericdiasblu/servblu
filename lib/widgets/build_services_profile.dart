import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/servico.dart';
import 'package:servblu/utils/navigation_helper.dart';

class BuildServicesProfile extends StatelessWidget {
  final String nomeServico;
  final String descServico;
  final String? idServico;
  final String? imgServico;
  final VoidCallback? onTap;
  final Servico? servico;
  final VoidCallback? onServiceDeleted;

  const BuildServicesProfile({
    Key? key,
    required this.nomeServico,
    required this.descServico,
    this.imgServico,
    this.idServico,
    this.onTap,
    this.servico,
    this.onServiceDeleted,
  }) : super(key: key);

  // Construtor factory para criar a partir de um objeto Servico
  factory BuildServicesProfile.fromServico(
      Servico servico,
      {VoidCallback? onServiceDeleted}
      ) {
    return BuildServicesProfile(
      idServico: servico.idServico,
      nomeServico: servico.nome,
      descServico: servico.descricao ?? "Sem descrição",
      imgServico: servico.imgServico,
      servico: servico,
      onServiceDeleted: onServiceDeleted,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? (servico != null
          ? () async {
        final wasDeleted = await NavigationHelper.navigateToServiceDetails(
            context,
            servico!
        );
        if (wasDeleted == true && onServiceDeleted != null) {
          onServiceDeleted!();
        }
      }
          : null),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 209,
              height: 130,
              child: imgServico != null && imgServico!.isNotEmpty
                  ? Image.network(
                imgServico!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.image_not_supported, size: 50);
                },
              )
                  : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: 210,
            child: Center(
              child: Text(
                nomeServico,
                style: const TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ),
          SizedBox(
            width: 200,
            child: Center(
              child: Text(
                descServico,
                style: const TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}