class Agendamento {
  final String idAgendamento;
  final String idCliente;
  final String idPrestador;
  final String idServico;
  final dynamic idHorario; // Pode ser int ou String
  final String dataServico;
  final String status;
  final bool isPix;
  final String? formaPagamento;
  final String? motivoRecusa; // Novo campo para o motivo da recusa
  String? nomeServico;
  String? nomePrestador;
  String? nomeCliente;

  Agendamento({
    required this.idAgendamento,
    required this.idCliente,
    required this.idPrestador,
    required this.idServico,
    required this.idHorario,
    required this.dataServico,
    this.status = 'solicitado',
    this.isPix = false,
    this.formaPagamento,
    this.motivoRecusa,
    this.nomeServico,
    this.nomePrestador,
    this.nomeCliente,
  });

  factory Agendamento.fromJson(Map<String, dynamic> json) {
    return Agendamento(
      idAgendamento: json['id_agendamento']?.toString() ?? '',
      idCliente: json['id_cliente']?.toString() ?? '',
      idPrestador: json['id_prestador']?.toString() ?? '',
      idServico: json['id_servico']?.toString() ?? '',
      idHorario: json['horario'], // Mantém o tipo original
      dataServico: json['data_servico']?.toString() ?? '',
      status: json['status']?.toString() ?? 'solicitado',
      isPix: json['is_pix'] == true,
      formaPagamento: json['forma_pagamento']?.toString(),
      motivoRecusa: json['motivo_recusa']?.toString(),
      nomeServico: json['nome_servico']?.toString(),
      nomePrestador: json['nome_prestador']?.toString(),
      nomeCliente: json['nome_cliente']?.toString(),
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
      'forma_pagamento': formaPagamento,
      'motivo_recusa': motivoRecusa,
    };
  }
}