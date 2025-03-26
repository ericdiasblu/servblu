class Notificacao {
  final int? id;
  final String idUsuario;
  final String mensagem;
  final bool lida;
  final DateTime dataEnvio;
  final String tipoNotificacao;

  Notificacao({
    this.id,
    required this.idUsuario,
    required this.mensagem,
    this.lida = false,
    required this.dataEnvio,
    required this.tipoNotificacao,
  });

  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: json['id'],
      idUsuario: json['id_usuario'],
      mensagem: json['mensagem'],
      lida: json['lida'] ?? false,
      dataEnvio: DateTime.parse(json['data_envio']),
      tipoNotificacao: json['tipo_notificacao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'mensagem': mensagem,
      'lida': lida,
      'data_envio': dataEnvio.toIso8601String(),
      'tipo_notificacao': tipoNotificacao,
    };
  }
}