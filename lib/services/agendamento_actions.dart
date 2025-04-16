import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/agendamento.dart';
import 'package:servblu/services/agendamento_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// ****** VERIFIQUE SE O CAMINHO ESTÁ CORRETO ******
import '../screens/pagamento/qrcode_screen.dart'; // PaymentScreen
// ************************************************


class AgendamentoActions {
  static void executeActionForStatus(BuildContext context, String status,
      Agendamento agendamento, int currentTabIndex, Function refreshData) {

    final BuildContext primaryContext = context;
    void closeModalAndRefresh() { if (Navigator.canPop(primaryContext)) Navigator.pop(primaryContext); refreshData(); }
    void closeModalOnly() { if (Navigator.canPop(primaryContext)) Navigator.pop(primaryContext); }

    switch (status) {
      case 'solicitado':
        if (currentTabIndex == 0) { cancelarSolicitacao(primaryContext, agendamento, refreshData); }
        else { gerenciarSolicitacao(primaryContext, agendamento, refreshData, closeModalOnly); }
        break;
      case 'aguardando':
        if (currentTabIndex == 0) { Pagamento(primaryContext, agendamento, refreshData, closeModalOnly); }
        else { verificarPagamento(primaryContext, agendamento, refreshData); }
        break;
      case 'confirmado':
        if (currentTabIndex == 0) { print("Ação Cliente 'confirmado': Fechando modal."); closeModalOnly(); }
        else { marcarComoConcluido(primaryContext, agendamento, refreshData); }
        break;
      case 'concluído':
        if (currentTabIndex == 0) { avaliarServico(primaryContext, agendamento, refreshData, closeModalOnly); }
        else { voltar(primaryContext, agendamento, refreshData); }
        break;
      case 'recusado':
        verDetalhes(primaryContext, agendamento, refreshData, closeModalOnly);
        break;
      default:
        print("Status não mapeado: $status. Fechando modal."); closeModalOnly();
    }
  }

  // --- Métodos de Ação ---

