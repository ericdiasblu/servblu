class PixCharge {
  final String txid;
  final String status;
  final String locationId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final double amount;
  final String description;
  final String? qrCodeImage;
  final String? qrCodeText;

  PixCharge({
    required this.txid,
    required this.status,
    required this.locationId,
    required this.createdAt,
    required this.expiresAt,
    required this.amount,
    required this.description,
    this.qrCodeImage,
    this.qrCodeText,
  });

  factory PixCharge.fromJson(Map<String, dynamic> json) {
    // Parse da data de criação e conversão para milissegundos
    final createdAt = DateTime.parse(json['calendario']['criacao']);
    final createdAtMs = createdAt.millisecondsSinceEpoch;

    // Converte a expiração para num e multiplica por 1000, em seguida, converte para int
    final expirationMs = ((json['calendario']['expiracao'] as num) * 1000).toInt();

    return PixCharge(
      txid: json['txid'],
      status: json['status'],
      locationId: json['loc']['id'].toString(),
      createdAt: createdAt,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(createdAtMs + expirationMs),
      amount: double.parse(json['valor']['original']),
      description: json['solicitacaoPagador'] ?? '',
      qrCodeText: null,
      qrCodeImage: null,
    );
  }
}