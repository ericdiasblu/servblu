import 'package:flutter/material.dart';

class AgendamentoStatusHelper {
  static IconData getIconForStatus(String status) {
    switch (status) {
      case 'solicitado':
        return Icons.pending_outlined; // Ícone de espera
      case 'aguardando':
        return Icons.hourglass_bottom_outlined; // Ícone aguardando pagamento
      case 'confirmado':     // Status após pagamento
        return Icons.event_available_outlined; // Ícone de agendado/confirmado
      case 'concluído':
        return Icons.check_circle_outline; // Ícone de concluído
      case 'recusado':
        return Icons.cancel_outlined; // Ícone de cancelado/recusado
      default:
        return Icons.help_outline; // Ícone de desconhecido
    }
  }

  static Color getColorForStatus(String status) {
    // Define a COR principal associada a cada STATUS (usada no card, etc.)
    switch (status) {
      case 'solicitado':
        return Colors.orange.shade700; // Laranja mais escuro
      case 'aguardando':
        return Colors.deepPurple.shade600; // Roxo
      case 'confirmado':     // Status após pagamento
        return Colors.blue.shade700; // Azul
      case 'concluído':
        return Colors.green.shade700; // Verde
      case 'recusado':
        return Colors.red.shade700; // Vermelho
      default:
        return Colors.grey.shade600; // Cinza
    }
  }

  // ***** NOVA FUNÇÃO ADICIONADA *****
  static Color getButtonColorForStatus(BuildContext context, String status, int currentTabIndex) {
    // Define a COR DE FUNDO do BOTÃO de ação principal no modal
    switch (status) {
      case 'solicitado':
      // Cliente pode cancelar (vermelho), Prestador pode aceitar (primária)
        return currentTabIndex == 0 ? Colors.red.shade600 : Theme.of(context).primaryColor;
      case 'aguardando':
      // Cliente pode pagar (primária), Prestador pode verificar (cinza?)
        return currentTabIndex == 0 ? Theme.of(context).primaryColor : Colors.grey.shade600;
      case 'confirmado':
      // Cliente pode ver detalhes (cinza?), Prestador pode marcar como concluído (primária)
        return currentTabIndex == 0 ? Colors.grey.shade600 : Theme.of(context).primaryColor;
      case 'concluído':
      // Cliente pode avaliar (primária), Prestador pode voltar (cinza?)
        return currentTabIndex == 0 ? Theme.of(context).primaryColor : Colors.grey.shade600;
      case 'recusado':
      // Ambos só podem ver detalhes (cinza)
        return Colors.grey.shade600;
      default:
      // Cor padrão para status desconhecidos
        return Colors.grey.shade600;
    }
  }

  static String getButtonTextForStatus(String status, int currentTabIndex) {
    // Define o TEXTO do BOTÃO de ação principal no modal
    switch (status) {
      case 'solicitado':
        return currentTabIndex == 0 ? 'Cancelar Solicitação' : 'Analisar Solicitação'; // Texto mais claro para Prestador
      case 'aguardando':
        return currentTabIndex == 0 ? 'Realizar Pagamento PIX' : 'Verificar Pagamento'; // Texto mais claro
      case 'confirmado':     // Status após pagamento
        return currentTabIndex == 0 ? 'Ver Detalhes Agendamento' : 'Marcar como Concluído';
      case 'concluído':
      // TODO: Implementar lógica de avaliação
        return currentTabIndex == 0 ? 'Avaliar Serviço' : 'Ver Detalhes';
      case 'recusado':
        return 'Ver Detalhes'; // Mesmo texto para ambos
      default:
        return 'Ver Detalhes';
    }
  }

  static String getDescriptionForStatus(String status) {
    // Define a DESCRIÇÃO amigável do STATUS (usada no modal)
    switch (status) {
      case 'solicitado':
        return 'Aguardando aprovação do prestador';
      case 'aguardando':
        return 'Aguardando pagamento PIX';
      case 'confirmado':     // Status após pagamento
        return 'Pago! Aguardando data do serviço'; // Descrição mais clara
      case 'concluído':
        return 'Serviço concluído';
      case 'recusado':
        return 'Solicitação recusada pelo prestador';
      default:
        return 'Status desconhecido';
    }
  }
}