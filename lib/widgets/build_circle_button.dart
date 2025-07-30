import 'package:flutter/material.dart';

class BuildCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback funcaoBotao;

  const BuildCircleButton({
    super.key,
    required this.icon,
    required this.funcaoBotao
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: funcaoBotao,
      style: ElevatedButton.styleFrom(
        minimumSize: Size(40, 40),
        padding: EdgeInsets.zero, // Remove any default padding
        shape: CircleBorder(),
        alignment: Alignment.center, // Ensure central alignment
      ),
      child: Icon(
        icon,
        color: Color(0xFF2196F3),
        size: 25,
      ),
    );
  }
}