import 'package:flutter/material.dart';

class BuildButton extends StatelessWidget {
  final String textButton;
  final VoidCallback? onPressed; // Método opcional
  final Widget Function()? screenRoute; // Função opcional que retorna um Widget

  const BuildButton({
    Key? key,
    required this.textButton,
    this.onPressed,
    this.screenRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF017DFE),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        minimumSize: const Size(double.infinity, 40),
        padding: EdgeInsets.zero,
      ),
      onPressed: () {
        // Primeiro executa o método, se definido
        if (onPressed != null) {
          onPressed!();
        }

        // Depois navega para a tela, se definido
        if (screenRoute != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screenRoute!()),
          );
        }
      },
      child: Text(
        textButton,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
