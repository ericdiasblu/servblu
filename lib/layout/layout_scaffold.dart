import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/destination.dart';

class LayoutScaffold extends StatelessWidget {
  const LayoutScaffold({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('LayoutScaffold'));

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: navigationShell,
    bottomNavigationBar: NavigationBar(
      backgroundColor: Colors.white,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: navigationShell.goBranch,
      indicatorColor: Colors.blue, // Mudança para borda azul
      destinations: destinations
          .map((destination) {
        final isSelected = destination == destinations[navigationShell.currentIndex];

        return NavigationDestination(
          icon: Icon(
            size: 30,
            destination.icon,
            color: isSelected ? Colors.white : Colors.blue, // Azul para não selecionados
          ),
          label: destination.label,
          selectedIcon: Container(
            padding: const EdgeInsets.all(4.0), // Padding para o contorno
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12), // Bordas arredondadas
            ),
            child: Icon(
              destination.icon,
              color: Colors.white, // Branco para ícone selecionado
            ),
          ),
        );
      }).toList(),
    ),
  );
}