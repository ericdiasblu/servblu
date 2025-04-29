import 'package:flutter/material.dart';
import 'package:servblu/models/avaliacoes/avaliacao.dart';
import 'package:intl/intl.dart';

class AvaliacaoCard extends StatelessWidget {
  final Avaliacao avaliacao;
  final String? fotoPerfil;

  const AvaliacaoCard({
    Key? key,
    required this.avaliacao,
    this.fotoPerfil,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: fotoPerfil != null ? NetworkImage(fotoPerfil!) : null,
                  child: fotoPerfil == null ? Icon(Icons.person) : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        avaliacao.nomeCliente ?? 'Cliente',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          _buildStarRating(avaliacao.nota),
                          SizedBox(width: 8),
                          Text(
                            DateFormat('dd/MM/yyyy').format(avaliacao.dataAvaliacao),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (avaliacao.comentario.isNotEmpty) ...[
              SizedBox(height: 16),
              Text(
                avaliacao.comentario,
                style: TextStyle(
                  fontSize: 14,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    int fullStars = rating.floor();
    bool hasHalfStar = (rating - fullStars) >= 0.5;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: Color(0xFFFCD40E), size: 18);
        } else if (index == fullStars && hasHalfStar) {
          return Icon(Icons.star_half, color: Color(0xFFFCD40E), size: 18);
        } else {
          return Icon(Icons.star_border, color: Color(0xFFFCD40E), size: 18);
        }
      }),
    );
  }
}