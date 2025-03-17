import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/servico.dart';
import 'package:servblu/screens/service_page/service_details_page.dart';

class NavigationHelper {
  static Future<bool?> navigateToServiceDetails(BuildContext context, Servico servico) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsPage(
          servico: servico,
        ),
      ),
    );
  }
}