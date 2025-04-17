import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/agendamento.dart';
import 'package:servblu/services/agendamento_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// Verifique se o caminho para PaymentScreen está correto
import '../screens/pagamento/qrcode_screen.dart';

class AgendamentoActions {
  // Assinatura do método principal modificada para aceitar o novo callback
  static void executeActionForStatus(
      BuildContext context, // Contexto do Modal/Dialog onde a ação foi iniciada
      String status,
      Agendamento agendamento,
      int currentTabIndex, // 0: Cliente, 1: Prestador
      // Callback para informar ScheduleScreen sobre o resultado
      Function(bool success, {String? newStatus}) onComplete)
  {
    // Funções auxiliares para chamar o callback onComplete
    void simpleSuccess() => onComplete(true);
    void successWithStatus(String newStatus) => onComplete(true, newStatus: newStatus);
    void failure() => onComplete(false);

    // Função auxiliar para fechar dialogs locais (como o de 'Gerenciar')
    // O fechamento do modal principal é feito pelo onComplete em ScheduleScreen
    void closeLocalDialog(BuildContext dialogContext) {
      if (Navigator.canPop(dialogContext)) {
        Navigator.pop(dialogContext);
      }
    }

    print("AgendamentoActions: Executando ação para status '$status' na aba ROL $currentTabIndex");

    switch (status) {
      case 'solicitado':
        if (currentTabIndex == 0) { // Cliente
          cancelarSolicitacao(context, agendamento, simpleSuccess, failure);
        } else { // Prestador
          // gerenciarSolicitacao abre um dialog local. Passamos callbacks para aceitar/recusar
          // e uma função para fechar *esse* dialog local.
          gerenciarSolicitacao(context, agendamento, successWithStatus, failure, closeLocalDialog);
        }
        break;

      case 'aguardando':
        if (currentTabIndex == 0) { // Cliente
          // Pagamento pode envolver navegação ou mostrar dialog. Usa simpleSuccess/failure.
          pagamento(context, agendamento, simpleSuccess, failure);
        } else { // Prestador
          verificarPagamento(context, agendamento, simpleSuccess, failure);
        }
        break;

      case 'confirmado':
        if (currentTabIndex == 0) { // Cliente (Ação 'Ver Detalhes' implícita)
          print("Ação Cliente 'confirmado': Nenhuma ação backend, chamando simpleSuccess para fechar modal.");
          simpleSuccess(); // Apenas sinaliza sucesso para fechar o modal
        } else { // Prestador
          marcarComoConcluido(context, agendamento, simpleSuccess, failure);
        }
        break;

      case 'concluído':
        if (currentTabIndex == 0) { // Cliente
          avaliarServico(context, agendamento, simpleSuccess, failure, closeLocalDialog);
        } else { // Prestador (Ação 'Voltar' implícita)
          print("Ação Prestador 'concluído': Nenhuma ação backend, chamando simpleSuccess para fechar modal.");
          simpleSuccess(); // Apenas sinaliza sucesso para fechar o modal
        }
        break;

      case 'recusado':
      // Ver detalhes geralmente mostra info, não muda status.
        verDetalhesRecusa(context, agendamento, simpleSuccess, failure, closeLocalDialog);
        break;

      default:
        print("Status não mapeado para ação: $status. Chamando simpleSuccess.");
        simpleSuccess(); // Comportamento padrão: sucesso para fechar modal
    }
  }

  // --- Métodos de Ação (Adaptados com onSuccess/onFailure) ---

