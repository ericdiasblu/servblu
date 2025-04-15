import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/agendamento.dart';
import 'package:servblu/services/agendamento_service.dart';

class AgendamentoActions {
  static void executeActionForStatus(BuildContext context, String status,
      Agendamento agendamento, int currentTabIndex, Function refreshData) {
    switch (status) {
      case 'solicitado':
        if (currentTabIndex == 0) {
          cancelarSolicitacao(context, agendamento, refreshData);
        } else {
          gerenciarSolicitacao(context, agendamento, refreshData);
        }
        break;
      case 'aguardando':
        if (currentTabIndex == 0) {
          confirmarPagamento(context, agendamento, refreshData);
        } else {
          verificarPagamento(context, agendamento, refreshData);
        }
        break;
      case 'concluído':
        if (currentTabIndex == 0) {
          avaliarServico(context, agendamento, refreshData);
        } else {
          voltar(context, agendamento, refreshData);
        }
        break;
      case 'recusado':
        verDetalhes(context, agendamento, refreshData);
        break;
      default:
        verDetalhes(context, agendamento, refreshData);
    }
  }

  static void cancelarSolicitacao(BuildContext context, Agendamento agendamento,
      Function refreshData) async {
    try {
      final agendamentoService = AgendamentoService();
      await agendamentoService.removerAgendamento(
        agendamento.idAgendamento,
      );

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitação cancelada com sucesso')),
      );
      refreshData();
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cancelar solicitação: $e')),
      );
    }
  }

  static void confirmarPagamento(BuildContext context, Agendamento agendamento,
      Function refreshData) async {
    Navigator.pop(context);
    // função pagamento
  }

  static void verificarPagamento(BuildContext context, Agendamento agendamento,
      Function refreshData) async {
    Navigator.pop(context);
    // função verificar status pagamento
  }

  static void avaliarServico(
      BuildContext context, Agendamento agendamento, Function refreshData) {
    // Abrir modal para avaliação
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double nota = 3.0; // Valor padrão
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: Text('Avaliar Serviço'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Como você avalia o serviço prestado?'),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${nota.toInt()}'),
                    SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        value: nota,
                        min: 1,
                        max: 5,
                        divisions: 4,
                        onChanged: (value) {
                          setState(() {
                            nota = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Comentário (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Cancelar'),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: Text('Enviar Avaliação'),
                onPressed: () async {
                  Navigator.pop(context); // Fecha o diálogo de avaliação
                  Navigator.pop(context); // Fecha o modal de detalhes

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Avaliação enviada com sucesso')),
                  );
                  refreshData();
                },
              ),
            ],
          );
        });
      },
    );
  }

  static void voltar(BuildContext context, Agendamento agendamento,
      Function refreshData) async {
    Navigator.pop(context);
  }

  static void verDetalhes(BuildContext context, Agendamento agendamento,
      Function refreshData) async {
    try {
      final agendamentoService = AgendamentoService();
      Agendamento detalhes = await agendamentoService.obterDetalhesAgendamento(agendamento.idAgendamento);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Motivo da Recusa'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('"${detalhes.motivoRecusa}"'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Fechar'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar motivo: $e')),
      );
    }
  }

  static void recusarSolicitacao(
      BuildContext context, Agendamento agendamento, Function refreshData) {
    // Abrir modal para confirmar recusa e solicitar motivo
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String motivo = '';
        return AlertDialog(
          title: Text('Recusar Solicitação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tem certeza que deseja recusar esta solicitação?'),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Motivo da recusa (obrigatório)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => motivo = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Confirmar'),
              onPressed: () async {
                if (motivo.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Informe o motivo da recusa')),
                  );
                  return;
                }

                try {
                  final agendamentoService = AgendamentoService();
                  await agendamentoService.atualizarStatusAgendamento(
                      agendamento.idAgendamento, 'recusado',
                      motivoRecusa: motivo);

                  Navigator.pop(context); // Fecha o diálogo de confirmação
                  Navigator.pop(context); // Fecha o modal de detalhes

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Solicitação recusada com sucesso')),
                  );
                  refreshData();
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao recusar solicitação: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  static void aceitarSolicitacao(BuildContext context, Agendamento agendamento,
      Function refreshData) async {
    try {
      final agendamentoService = AgendamentoService();
      await agendamentoService.atualizarStatusAgendamento(
          agendamento.idAgendamento, 'aguardando');

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitação aceita com sucesso')),
      );
      refreshData();
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceitar solicitação: $e')),
      );
    }
  }

  static void gerenciarSolicitacao(
      BuildContext context, Agendamento agendamento, Function refreshData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Como gostaria de prosseguir?'),
          content: Text('Como deseja proceder com esta solicitação?'),
          actions: [
            TextButton(
              child: Text('Aceitar'),
              onPressed: () {
                // Fecha este diálogo
                aceitarSolicitacao(context, agendamento, refreshData);
              },
            ),
            TextButton(
              child: Text('Recusar'),
              onPressed: () {
                // Fecha este diálogo
                recusarSolicitacao(context, agendamento, refreshData);
              },
            ),
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}
