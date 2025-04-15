import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PixQRCodeWidget extends StatelessWidget {
  final String qrCodeImage;
  final String qrCodeText;

  const PixQRCodeWidget({
    Key? key,
    required this.qrCodeImage,
    required this.qrCodeText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(16),
          child: Image.memory(
            _convertBase64ToImage(qrCodeImage),
            width: 200,
            height: 200,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Ou copie o código PIX abaixo:',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(10),
            color: Colors.grey[200],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  qrCodeText,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: qrCodeText));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código PIX copiado!')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Uint8List _convertBase64ToImage(String base64String) {
    // Remove o cabeçalho "data:image/png;base64," se existir
    String sanitizedBase64 = base64String;
    if (base64String.contains(',')) {
      sanitizedBase64 = base64String.split(',')[1];
    }
    return base64Decode(sanitizedBase64);
  }
}