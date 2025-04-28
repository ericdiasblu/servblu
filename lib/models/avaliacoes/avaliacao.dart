/* 
enviarAvaliacao(Avaliacao avaliacao)
Descrição: Registra a avaliação feita pelo contratante após a execução do serviço,
salvando nota e comentário.

listarAvaliacoesPorPrestador(int idPrestador)
Descrição: Retorna todas as avaliações recebidas por um prestador para exibição em
seu perfil.
*/

import 'package:uuid/uuid.dart';

class Avaliacao {
  final String idAvaliacao;
  final String idAgendamento;
  final double nota;
  final String comentario;
  final DateTime dataAvaliacao;
  String? nomeCliente; // Campo adicional para exibição
  String? nomePrestador; // Campo adicional para exibição

  Avaliacao({
    String? idAvaliacao,
    required this.idAgendamento,
    required this.nota,
    required this.comentario,
    DateTime? dataAvaliacao,
    this.nomeCliente,
    this.nomePrestador,
  })  : this.idAvaliacao = idAvaliacao ?? const Uuid().v4(),
        this.dataAvaliacao = dataAvaliacao ?? DateTime.now();

  // Converte objeto para JSON para armazenar no Supabase
  Map<String, dynamic> toJson() {
    return {
      'id_avaliacao': idAvaliacao,
      'id_agendamento': idAgendamento,
      'nota': nota,
      'comentario': comentario,
      'data_avaliacao': dataAvaliacao.toIso8601String(),
    };
  }

  // Cria objeto a partir de resposta JSON do Supabase
  factory Avaliacao.fromJson(Map<String, dynamic> json) {
    return Avaliacao(
      idAvaliacao: json['id_avaliacao'],
      idAgendamento: json['id_agendamento'],
      nota: json['nota'] is int ? json['nota'].toDouble() : json['nota'],
      comentario: json['comentario'] ?? '',
      dataAvaliacao: json['data_avaliacao'] != null
          ? DateTime.parse(json['data_avaliacao'])
          : DateTime.now(),
    );
  }

  // Verifica se a nota está dentro do intervalo permitido (1-5)
  static bool isNotaValida(double nota) {
    return nota >= 1.0 && nota <= 5.0;
  }
}
