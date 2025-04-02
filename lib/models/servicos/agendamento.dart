// models/agendamento.dart
class Agendamento {
  final String idAgendamento;
  final String idCliente;
  final String idPrestador;
  final String idServico;
  final String idHorario; // FK para horarios_disponiveis.id_horario
  final String dataServico; // Data específica (ex.: '2025-03-12')
  final String status; // 'pendente', 'aguardando confirmação', 'confirmado', 'concluído', 'cancelado'
  final bool isPix;

  Agendamento({
    required this.idAgendamento,
    required this.idCliente,
    required this.idPrestador,
    required this.idServico,
    required this.idHorario,
    required this.dataServico,
    this.status = 'pendente',
    this.isPix = false,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    return Agendamento(
      idAgendamento: json['id_agendamento'],
      idCliente: json['id_cliente'],
      idPrestador: json['id_prestador'],
      idServico: json['id_servico'],
      idHorario: json['horario'], // refere-se ao id do horário escolhido
      dataServico: json['data_servico'],
      status: json['status'],
      isPix: json['is_pix'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_agendamento': idAgendamento,
      'id_cliente': idCliente,
      'id_prestador': idPrestador,
      'id_servico': idServico,
      'horario': idHorario,
      'data_servico': dataServico,
      'status': status,
      'is_pix': isPix,
    };
  }
}
