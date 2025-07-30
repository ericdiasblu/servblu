class PixQRCode {
  final String qrCodeText;
  final String qrCodeImage;

  PixQRCode({required this.qrCodeText, required this.qrCodeImage});

  factory PixQRCode.fromJson(Map<String, dynamic> json) {
    return PixQRCode(
      qrCodeText: json['qrcode'],
      qrCodeImage: json['imagemQrcode'],
    );
  }
}