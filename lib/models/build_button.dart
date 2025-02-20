import 'package:flutter/material.dart';

class BuildButton extends StatelessWidget {
  final String textButton;
  final Widget? screenRoute; // Renomeado para 'screenRoute' para seguir a convenção de nomenclatura

  const BuildButton({
    Key? key,
    required this.textButton,
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
        if (screenRoute != null) { // Verifica se 'screenRoute' não é null
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => screenRoute!),
          );
        } else {
          // Aqui você pode adicionar um comportamento padrão ou um alerta, se necessário
          print("ScreenRoute is null!");
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
