import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BuildCategories extends StatelessWidget {
  final String textCategory;
  final IconData icon;
  final VoidCallback? onTap;

  const BuildCategories({
    Key? key,
    required this.textCategory,
    required this.icon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 9),
        ElevatedButton(
          onPressed: onTap ?? () {
            // Navegação padrão se nenhum onTap for fornecido
            context.go('/service-list?category=$textCategory', extra: textCategory);
          },
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
          ),
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.blue, width: 3),
              color: Colors.transparent,
            ),
            child: Center(
              child: Icon(
                icon,
                color: Colors.blue,
                size: 35,
              ),
            ),
          ),
        ),
        Text(
          textCategory,
          style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold
          ),
        )
      ],
    );
  }
}