  static void cancelarSolicitacao(BuildContext context, Agendamento agendamento, Function refreshData) async {
    // (Código mantido - com confirmação e loading)
    final bool? confirm = await showDialog<bool>(
      context: context, builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text('Confirmar Cancelamento'),
        content: Text('Tem certeza que deseja cancelar esta solicitação? Esta ação não pode ser desfeita.'),
        actions: <Widget>[
          TextButton( child: Text('Não'), onPressed: () => Navigator.pop(dialogContext, false)),
          TextButton( child: Text('Sim, Cancelar'), style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () => Navigator.pop(dialogContext, true)),
        ],
      );
    },
    );
    if (confirm != true) return;
    showDialog( context: context, barrierDismissible: false, builder: (BuildContext context) => Center(child: CircularProgressIndicator()));
    try {
      final agendamentoService = AgendamentoService();
      await agendamentoService.removerAgendamento(agendamento.idAgendamento);
      Navigator.pop(context); // Fecha loading
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Solicitação cancelada com sucesso')),);
      refreshData();
    } catch (e) {
      Navigator.pop(context); // Fecha loading
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Erro ao cancelar solicitação: $e')),);
    }
  }

  static void Pagamento(BuildContext context, Agendamento agendamento, Function refreshData, Function closeModalCallback) {
    closeModalCallback(); // Fecha modal de ações original

    if (agendamento.isPix == true) {
      final description = 'Pagamento de serviço: ${agendamento.nomeServico ?? 'Serviço Indefinido'}';
      print("AgendamentoActions.Pagamento: Iniciando fluxo PIX...");
      Navigator.push(
        context,
        MaterialPageRoute( builder: (context) => PaymentScreen( agendamento: agendamento, description: description,)),
      ).then((_) { // Executa QUANDO voltar do fluxo de pagamento (PaymentScreen ou PaymentStatusScreen)
        print("AgendamentoActions.Pagamento: Retornou do fluxo de pagamento PIX. Chamando refreshData().");
        refreshData(); // Atualiza a lista na ScheduleScreen
      });
    } else {
      _showNonPixPaymentInstructions(context, agendamento); // Lógica Não-PIX
    }
  }

  // CORRIGIDO: Removida a vírgula extra no botão "Ligar agora"
  static void _showNonPixPaymentInstructions(BuildContext context, Agendamento agendamento) async {
    showDialog( context: context, barrierDismissible: false, builder: (BuildContext context) => Center(child: CircularProgressIndicator()));
    try {
      final AgendamentoService _agendamentoService = AgendamentoService();
      final prestadorInfo = await _agendamentoService.obterDetalhesPrestador(agendamento.idPrestador);
      Navigator.pop(context); // Fecha loading
      showDialog( context: context, builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Instruções de Pagamento'),
          content: Column(
              mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text( 'Por favor, entre em contato com o prestador para combinar o pagamento:', style: TextStyle(fontSize: 16)), SizedBox(height: 16),
            RichText( text: TextSpan( style: TextStyle(fontSize: 16, color: Colors.black), children: [ TextSpan(text: 'Prestador: ', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: '${prestadorInfo['nome'] ?? 'N/A'}'), ],),), SizedBox(height: 8),
            RichText( text: TextSpan( style: TextStyle(fontSize: 16, color: Colors.black), children: [ TextSpan(text: 'Telefone: ', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: '${prestadorInfo['telefone'] ?? 'N/A'}'), ],),), SizedBox(height: 8),
            RichText( text: TextSpan( style: TextStyle(fontSize: 16, color: Colors.black), children: [ TextSpan(text: 'Forma de pagamento: ', style: TextStyle(fontWeight: FontWeight.bold)), TextSpan(text: '${agendamento.formaPagamento ?? 'A combinar'}'), ],),), SizedBox(height: 16),
            Text( 'Após o pagamento ser confirmado pelo prestador, o status será atualizado.', style: TextStyle(fontStyle: FontStyle.italic)),
          ]),
          actions: [
            TextButton( onPressed: () => Navigator.pop(dialogContext), child: Text('Entendi')),
            TextButton(
                onPressed: () async {
                  final telefone = prestadorInfo['telefone'];
                  if (telefone != null) {
                    final Uri url = Uri.parse('tel:$telefone');
                    try {
                      if (await canLaunchUrl(url)) { await launchUrl(url); }
                      else { ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Não foi possível abrir o discador.'))); }
                    } catch (e) { ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Erro ao tentar realizar a ligação.'))); }
                  } else { ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text('Número de telefone indisponível.'))); }
                }, // <--- VÍRGULA REMOVIDA DAQUI
                child: Text('Ligar agora')
            ),
          ],
        );
      });
    } catch (e) {
      Navigator.pop(context); // Fecha loading
      ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('Erro ao carregar informações do prestador: $e'), backgroundColor: Colors.red,));
      print('Erro ao buscar detalhes do prestador: $e');
    }
  }


  static void verificarPagamento(BuildContext context, Agendamento agendamento, Function refreshData) async {
    // (Código mantido - com checagem dupla e refresh condicional)
    final currentContext = context;
    if (Navigator.canPop(currentContext)) Navigator.pop(currentContext); // Fecha modal ações
    showDialog( context: currentContext, barrierDismissible: false, builder: (BuildContext dialogContext) => const Center( child: CircularProgressIndicator()));
    try {
      final agendamentoService = AgendamentoService(); final supabase = Supabase.instance.client; bool statusMudou = false;
      final pagamentoConfirmado = await supabase.from('pagamentos').select('id_pagamento').eq('id_agendamento', agendamento.idAgendamento).eq('status', 'confirmado').limit(1).maybeSingle();
      Navigator.pop(currentContext); // Fecha loading
      if (pagamentoConfirmado != null) {
        if(agendamento.status != 'confirmado') {
          print("Verificar Pagamento: Atualizando agendamento para 'confirmado'.");
          await agendamentoService.atualizarStatusAgendamento( agendamento.idAgendamento, 'confirmado'); statusMudou = true;
          ScaffoldMessenger.of(currentContext).showSnackBar( const SnackBar( content: Text('Pagamento verificado e status atualizado!'), backgroundColor: Colors.green));
        } else {
          print("Verificar Pagamento: Agendamento já estava 'confirmado'.");
          ScaffoldMessenger.of(currentContext).showSnackBar( const SnackBar( content: Text('O pagamento já foi confirmado anteriormente.'), backgroundColor: Colors.blue));
        }
      } else {
        print("Verificar Pagamento: Nenhum pagamento 'confirmado' encontrado.");
        ScaffoldMessenger.of(currentContext).showSnackBar( const SnackBar( content: Text('O pagamento correspondente ainda não foi encontrado ou confirmado.'), backgroundColor: Colors.orange));
      }
      if (statusMudou) refreshData();
    } catch (e) {
      if (Navigator.canPop(currentContext)) Navigator.pop(currentContext); // Fecha loading erro
      ScaffoldMessenger.of(currentContext).showSnackBar( SnackBar( content: Text('Erro ao verificar pagamento: $e'), backgroundColor: Colors.red));
      print('Erro ao verificar pagamento: $e');
    }
  }

  static void avaliarServico( BuildContext context, Agendamento agendamento, Function refreshData, Function closeModalCallback) {
    // (Código mantido - com estrelas)
    final primaryContext = context;
    closeModalCallback(); // Fecha modal de ações
    showDialog( context: primaryContext, builder: (BuildContext dialogContext) {
      double nota = 3.0; final comentarioController = TextEditingController();
      return StatefulBuilder(builder: (context, setStateDialog) {
        return AlertDialog(
          title: Text('Avaliar Serviço'),
          content: SingleChildScrollView( child: Column( mainAxisSize: MainAxisSize.min, children: [
            Text('Como você avalia o serviço prestado por ${agendamento.nomePrestador ?? "este prestador"}?'), SizedBox(height: 16),
            Row( mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) { return IconButton( icon: Icon( index < nota ? Icons.star : Icons.star_border, color: Colors.amber,), onPressed: () => setStateDialog(() => nota = (index + 1).toDouble())); }),),
            Text('${nota.toInt()} de 5 estrelas'), SizedBox(height: 16),
            TextField( controller: comentarioController, decoration: InputDecoration( labelText: 'Comentário (opcional)', hintText: 'Descreva sua experiência...', border: OutlineInputBorder()), maxLines: 3, keyboardType: TextInputType.multiline),
          ],),
          ),
          actions: [
            TextButton( child: Text('Cancelar'), onPressed: () => Navigator.pop(dialogContext)),
            TextButton( child: Text('Enviar Avaliação'), onPressed: () async { Navigator.pop(dialogContext); /* TODO: Lógica de envio backend */ ScaffoldMessenger.of(primaryContext).showSnackBar(SnackBar(content: Text('Avaliação enviada (simulação)'))); }),
          ],
        );
      });
    });
  }

  static void voltar(BuildContext context, Agendamento agendamento, Function refreshData) {
    // (Código mantido)
    if (Navigator.canPop(context)) { Navigator.pop(context); }
  }

  static void verDetalhes(BuildContext context, Agendamento agendamento, Function refreshData, Function closeModalCallback) async {
    // (Código mantido - focado em 'recusado')
    closeModalCallback(); // Fecha modal de ações
    if (agendamento.status == 'recusado') {
      showDialog(context: context, barrierDismissible: false, builder: (BuildContext context) => Center(child: CircularProgressIndicator()));
      try {
        final agendamentoService = AgendamentoService(); String motivo = agendamento.motivoRecusa ?? '';
        if (motivo.isEmpty) { Agendamento detalhes = await agendamentoService.obterDetalhesAgendamento(agendamento.idAgendamento); motivo = detalhes.motivoRecusa ?? 'Motivo não informado.';}
        Navigator.pop(context); // Fecha loading
        showDialog( context: context, builder: (BuildContext dialogContext) {
          return AlertDialog( title: Text('Motivo da Recusa'), content: Text(motivo.isNotEmpty ? '"$motivo"' : 'Motivo não especificado.'), actions: [ TextButton( onPressed: () => Navigator.pop(dialogContext), child: Text('Fechar'))]);
        });
      } catch (e) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar motivo da recusa: $e'))); }
    } else { print("Ver Detalhes: Chamado para status '${agendamento.status}'. Nenhuma ação extra definida."); }
  }

  static void recusarSolicitacao( BuildContext context, Agendamento agendamento, Function refreshData, Function closeModalCallback) {
    // (Código mantido - com validação)
    closeModalCallback(); // Fecha modal de ações
    showDialog( context: context, builder: (BuildContext dialogContext) {
      String motivo = ''; final formKey = GlobalKey<FormState>();
      return AlertDialog( title: Text('Recusar Solicitação'), content: Form( key: formKey, child: Column( mainAxisSize: MainAxisSize.min, children: [ Text('Tem certeza que deseja recusar esta solicitação?'), SizedBox(height: 16), TextFormField( decoration: InputDecoration( labelText: 'Motivo da recusa *', hintText: 'Informe o motivo...', border: OutlineInputBorder()), maxLines: 3, validator: (v) { if (v == null || v.trim().isEmpty) return 'O motivo é obrigatório.'; if (v.trim().length < 5) return 'O motivo deve ter pelo menos 5 caracteres.'; return null; }, onSaved: (v) => motivo = v ?? ''), ],),),
        actions: [
          TextButton( child: Text('Cancelar'), onPressed: () => Navigator.pop(dialogContext)),
          TextButton( child: Text('Confirmar Recusa'), style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () async { if (formKey.currentState!.validate()) { formKey.currentState!.save(); Navigator.pop(dialogContext); showDialog(context: context, barrierDismissible: false, builder: (BuildContext context) => Center(child: CircularProgressIndicator())); try { final agendamentoService = AgendamentoService(); await agendamentoService.atualizarStatusAgendamento(agendamento.idAgendamento, 'recusado', motivoRecusa: motivo); Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Solicitação recusada com sucesso'))); refreshData(); } catch (e) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao recusar solicitação: $e')));}}}),
        ],
      );
    });
  }

  static void aceitarSolicitacao(BuildContext context, Agendamento agendamento, Function refreshData, Function closeModalCallback) async {
    // (Código mantido - com confirmação)
    closeModalCallback(); // Fecha modal de ações
    final bool? confirm = await showDialog<bool>( context: context, builder: (BuildContext dialogContext) {
      return AlertDialog( title: Text('Aceitar Solicitação?'), content: Text('Deseja aceitar este agendamento? O cliente será notificado para realizar o pagamento.'), actions: [ TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text('Cancelar')), TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text('Sim, Aceitar')),]);
    });
    if (confirm != true) return;
    showDialog( context: context, barrierDismissible: false, builder: (BuildContext context) => Center(child: CircularProgressIndicator()));
    try {
      final agendamentoService = AgendamentoService(); await agendamentoService.atualizarStatusAgendamento( agendamento.idAgendamento, 'aguardando');
      Navigator.pop(context); // Fecha loading
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Solicitação aceita. Aguardando pagamento do cliente.')),);
      refreshData();
    } catch (e) {
      Navigator.pop(context); // Fecha loading
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Erro ao aceitar solicitação: $e')),);
    }
  }

  static void marcarComoConcluido(BuildContext context, Agendamento agendamento, Function refreshData) async {
    // (Código mantido - com confirmação)
    final primaryContext = context;
    final bool? confirmou = await showDialog<bool>( context: primaryContext, builder: (BuildContext dialogContext) {
      return AlertDialog( title: Text('Confirmar Conclusão'), content: Text('Tem certeza que deseja marcar este serviço como concluído?'), actions: [ TextButton( child: Text('Cancelar'), onPressed: () => Navigator.pop(dialogContext, false)), TextButton( child: Text('Confirmar'), onPressed: () => Navigator.pop(dialogContext, true)),],);
    });
    if (confirmou == true) {
      if (Navigator.canPop(primaryContext)) Navigator.pop(primaryContext); // Fecha modal detalhes
      showDialog( context: primaryContext, barrierDismissible: false, builder: (BuildContext context) => Center(child: CircularProgressIndicator()));
      try {
        final agendamentoService = AgendamentoService(); await agendamentoService.atualizarStatusAgendamento( agendamento.idAgendamento, 'concluído');
        Navigator.pop(primaryContext); // Fecha loading
        ScaffoldMessenger.of(primaryContext).showSnackBar( const SnackBar( content: Text('Serviço marcado como concluído!'), backgroundColor: Colors.green));
        refreshData();
      } catch (e) {
        print("Erro ao marcar como concluido: $e"); Navigator.pop(primaryContext); // Fecha loading
        ScaffoldMessenger.of(primaryContext).showSnackBar( SnackBar( content: Text('Erro ao atualizar status: $e'), backgroundColor: Colors.red));
      }
    }
  }

  static void gerenciarSolicitacao( BuildContext context, Agendamento agendamento, Function refreshData, Function closeModalCallback) {
    // (Código mantido - chamando aceitar/recusar)
    closeModalCallback(); // Fecha modal de ações
    showDialog( context: context, builder: (BuildContext dialogContext) {
      return AlertDialog( title: Text('Gerenciar Solicitação'), content: Text('Escolha uma ação para esta solicitação:'), actions: [
        TextButton( child: Text('Aceitar'), onPressed: () { Navigator.pop(dialogContext); aceitarSolicitacao(context, agendamento, refreshData, () {}); }), // Callback vazio
        TextButton( child: Text('Recusar'), style: TextButton.styleFrom(foregroundColor: Colors.red), onPressed: () { Navigator.pop(dialogContext); recusarSolicitacao(context, agendamento, refreshData, () {}); }), // Callback vazio
        TextButton( child: Text('Cancelar'), onPressed: () => Navigator.pop(dialogContext)),
      ],);
    });
  }

} // Fim da classe AgendamentoActions