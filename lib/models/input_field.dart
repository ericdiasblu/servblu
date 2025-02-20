import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final IconData icon;
  final String hintText;
  final TextEditingController? controller; // Adicionado como required
  final EdgeInsetsGeometry? margin; // Parâmetro opcional

  const InputField({
    Key? key,
    required this.icon,
    required this.hintText,
    this.controller, // Agora é obrigatório
    this.margin,
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
        children: [
          Icon(icon, color: const Color(0xFF017DFE)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller, // Adicionado
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
