import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart'; // Para formatação de texto

class InputField extends StatelessWidget {
  final IconData? icon;
  final String hintText;
  final TextEditingController? controller; // Controlador de texto padrão
  final MaskedTextController? maskedController; // Controlador de máscara
  final EdgeInsetsGeometry? margin; // Parâmetro opcional
  final bool obscureText;
  final bool isDescription; // Novo parâmetro

  const InputField({
    Key? key,
    this.icon,
    required this.hintText,
    required this.obscureText,
    this.controller, // Controlador opcional
    this.maskedController, // Controlador de máscara opcional
    this.margin,
    this.isDescription = false, // Padrão: campo normal
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF017DFE),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      margin: margin ?? const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: isDescription ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF017DFE)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              obscureText: obscureText,
              controller: maskedController ?? controller, // Usar o controlador de máscara se disponível
              maxLines: isDescription ? 5 : 1, // Ajusta o tamanho do campo
              decoration: InputDecoration(
                hintText: hintText,
                border: InputBorder.none,
                hintStyle: const TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