  static void _showLoadingDialog(BuildContext context, {String message = 'Processando...'}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        content: Row(children: [CircularProgressIndicator(), SizedBox(width: 20), Text(message)]),
      ),
    );
  }

  static void _hideLoadingDialog(BuildContext context) {
    // Garante que estamos no contexto certo para fechar
    // Verifica se há uma rota modal (como o dialog) para fechar
    if(Navigator.of(context, rootNavigator: true).canPop()) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  static void cancelarSolicitacao(BuildContext context, Agendamento agendamento, Function onSuccess, Function onFailure) async {
    final bool? confirm = await showDialog<bool>(
      context: context, builder: (BuildContext dialogContext) => AlertDialog(
      title: Text('Confirmar Cancelamento'),
      content: Text('Tem certeza que deseja cancelar esta solicitação?'),
      actions: <Widget>[
        TextButton( child: Text('Não'), onPressed: () => Navigator.pop(dialogContext, false)),
        TextButton( child: Text('Sim, Cancelar'), style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.pop(dialogContext, true)),
      ],
    ),
    );
    if (confirm != true) {
      // Não chama onSuccess nem onFailure se o usuário cancelou a confirmação
      print("Cancelamento de solicitação abortado pelo usuário.");
      return;
    }

    _showLoadingDialog(context);
    try {
      final agendamentoService = AgendamentoService();
      await agendamentoService.removerAgendamento(agendamento.idAgendamento);
      _hideLoadingDialog(context);
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Solicitação cancelada com sucesso'), backgroundColor: Colors.green),);
      onSuccess(); // Chama onSuccess
    } catch (e) {
      _hideLoadingDialog(context);
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Erro ao cancelar: $e'), backgroundColor: Colors.red),);
      onFailure(); // Chama onFailure
    }
  }

  // Prestador: Dialog para escolher Aceitar ou Recusar
  static void gerenciarSolicitacao(BuildContext context, Agendamento agendamento, Function(String newStatus) onSuccessWithStatus, Function onFailure, Function(BuildContext) closeLocalDialog) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Usar dialogContext internamente
        return AlertDialog(
          title: Text('Gerenciar Solicitação'),
          content: Text('O que deseja fazer com este pedido de ${agendamento.nomeCliente ?? 'Cliente'}?'),
          actions: [
            TextButton(
              child: Text('Aceitar'),
              onPressed: () {
                closeLocalDialog(dialogContext); // Fecha este dialog ANTES de chamar a ação
                aceitarSolicitacao(context, agendamento, onSuccessWithStatus, onFailure);
              },
            ),
            TextButton(
              child: Text('Recusar'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                closeLocalDialog(dialogContext); // Fecha este dialog ANTES de chamar a ação
                recusarSolicitacao(context, agendamento, onSuccessWithStatus, onFailure);
              },
            ),
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => closeLocalDialog(dialogContext), // Apenas fecha este dialog
            ),
          ],
        );
      },
    );
  }


  // Prestador: Ação de Aceitar
  static void aceitarSolicitacao(BuildContext context, Agendamento agendamento, Function(String newStatus) onSuccessWithStatus, Function onFailure) async {
    // Confirmação opcional, mas recomendada
    final bool? confirm = await showDialog<bool>( context: context, builder: (BuildContext dialogContext) =>
        AlertDialog( title: Text('Aceitar Solicitação?'), content: Text('O cliente será notificado para pagar.'), actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('Sim, Aceitar')),
        ]
        )
    );
    if (confirm != true) return;

    _showLoadingDialog(context, message: 'Aceitando...');
    try {
      final agendamentoService = AgendamentoService();
      // Atualiza o status para 'aguardando' (pagamento)
      await agendamentoService.atualizarStatusAgendamento( agendamento.idAgendamento, 'aguardando');
      _hideLoadingDialog(context);
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Solicitação aceita! Aguardando pagamento.'), backgroundColor: Colors.green),);
      onSuccessWithStatus('aguardando'); // Chama onSuccess com o NOVO status
    } catch (e) {
      _hideLoadingDialog(context);
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Erro ao aceitar: $e'), backgroundColor: Colors.red),);
      onFailure(); // Chama onFailure
    }
  }

  // Prestador: Ação de Recusar (abre dialog para motivo)
  static void recusarSolicitacao( BuildContext context, Agendamento agendamento, Function(String newStatus) onSuccessWithStatus, Function onFailure) {
    showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          String motivo = '';
          final formKey = GlobalKey<FormState>();
          return AlertDialog(
            title: Text('Recusar Solicitação'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Por favor, informe o motivo da recusa.'),
                  SizedBox(height: 16),
                  TextFormField(
                    decoration: InputDecoration( labelText: 'Motivo *', hintText: 'Ex: Horário indisponível', border: OutlineInputBorder()),
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().length < 5) ? 'Motivo muito curto (mín. 5).' : null,
                    onSaved: (v) => motivo = v?.trim() ?? '',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton( child: Text('Cancelar'), onPressed: () => Navigator.pop(dialogContext)), // Fecha só o dialog do motivo
              TextButton(
                  child: Text('Confirmar Recusa'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      Navigator.pop(dialogContext); // Fecha dialog do motivo

                      _showLoadingDialog(context, message: 'Recusando...');
                      try {
                        final agendamentoService = AgendamentoService();
                        // Atualiza status e adiciona motivo
                        await agendamentoService.atualizarStatusAgendamento(agendamento.idAgendamento, 'recusado', motivoRecusa: motivo);
                        _hideLoadingDialog(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Solicitação recusada.'), backgroundColor: Colors.orange));
                        onSuccessWithStatus('recusado'); // Chama onSuccess com o NOVO status
                      } catch (e) {
                        _hideLoadingDialog(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao recusar: $e'), backgroundColor: Colors.red));
                        onFailure(); // Chama onFailure
                      }
                    }
                  }
              ),
            ],
          );
        }
    );
  }


  // Cliente: Inicia fluxo de pagamento
  static void pagamento(BuildContext context, Agendamento agendamento, Function onSuccess, Function onFailure) {
    // Fecha o modal de detalhes original ANTES de navegar ou mostrar dialog
    // (A responsabilidade foi movida para o onComplete em ScheduleScreen)

    if (agendamento.isPix == true && agendamento.precoServico != null && agendamento.precoServico! > 0) {
      final description = 'Pagamento: ${agendamento.nomeServico ?? 'Serviço'}';
      print("AgendamentoActions.pagamento: Iniciando fluxo PIX...");
      Navigator.push(
        context,
        MaterialPageRoute( builder: (ctx) => PaymentScreen( agendamento: agendamento, description: description,)),
      ).then((paymentResult) {
        // Este 'then' executa DEPOIS que a tela de pagamento (ou status) é fechada.
        // O resultado do pagamento (se houve) pode estar em paymentResult (precisa ajustar PaymentScreen para retornar algo).
        print("AgendamentoActions.pagamento: Retornou do fluxo PIX. Resultado: $paymentResult. Chamando onSuccess para refresh.");
        // Independentemente do resultado do pagamento, chamamos onSuccess
        // para que ScheduleScreen recarregue a lista (o status pode ou não ter mudado).
        onSuccess();
      }).catchError((error) {
        print("Erro durante navegação para PaymentScreen: $error");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao iniciar pagamento: $error'), backgroundColor: Colors.red));
        onFailure(); // Chama onFailure se a navegação falhar
      });

    } else if(agendamento.isPix == false) {
      // Lógica Não-PIX (mostrar instruções)
      _showNonPixPaymentInstructions(context, agendamento, onSuccess, onFailure);
    } else {
      // Caso Pix seja true, mas preço é nulo ou zero, ou isPix é nulo
      print("AgendamentoActions.pagamento: Condição inválida para pagamento (isPix: ${agendamento.isPix}, preco: ${agendamento.precoServico})");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não é possível iniciar pagamento. Verifique detalhes do serviço.'), backgroundColor: Colors.orange));
      onFailure(); // Considera falha se não pode iniciar
    }
  }

  // Cliente: Mostrar instruções para pagamento não-PIX
  static void _showNonPixPaymentInstructions(BuildContext context, Agendamento agendamento, Function onSuccess, Function onFailure) async {
    _showLoadingDialog(context, message: 'Buscando contato...');
    try {
      final AgendamentoService _agendamentoService = AgendamentoService();
      final prestadorInfo = await _agendamentoService.obterDetalhesPrestador(agendamento.idPrestador);
      _hideLoadingDialog(context);

      showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            final telefone = prestadorInfo['telefone'] as String?;
            final canCall = telefone != null && telefone.isNotEmpty;
            return AlertDialog(
              title: Text('Instruções de Pagamento'),
              content: SingleChildScrollView( // Para evitar overflow
                child: Column(
                    mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text( 'Combine o pagamento diretamente com o prestador:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), SizedBox(height: 16),
                  _buildPrestadorInfoRow('Prestador:', prestadorInfo['nome'] ?? 'N/A'),
                  _buildPrestadorInfoRow('Telefone:', telefone ?? 'N/A'),
                  _buildPrestadorInfoRow('Pagamento:', agendamento.formaPagamento ?? 'A combinar'),
                  SizedBox(height: 16),
                  Text( 'O status será atualizado após a confirmação do prestador.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                ]),
              ),
              actions: [
                TextButton( onPressed: () => Navigator.pop(dialogContext), child: Text('Entendi')),
                if (canCall)
                  TextButton(
                      onPressed: () async {
                        final Uri url = Uri.parse('tel:$telefone');
                        try {
                          if (await canLaunchUrl(url)) { await launchUrl(url); }
                          else { ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Não foi possível abrir o discador.'))); }
                        } catch (e) { ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Erro ao tentar ligar.'))); }
                      },
                      child: Text('Ligar agora')
                  ),
              ],
            );
          }
      ).then((_) {
        // Após fechar o dialog de instruções, consideramos a "ação" concluída.
        onSuccess();
      });

    } catch (e) {
      _hideLoadingDialog(context);
      ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('Erro ao buscar contato: $e'), backgroundColor: Colors.red,));
      print('Erro ao buscar detalhes do prestador: $e');
      onFailure(); // Chama onFailure em caso de erro ao buscar dados
    }
  }
  // Helper para formatar linha de info do prestador no dialog
  static Widget _buildPrestadorInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText( text: TextSpan( style: TextStyle(fontSize: 15, color: Colors.black87), children: [
        TextSpan(text: label, style: TextStyle(fontWeight: FontWeight.bold)),
        TextSpan(text: ' $value'),
      ],),),
    );
  }


  // Prestador: Verifica se pagamento PIX foi confirmado no Supabase
  static void verificarPagamento(BuildContext context, Agendamento agendamento, Function onSuccess, Function onFailure) async {
    _showLoadingDialog(context, message: 'Verificando...');
    try {
      final agendamentoService = AgendamentoService();
      final supabase = Supabase.instance.client;
      bool statusMudou = false;

      // Verifica na tabela 'pagamentos' se existe um pagamento confirmado para este agendamento
      final pagamentoConfirmado = await supabase.from('pagamentos')
          .select('id_pagamento')
          .eq('id_agendamento', agendamento.idAgendamento)
          .eq('status', 'confirmado') // Busca especificamente por 'confirmado'
          .limit(1)
          .maybeSingle();

      _hideLoadingDialog(context);

      if (pagamentoConfirmado != null) { // Encontrou pagamento confirmado
        if (agendamento.status != 'confirmado') { // E o agendamento ainda não está 'confirmado'
          print("Verificar Pagamento: Pagamento encontrado. Atualizando agendamento ${agendamento.idAgendamento} para 'confirmado'.");
          await agendamentoService.atualizarStatusAgendamento( agendamento.idAgendamento, 'confirmado');
          statusMudou = true;
          ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Pagamento confirmado e status atualizado!'), backgroundColor: Colors.green));
        } else {
          print("Verificar Pagamento: Agendamento ${agendamento.idAgendamento} já estava 'confirmado'.");
          ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Pagamento já confirmado anteriormente.'), backgroundColor: Colors.blue));
        }
      } else { // Não encontrou pagamento confirmado
        print("Verificar Pagamento: Pagamento para ${agendamento.idAgendamento} ainda não confirmado no sistema.");
        ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Pagamento ainda não consta como confirmado.'), backgroundColor: Colors.orange));
      }
      // Chama onSuccess independentemente de ter mudado o status ou não,
      // pois a verificação foi concluída com sucesso. A UI vai recarregar.
      onSuccess();

    } catch (e) {
      _hideLoadingDialog(context);
      ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('Erro ao verificar pagamento: $e'), backgroundColor: Colors.red));
      print('Erro ao verificar pagamento: $e');
      onFailure(); // Chama onFailure em caso de erro
    }
  }

  // Prestador: Marca o serviço como concluído
  static void marcarComoConcluido(BuildContext context, Agendamento agendamento, Function onSuccess, Function onFailure) async {
    final bool? confirmou = await showDialog<bool>( context: context, builder: (BuildContext dialogContext) =>
        AlertDialog( title: Text('Confirmar Conclusão'), content: Text('Marcar este serviço como concluído?'), actions: [
          TextButton( child: Text('Cancelar'), onPressed: () => Navigator.pop(dialogContext, false)),
          TextButton( child: Text('Confirmar'), onPressed: () => Navigator.pop(dialogContext, true)),
        ],
        )
    );

    if (confirmou == true) {
      _showLoadingDialog(context, message: 'Finalizando...');
      try {
        final agendamentoService = AgendamentoService();
        await agendamentoService.atualizarStatusAgendamento( agendamento.idAgendamento, 'concluído');
        _hideLoadingDialog(context);
        ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Serviço marcado como concluído!'), backgroundColor: Colors.green));
        onSuccess(); // Chama onSuccess
      } catch (e) {
        _hideLoadingDialog(context);
        print("Erro ao marcar como concluido: $e");
        ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('Erro ao finalizar: $e'), backgroundColor: Colors.red));
        onFailure(); // Chama onFailure
      }
    }
    // Se confirmou == false, não faz nada e não chama callbacks
  }


  // Cliente: Abre dialog para avaliação (Simulação)
  static void avaliarServico(BuildContext context, Agendamento agendamento, Function onSuccess, Function onFailure, Function(BuildContext) closeLocalDialog) {
    showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          double nota = 3.0;
          final comentarioController = TextEditingController();
          return StatefulBuilder(builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Avaliar Serviço'),
              content: SingleChildScrollView(
                child: Column( mainAxisSize: MainAxisSize.min, children: [
                  Text('Como foi o serviço de ${agendamento.nomePrestador ?? "este prestador"}?'), SizedBox(height: 16),
                  Row( mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) {
                    return IconButton(
                        icon: Icon( index < nota ? Icons.star : Icons.star_border, color: Colors.amber, size: 30,),
                        onPressed: () => setStateDialog(() => nota = (index + 1).toDouble())
                    );
                  }),),
                  Text('${nota.toInt()} de 5 estrelas', style: TextStyle(fontWeight: FontWeight.bold)), SizedBox(height: 16),
                  TextField( controller: comentarioController, decoration: InputDecoration( labelText: 'Comentário (opcional)', hintText: 'Sua opinião ajuda outros usuários...', border: OutlineInputBorder()), maxLines: 3, keyboardType: TextInputType.multiline),
                ],),
              ),
              actions: [
                TextButton( child: Text('Cancelar'), onPressed: () => closeLocalDialog(dialogContext)),
                TextButton(
                    child: Text('Enviar Avaliação'),
                    onPressed: () async {
                      // TODO: Implementar lógica real de envio da avaliação para o backend
                      print('Avaliação: Nota ${nota.toInt()}, Comentário: ${comentarioController.text}');
                      closeLocalDialog(dialogContext); // Fecha o dialog de avaliação

                      _showLoadingDialog(context, message: "Enviando...");
                      await Future.delayed(Duration(seconds: 1)); // Simula envio
                      _hideLoadingDialog(context);

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Obrigado pela sua avaliação!'), backgroundColor: Colors.green));
                      onSuccess(); // Informa sucesso na operação (mesmo que simulada)
                    }
                ),
              ],
            );
          });
        }
    );
  }

  // Cliente/Prestador: Ação para status 'recusado' - mostra motivo
  static void verDetalhesRecusa(BuildContext context, Agendamento agendamento, Function onSuccess, Function onFailure, Function(BuildContext) closeLocalDialog) async {
    if (agendamento.status != 'recusado') {
      print("verDetalhesRecusa chamado para status não-recusado: ${agendamento.status}");
      onSuccess(); // Ação concluída (não fez nada)
      return;
    }

    String motivo = agendamento.motivoRecusa ?? '';

    // Se o motivo já está no objeto, mostra direto. Senão, tenta buscar.
    if (motivo.isNotEmpty) {
      showDialog( context: context, builder: (BuildContext dialogContext) => AlertDialog(
          title: Text('Motivo da Recusa'),
          content: Text(motivo.isNotEmpty ? '"$motivo"' : 'Motivo não especificado.'),
          actions: [ TextButton( onPressed: () => closeLocalDialog(dialogContext), child: Text('Fechar'))]
      )
      ).then((_) => onSuccess()); // Chama onSuccess quando o dialog for fechado
    } else {
      _showLoadingDialog(context, message: 'Buscando motivo...');
      try {
        final agendamentoService = AgendamentoService();
        Agendamento detalhes = await agendamentoService.obterDetalhesAgendamento(agendamento.idAgendamento);
        motivo = detalhes.motivoRecusa ?? 'Motivo não informado pelo prestador.';
        _hideLoadingDialog(context);
        showDialog( context: context, builder: (BuildContext dialogContext) => AlertDialog(
            title: Text('Motivo da Recusa'),
            content: Text(motivo),
            actions: [ TextButton( onPressed: () => closeLocalDialog(dialogContext), child: Text('Fechar'))]
        )
        ).then((_) => onSuccess()); // Chama onSuccess quando o dialog for fechado
      } catch (e) {
        _hideLoadingDialog(context);
        print("Erro ao buscar motivo da recusa: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar motivo: $e'), backgroundColor: Colors.red));
        onFailure(); // Chama onFailure se erro ao buscar
      }
    }
  }

} // Fim da classe AgendamentoActions