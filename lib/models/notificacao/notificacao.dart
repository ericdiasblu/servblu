class Notificacao {
  final int? id;
  final String userId;
  final String mensagem;
  final DateTime dataEnvio;
  final bool lida;

  Notificacao({
    this.id,
    required this.userId,
    required this.mensagem,
    required this.dataEnvio,
    this.lida = false,
  });

  factory Notificacao.fromMap(Map<String, dynamic> m) => Notificacao(
    id: m['id'] as int,
    userId: m['id_usuario'] as String,
    mensagem: m['mensagem'] as String,
    dataEnvio: DateTime.parse(m['data_envio'] as String),
    lida: m['lida'] as bool,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'id_usuario': userId,
    'mensagem': mensagem,
    'data_envio': dataEnvio.toIso8601String(),
    'lida': lida,
  };
}
