import 'package:flutter/material.dart';

class AgendamentoStatusHelper {
  static IconData getIconForStatus(String status) {
    switch (status) {
      case 'solicitado':
        return Icons.pending_outlined;
      case 'aguardando':
        return Icons.payment;
      case 'concluído':
        return Icons.check_circle_outline;
      case 'recusado':
        return Icons.cancel_outlined;
      default:
        return Icons.error_outline;
    }
  }

  static Color getColorForStatus(String status) {
    switch (status) {
      case 'solicitado':
        return Colors.orange;
      case 'aguardando':
        return Colors.deepPurple;
      case 'concluído':
        return Colors.green;
      case 'recusado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static String getButtonTextForStatus(String status, int currentTabIndex) {
    switch (status) {
      case 'solicitado':
        return currentTabIndex == 0
            ? 'Cancelar Solicitação'
            : 'Aceitar ou Recusar';
      case 'aguardando':
        return currentTabIndex == 0 ? 'Pagar' : 'Verificar Pagamento';
      case 'concluído':
        return currentTabIndex == 0 ? 'Avaliar Serviço' : 'Voltar';
      case 'recusado':
        return currentTabIndex == 0 ? 'Ver Detalhes' : 'Ver Detalhes';
      default:
        return 'Ver Detalhes';
    }
  }
}
