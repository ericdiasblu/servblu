import 'package:flutter/material.dart';

class Destination {
  const Destination({required this.label,required this.icon});

  final String label;
  final IconData icon;
}

const destinations = [
  Destination(label: "Início", icon: Icons.home_filled),
  Destination(label: "Agenda", icon:Icons.calendar_month_sharp),
  Destination(label: "Anunciar", icon: Icons.add_box_sharp),
  Destination(label: "Carteira", icon: Icons.credit_card),
  Destination(label: "Perfil", icon: Icons.person),
];