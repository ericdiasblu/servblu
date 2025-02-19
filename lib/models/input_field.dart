import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final EdgeInsetsGeometry? margin; // Novo parâmetro opcional

  const InputField({
    Key? key,
    required this.icon,
    required this.hintText,
    this.margin, // Adicione o novo parâmetro
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
      margin: margin ?? const EdgeInsets.only(bottom: 20), // Use o parâmetro ou um valor padrão
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF017DFE)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
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
