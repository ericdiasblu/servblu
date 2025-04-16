import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/agendamento.dart';
import 'package:servblu/services/agendamento_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/pagamento/qrcode_screen.dart';

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
          Pagamento(context, agendamento, refreshData);
        } else {
          verificarPagamento(context, agendamento, refreshData);
        }
        break;
      case 'confirmado':  // Novo status após pagamento confirmado
        if (currentTabIndex == 0) {
          verDetalhes(context, agendamento, refreshData);
        } else {
          marcarComoConcluido(context, agendamento, refreshData);
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

  static void Pagamento(BuildContext context, Agendamento agendamento,
      Function refreshData) async {
    Navigator.pop(context); // Fecha o modal atual

    // Verifica se o pagamento é via PIX
    if (agendamento.isPix == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentScreen(
            agendamento: agendamento,  // Passando o objeto agendamento completo
            description: 'Pagamento de serviço: ${agendamento.nomeServico}',
          ),
        ),
      );
    } else {
      // Se não for PIX, busca as informações de contato do prestador
      try {
        final AgendamentoService _agendamentoService = AgendamentoService();
        final prestadorInfo = await _agendamentoService.obterDetalhesPrestador(agendamento.idPrestador);

        // Mostrar modal com informações para pagamento
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Instruções de Pagamento'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Por favor, entre em contato com o prestador para realizar o pagamento:',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Prestador: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: '${prestadorInfo['nome']}'),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Telefone: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: '${prestadorInfo['telefone']}'),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 16, color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Forma de pagamento: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: '${agendamento.formaPagamento}'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Lembre-se de realizar o pagamento antes da data do serviço.',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (refreshData != null) {
                      refreshData();
                    }
                  },
                  child: Text('Entendi'),
                ),
                TextButton(
                  onPressed: () async {
                    // Tenta iniciar uma chamada telefônica
                    final Uri url = Uri.parse('tel:${prestadorInfo['telefone']}');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                  child: Text('Ligar agora'),
                ),
              ],
            );
          },
        );
      } catch (e) {
        // Em caso de erro, mostrar um snackbar com a mensagem
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar informações do prestador. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
        print('Erro ao buscar detalhes do prestador: $e');
      }
    }
  }

  static void verificarPagamento(BuildContext context, Agendamento agendamento,
      Function refreshData) async {
    // Mostrar indicador de carregamento
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final agendamentoService = AgendamentoService();
      final supabase = Supabase.instance.client;

      // Verifica se existe pagamento confirmado para este agendamento
      final pagamento = await supabase
          .from('pagamentos')
          .select()
          .eq('id_agendamento', agendamento.idAgendamento)
          .eq('status', 'confirmado')
          .maybeSingle();

      // Fecha o indicador de carregamento
      Navigator.pop(context);

      if (pagamento != null) {
        // Pagamento confirmado - atualizar status para "confirmado"
        await agendamentoService.atualizarStatusAgendamento(
            agendamento.idAgendamento, 'confirmado');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pagamento confirmado! O serviço está agendado e aguardando a data.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Pagamento não encontrado ou não confirmado
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('O pagamento ainda não foi confirmado.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      refreshData(); // Atualiza a lista de agendamentos
    } catch (e) {
      // Fecha o indicador de carregamento em caso de erro
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao verificar pagamento: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Erro ao verificar pagamento: $e');
    }
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

  // Dentro de AgendamentoActions.dart

  static void marcarComoConcluido(BuildContext context, Agendamento agendamento,
      Function refreshData) async {

    // Salva o contexto do ModalBottomSheet para usar depois
    final modalContext = context;

    // Mostra o diálogo de confirmação e aguarda o resultado (true se confirmar, false/null se cancelar)
    final bool? confirmou = await showDialog<bool>(
      context: modalContext, // Usa o contexto que abriu o modal
      builder: (BuildContext dialogContext) { // Contexto interno do diálogo
        return AlertDialog(
          title: Text('Confirmar Conclusão'),
          content: Text('Tem certeza que deseja marcar este serviço como concluído?'),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.pop(dialogContext, false), // Retorna false
            ),
            TextButton(
              child: Text('Confirmar'),
              onPressed: () => Navigator.pop(dialogContext, true), // Retorna true
            ),
          ],
        );
      },
    );

    // Só executa as ações se o usuário confirmou (resultado foi true)
    if (confirmou == true) {
      // Opcional: Mostrar um indicador de loading enquanto atualiza
      // showDialog(context: modalContext, barrierDismissible: false, builder: (_) => Center(child: CircularProgressIndicator()));

      try {
        final agendamentoService = AgendamentoService();
        await agendamentoService.atualizarStatusAgendamento(
            agendamento.idAgendamento, 'concluído');

        // Opcional: Fecha o loading
        // if (Navigator.canPop(modalContext)) Navigator.pop(modalContext);

        // Fecha o ModalBottomSheet original APÓS o sucesso da operação
        // Verifica se o modal ainda está na árvore antes de fechar
        if (ModalRoute.of(modalContext)?.isCurrent ?? false) {
          Navigator.pop(modalContext);
        }

        // Mostra o SnackBar na tela subjacente (ScheduleScreen)
        ScaffoldMessenger.of(modalContext).showSnackBar(
          const SnackBar(
            content: Text('Serviço marcado como concluído!'),
            backgroundColor: Colors.green,
          ),
        );

        // Atualiza a lista na ScheduleScreen
        refreshData();

      } catch (e) {
        print("Erro ao marcar como concluido: $e"); // Log do erro

        // Opcional: Fecha o loading
        // if (Navigator.canPop(modalContext)) Navigator.pop(modalContext);

        // Fecha o ModalBottomSheet original MESMO em caso de erro para não ficar preso
        if (ModalRoute.of(modalContext)?.isCurrent ?? false) {
          Navigator.pop(modalContext);
        }

        // Mostra o SnackBar de erro
        ScaffoldMessenger.of(modalContext).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar status: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Você pode decidir se quer chamar refreshData() aqui também ou não
      }
    }
    // Se confirmou for false ou null, não faz nada (o diálogo já foi fechado)
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
