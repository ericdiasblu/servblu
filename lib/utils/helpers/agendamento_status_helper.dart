import 'package:flutter/material.dart';

class AgendamentoStatusHelper {
  static IconData getIconForStatus(String status) {
    switch (status) {
      case 'solicitado':
        return Icons.pending_outlined;
      case 'aguardando':
        return Icons.payment;
      case 'confirmado':     // Novo status após pagamento confirmado
        return Icons.schedule;
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
      case 'confirmado':     // Novo status após pagamento confirmado
        return Colors.blue;
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
      case 'confirmado':     // Novo status após pagamento confirmado
        return currentTabIndex == 0 ? 'Ver Detalhes' : 'Marcar como Concluído';
      case 'concluído':
        return currentTabIndex == 0 ? 'Avaliar Serviço' : 'Voltar';
      case 'recusado':
        return currentTabIndex == 0 ? 'Ver Detalhes' : 'Ver Detalhes';
      default:
        return 'Ver Detalhes';
    }
  }

  // Adicionado para ajudar na exibição de descrições amigáveis dos status
  static String getDescriptionForStatus(String status) {
    switch (status) {
      case 'solicitado':
        return 'Aguardando aprovação';
      case 'aguardando':
        return 'Aguardando pagamento';
      case 'confirmado':     // Novo status após pagamento confirmado
        return 'Pagamento confirmado, aguardando data do serviço';
      case 'concluído':
        return 'Serviço concluído';
      case 'recusado':
        return 'Solicitação recusada';
      default:
        return 'Status desconhecido';
    }
  }
}