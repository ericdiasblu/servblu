import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/agendamento.dart';
import 'package:servblu/services/agendamento_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

// --- Verifique se o import da PaymentScreen está correto ---
import '../screens/pagamento/qrcode_screen.dart';
// Remova o import da qrcode_screen se não for mais usada diretamente aqui
// import '../screens/pagamento/qrcode_screen.dart';

class AgendamentoActions {

  /// Função principal para determinar qual ação executar com base no status e ROL.
  /// Chama o callback onComplete para sinalizar o resultado à ScheduleScreen.
  static void executeActionForStatus(
      BuildContext context, // Contexto onde a ação foi iniciada (geralmente o Modal)
      String status,
      Agendamento agendamento,
      int currentTabIndex, // 0: Cliente, 1: Prestador
      // Callback para ScheduleScreen: (bool sucessoAcao, {String? novoStatusAposAcao})
      Function(bool success, {String? newStatus}) onComplete)
  {
    // Funções helper para simplificar a chamada do onComplete
    void simpleSuccess() => onComplete(true);
    void successWithStatus(String newStatus) => onComplete(true, newStatus: newStatus);
    void failure() => onComplete(false);

    // Helper para fechar dialogs INTERNOS criados por algumas ações
    void closeLocalDialog(BuildContext dialogContext) {
      // Verifica se o dialog pertence ao contexto e pode ser fechado
      // Usar rootNavigator pode ser mais seguro se o dialog foi mostrado com ele
      if (Navigator.of(dialogContext, rootNavigator: true).canPop()) {
        Navigator.of(dialogContext, rootNavigator: true).pop();
      } else if (Navigator.canPop(dialogContext)){
        Navigator.pop(dialogContext);
      }
    }

    print("AgendamentoActions: Executando ação para status '$status' na aba ROL $currentTabIndex (Agendamento ID: ${agendamento.idAgendamento})");

    // Delega para a função de ação apropriada
    switch (status) {
      case 'solicitado':
        if (currentTabIndex == 0) { // Cliente pode cancelar
          cancelarSolicitacao(context, agendamento, simpleSuccess, failure);
        } else { // Prestador pode gerenciar (Aceitar/Recusar)
          gerenciarSolicitacao(context, agendamento, successWithStatus, failure, closeLocalDialog);
        }
        break;

      case 'aguardando':
        if (currentTabIndex == 0) { // Cliente pode pagar
          // Chama a função de pagamento que agora usa await e retorna resultado
          pagamento(context, agendamento, simpleSuccess, failure);
        } else { // Prestador pode verificar pagamento
          verificarPagamento(context, agendamento, simpleSuccess, failure);
        }
        break;

      case 'confirmado': // Status após pagamento bem-sucedido
        if (currentTabIndex == 0) { // Cliente: Ação padrão é apenas ver detalhes
          print("Ação Cliente 'confirmado': Nenhuma ação backend, chamando simpleSuccess.");
          // Não precisa fechar o modal principal aqui, o onComplete fará isso se necessário
          simpleSuccess();
        } else { // Prestador: Pode marcar como concluído
          marcarComoConcluido(context, agendamento, simpleSuccess, failure);
        }
        break;

      case 'concluído':
        if (currentTabIndex == 0) { // Cliente: Pode avaliar
          avaliarServico(context, agendamento, simpleSuccess, failure, closeLocalDialog);
        } else { // Prestador: Ação padrão é apenas ver detalhes
          print("Ação Prestador 'concluído': Nenhuma ação backend, chamando simpleSuccess.");
          simpleSuccess();
        }
        break;

      case 'recusado': // Cliente ou Prestador: Ação é ver detalhes/motivo
        verDetalhesRecusa(context, agendamento, simpleSuccess, failure, closeLocalDialog);
        break;

      default:
        print("Status não mapeado para ação: $status. Chamando simpleSuccess.");
        simpleSuccess(); // Comportamento padrão: sucesso para fechar modal
    }
  }

  // --- Dialogs Auxiliares ---

  /// Mostra um dialog de loading simples.
  static void _showLoadingDialog(BuildContext context, {String message = 'Processando...'}) {
    // Verifica se o widget ainda está montado antes de mostrar o dialog
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false, // Impede fechar clicando fora
      useRootNavigator: false, // Geralmente false para dialogs de ação
      builder: (BuildContext dialogContext) => AlertDialog(
        content: Row(children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Text(message)
        ]),
      ),
    );
  }

  /// Esconde o dialog de loading (se existir).
  static void _hideLoadingDialog(BuildContext context) {
    // Tenta fechar o dialog associado ao contexto atual
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    // Se não conseguiu, pode ser que o contexto mudou ou o dialog foi mostrado de outra forma
    // Tentar com rootNavigator como fallback PODE fechar o dialog errado se houver outros
    // else if (Navigator.of(context, rootNavigator: true).canPop()) {
    //   Navigator.of(context, rootNavigator: true).pop();
    // }
  }

  // --- Métodos de Ação Específicos ---

  /// Cliente: Cancela uma solicitação de agendamento.
  static void cancelarSolicitacao(BuildContext context, Agendamento agendamento, Function onSuccess, Function onFailure) async {
    if (!context.mounted) return; // Verifica antes de mostrar dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Confirmar Cancelamento'),
        content: const Text('Tem certeza que deseja cancelar esta solicitação?'),
        actions: <Widget>[
          TextButton(child: const Text('Não'), onPressed: () => Navigator.pop(dialogContext, false)),
          TextButton(
              child: const Text('Sim, Cancelar'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true)),
        ],
      ),
    );

    if (confirm != true) return; // Usuário cancelou a confirmação

    if (!context.mounted) return; // Verifica antes de mostrar loading
    _showLoadingDialog(context);
    try {
      await AgendamentoService().removerAgendamento(agendamento.idAgendamento);
      if (!context.mounted) return; // Verifica após await
      _hideLoadingDialog(context);
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Solicitação cancelada com sucesso'), backgroundColor: Colors.green),);
      onSuccess();
    } catch (e) {
      if (!context.mounted) return; // Verifica após await (catch)
      _hideLoadingDialog(context);
      ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('Erro ao cancelar: ${e.toString()}'), backgroundColor: Colors.red),);
      onFailure();
    }
  }

  /// Prestador: Mostra dialog para Aceitar ou Recusar a solicitação.
  static void gerenciarSolicitacao( BuildContext context, Agendamento agendamento, Function(String newStatus) onSuccessWithStatus, Function onFailure, Function(BuildContext) closeLocalDialog) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) { // Usa dialogContext para ações internas
        return AlertDialog(
          title: const Text('Gerenciar Solicitação'),
          content: Text('Aceitar ou recusar o pedido de ${agendamento.nomeCliente ?? 'Cliente'} para o serviço "${agendamento.nomeServico ?? 'N/A'}"?'),
          actions: [
            TextButton(
              child: const Text('Aceitar'),
              onPressed: () {
                closeLocalDialog(dialogContext); // Fecha este dialog primeiro
                // Chama a função de aceitar, passando os callbacks finais e o contexto original
                aceitarSolicitacao(context, agendamento, onSuccessWithStatus, onFailure);
              },
            ),
            TextButton(
              child: const Text('Recusar'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () {
                closeLocalDialog(dialogContext); // Fecha este dialog primeiro
                // Chama a função de recusar, passando os callbacks finais e o contexto original
                recusarSolicitacao(context, agendamento, onSuccessWithStatus, onFailure);
              },
            ),
            TextButton(
              child: const Text('Voltar'), // Botão neutro para fechar
              onPressed: () => closeLocalDialog(dialogContext), // Apenas fecha este dialog
            ),
          ],
        );
      },
    );
  }


  /// Prestador: Ação de Aceitar a solicitação (muda status para 'aguardando').
  static void aceitarSolicitacao(BuildContext context, Agendamento agendamento, Function(String newStatus) onSuccessWithStatus, Function onFailure) async {
    if (!context.mounted) return;
    // Confirmação opcional
    final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Aceitar Solicitação?'),
            content: const Text('O cliente será notificado para realizar o pagamento PIX (se aplicável).'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
              TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Sim, Aceitar')),
            ]
        )
    );
    if (confirm != true) return; // Não faz nada se cancelou

    if (!context.mounted) return;
    _showLoadingDialog(context, message: 'Aceitando...');
    try {
      await AgendamentoService().atualizarStatusAgendamento( agendamento.idAgendamento, 'aguardando'); // Muda status
      if (!context.mounted) return;
      _hideLoadingDialog(context);
      ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Solicitação aceita! Aguardando cliente.'), backgroundColor: Colors.green),);
      onSuccessWithStatus('aguardando'); // Informa ScheduleScreen do sucesso e do novo status
    } catch (e) {
      if (!context.mounted) return;
      _hideLoadingDialog(context);
      ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Erro ao aceitar: ${e.toString()}'), backgroundColor: Colors.red),);
      onFailure(); // Informa ScheduleScreen da falha
    }
  }

  /// Prestador: Ação de Recusar a solicitação (pede motivo, muda status para 'recusado').
  static void recusarSolicitacao( BuildContext context, Agendamento agendamento, Function(String newStatus) onSuccessWithStatus, Function onFailure) {
    if (!context.mounted) return;
    // Mostra dialog para inserir o motivo da recusa
    showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          String motivo = '';
          final formKey = GlobalKey<FormState>();
          return AlertDialog(
            title: const Text('Recusar Solicitação'),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Encolhe para o conteúdo
                children: [
                  const Text('Informe o motivo da recusa:'),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Motivo *', hintText: 'Ex: Horário indisponível', border: OutlineInputBorder()),
                    maxLines: 3,
                    validator: (v) => (v == null || v.trim().length < 5) ? 'Motivo muito curto.' : null,
                    onSaved: (v) => motivo = v?.trim() ?? '',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () => Navigator.pop(dialogContext) // Fecha só o dialog do motivo
              ),
              TextButton(
                  child: const Text('Confirmar Recusa'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      formKey.currentState!.save();
                      Navigator.pop(dialogContext); // Fecha dialog do motivo ANTES de mostrar loading

                      if (!context.mounted) return; // Re-verifica contexto original
                      _showLoadingDialog(context, message: 'Recusando...');
                      try {
                        await AgendamentoService().atualizarStatusAgendamento(agendamento.idAgendamento, 'recusado', motivoRecusa: motivo);
                        if (!context.mounted) return; // Verifica após await
                        _hideLoadingDialog(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitação recusada.'), backgroundColor: Colors.orange));
                        onSuccessWithStatus('recusado');
                      } catch (e) {
                        if (!context.mounted) return; // Verifica após await (catch)
                        _hideLoadingDialog(context);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao recusar: ${e.toString()}'), backgroundColor: Colors.red));
                        onFailure();
                      }
                    }
                  }
              ),
            ],
          );
        }
    );
  }


  /// Cliente: Inicia fluxo de pagamento PIX ou mostra instruções para não-PIX.
  /// Processa o resultado bool? retornado por PaymentScreen.
  static Future<void> pagamento(BuildContext context, Agendamento agendamento, Function onSuccess, Function onFailure) async {

    if (agendamento.isPix == true && agendamento.precoServico != null && agendamento.precoServico! > 0) {
      // --- Lógica para pagamento PIX ---
      final description = 'Pagamento: ${agendamento.nomeServico ?? 'Agendamento ${agendamento.idAgendamento}'}';
      print("AgendamentoActions.pagamento: Iniciando fluxo PIX (PaymentScreen) para ${agendamento.idAgendamento}...");

      // Verifica se o contexto ainda é válido antes de navegar
      if (!context.mounted) {
        print("AgendamentoActions.pagamento: Contexto inválido antes de navegar. Abortando.");
        onFailure(); // Informa falha se não pode nem navegar
        return;
      }

      try {
        // Navega para PaymentScreen e ESPERA (await) pelo resultado (bool?)
        // PaymentScreen é responsável por todo o fluxo PIX e por retornar:
        // - true: Se o PIX foi pago E o backend foi atualizado com sucesso (via PaymentStatusScreen).
        // - false: Se houve falha no PIX OU no processamento do backend.
        // - null: Se o usuário cancelou o processo (ex: botão voltar).
        final bool? pagamentoCompletoBemSucedido = await Navigator.push<bool?>(
          context,
          MaterialPageRoute(
            builder: (ctx) => PaymentScreen(
              description: description,
              agendamento: agendamento,
            ),
          ),
        );

        // Este código executa APÓS PaymentScreen retornar (via Navigator.pop)
        print("AgendamentoActions.pagamento: Retornou do fluxo PaymentScreen/StatusScreen. Resultado final: $pagamentoCompletoBemSucedido");

        // Verifica o resultado e chama o callback apropriado
        if (pagamentoCompletoBemSucedido == true) {
          print("AgendamentoActions.pagamento: Sucesso confirmado pelo fluxo completo. Chamando onSuccess.");
          onSuccess(); // Chama o callback de SUCESSO para ScheduleScreen
        } else {
          // Se retornou false (falha explícita) ou null (cancelamento/volta)
          print("AgendamentoActions.pagamento: Falha ou cancelamento no fluxo. Chamando onFailure.");
          onFailure(); // Chama o callback de FALHA para ScheduleScreen

          // Mostra uma mensagem para o usuário (apenas se o contexto ainda for válido)
          if (context.mounted) {
            if (pagamentoCompletoBemSucedido == false) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ocorreu uma falha durante o pagamento.')));
            } else { // null implica cancelamento
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pagamento cancelado.')));
            }
          }
        }

      } catch (error, stacktrace) {
        // Erro durante a própria navegação (ex: build da PaymentScreen falhou)
        print("Erro CRÍTICO durante navegação para PaymentScreen: $error");
        print(stacktrace);
        if (context.mounted) { // Verifica context.mounted
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro inesperado ao iniciar pagamento: ${error.toString()}'), backgroundColor: Colors.red));
        }
        onFailure(); // Informa falha se a navegação/build falhar
      }

    } else if(agendamento.isPix == false) {
      // --- Lógica para pagamento Não-PIX (combinar com prestador) ---
      print("AgendamentoActions.pagamento: Iniciando fluxo Não-PIX (instruções).");
      _showNonPixPaymentInstructions(context, agendamento, onSuccess, onFailure);
    } else {
      // --- Condição inválida ---
      print("AgendamentoActions.pagamento: Condição inválida para pagamento (isPix: ${agendamento.isPix}, preco: ${agendamento.precoServico})");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não é possível pagar. Verifique detalhes ou contate suporte.'), backgroundColor: Colors.orange));
      }
      onFailure(); // Considera falha se não pode iniciar
    }
  }

  /// Cliente: Mostra dialog com instruções para pagamento não-PIX.
  static void _showNonPixPaymentInstructions(BuildContext context, Agendamento agendamento, Function onSuccess, Function onFailure) async {
    if (!context.mounted) return;
    _showLoadingDialog(context, message: 'Buscando contato...');
    try {
      final prestadorInfo = await AgendamentoService().obterDetalhesPrestador(agendamento.idPrestador);
      if (!context.mounted) return;
      _hideLoadingDialog(context);

      final telefone = prestadorInfo['telefone'] as String?;
      final canCall = telefone != null && telefone.isNotEmpty;

      // Mostra o dialog com as informações
      showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: const Text('Instruções de Pagamento'),
              content: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text( 'Combine o pagamento diretamente com o prestador:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      _buildPrestadorInfoRow('Prestador:', prestadorInfo['nome'] ?? 'N/A'),
                      _buildPrestadorInfoRow('Telefone:', telefone ?? 'N/A'),
                      _buildPrestadorInfoRow('Forma:', agendamento.formaPagamento ?? 'A combinar'),
                      const SizedBox(height: 16),
                      const Text( 'O status será atualizado pelo prestador após confirmar.', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                    ]
                ),
              ),
              actions: [
                TextButton( onPressed: () => Navigator.pop(dialogContext), child: const Text('Entendi')),
                if (canCall)
                  TextButton(
                      onPressed: () async {
                        final Uri url = Uri.parse('tel:$telefone');
                        try { if (await canLaunchUrl(url)) { await launchUrl(url); } } catch (e) { /* Ignore */ }
                      },
                      child: const Text('Ligar agora')
                  ),
              ],
            );
          }
      ).then((_) {
        // Após fechar o dialog, consideramos a "ação" UI concluída.
        print("Dialog de instruções não-PIX fechado. Chamando onSuccess.");
        onSuccess();
      });

    } catch (e) {
      if (!context.mounted) return;
      _hideLoadingDialog(context);
      ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('Erro ao buscar contato: ${e.toString()}'), backgroundColor: Colors.red,));
      print('Erro ao buscar detalhes do prestador: $e');
      onFailure(); // Chama onFailure em caso de erro ao buscar dados
    }
  }

  /// Helper para formatar linha de info do prestador no dialog de instruções.
  static Widget _buildPrestadorInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 15, color: Colors.black87), // Estilo padrão
          children: [
            TextSpan(text: label, style: const TextStyle(fontWeight: FontWeight.bold)),
            TextSpan(text: ' $value'),
          ],
        ),
      ),
    );
  }


  /// Prestador: Verifica manualmente se pagamento PIX foi confirmado no Supabase.
  static void verificarPagamento(BuildContext context, Agendamento agendamento, Function onSuccess, Function onFailure) async {
    if (!context.mounted) return;
    _showLoadingDialog(context, message: 'Verificando Pagamento...');
    try {
      final supabase = Supabase.instance.client;
      bool statusMudouParaConfirmado = false;

      // 1. Verifica na tabela 'pagamentos' se existe um pagamento confirmado
      final pagamentoConfirmado = await supabase.from('pagamentos')
          .select('id_pagamento')
          .eq('id_agendamento', agendamento.idAgendamento)
          .eq('status', 'confirmado') // Busca status 'confirmado' na tabela pagamentos
          .limit(1)
          .maybeSingle();

      if (!context.mounted) return; // Verifica após await

      if (pagamentoConfirmado != null) {
        // 2. Se encontrou pagamento confirmado E o agendamento AINDA está como 'aguardando'
        if (agendamento.status == 'aguardando') {
          print("Verificar Pagamento: Pagamento confirmado encontrado. Atualizando agendamento ${agendamento.idAgendamento} para 'confirmado'.");
          // 3. Atualiza o status do AGENDAMENTO para 'confirmado'
          await AgendamentoService().atualizarStatusAgendamento( agendamento.idAgendamento, 'confirmado');
          statusMudouParaConfirmado = true;
          if (!context.mounted) return; // Verifica após await
          _hideLoadingDialog(context);
          ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Pagamento confirmado! Status do agendamento atualizado.'), backgroundColor: Colors.green));
        } else {
          // Pagamento confirmado, mas agendamento já estava 'confirmado' ou outro status
          _hideLoadingDialog(context);
          print("Verificar Pagamento: Pagamento consta como confirmado, agendamento já está como '${agendamento.status}'.");
          ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('Pagamento já estava confirmado no sistema (Status atual: ${agendamento.status}).'), backgroundColor: Colors.blue));
        }
      } else {
        // Não encontrou pagamento confirmado na tabela 'pagamentos'
        _hideLoadingDialog(context);
        print("Verificar Pagamento: Pagamento para ${agendamento.idAgendamento} ainda não consta como confirmado na tabela de pagamentos.");
        ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Pagamento do cliente ainda não confirmado no sistema.'), backgroundColor: Colors.orange));
      }

      // Chama onSuccess para indicar que a verificação terminou (com ou sem mudança de status).
      // ScheduleScreen vai recarregar e mostrar o status atualizado (se mudou).
      onSuccess();

    } catch (e) {
      if (!context.mounted) return; // Verifica após await (catch)
      _hideLoadingDialog(context);
      ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('Erro ao verificar pagamento: ${e.toString()}'), backgroundColor: Colors.red));
      print('Erro ao verificar pagamento: $e');
      onFailure(); // Chama onFailure em caso de erro na verificação
    }
  }

  /// Prestador: Marca o serviço como concluído (muda status para 'concluído').
  static void marcarComoConcluido(BuildContext context, Agendamento agendamento, Function onSuccess, Function onFailure) async {
    if (!context.mounted) return;
    final bool? confirmou = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) => AlertDialog(
          title: const Text('Confirmar Conclusão'),
          content: const Text('Deseja marcar este serviço como concluído?'),
          actions: [
            TextButton( child: const Text('Cancelar'), onPressed: () => Navigator.pop(dialogContext, false)),
            TextButton( child: const Text('Sim, Concluir'), onPressed: () => Navigator.pop(dialogContext, true)),
          ],
        )
    );

    if (confirmou == true) {
      if (!context.mounted) return;
      _showLoadingDialog(context, message: 'Finalizando...');
      try {
        await AgendamentoService().atualizarStatusAgendamento( agendamento.idAgendamento, 'concluído');
        if (!context.mounted) return;
        _hideLoadingDialog(context);
        ScaffoldMessenger.of(context).showSnackBar( const SnackBar( content: Text('Serviço marcado como concluído!'), backgroundColor: Colors.green));
        onSuccess();
      } catch (e) {
        if (!context.mounted) return;
        _hideLoadingDialog(context);
        print("Erro ao marcar como concluido: $e");
        ScaffoldMessenger.of(context).showSnackBar( SnackBar( content: Text('Erro ao finalizar agendamento: ${e.toString()}'), backgroundColor: Colors.red));
        onFailure();
      }
    }
  }


  /// Cliente: Abre dialog para avaliação (simulação).
  static void avaliarServico(BuildContext context, Agendamento agendamento, Function onSuccess, Function onFailure, Function(BuildContext) closeLocalDialog) {
    if (!context.mounted) return;
    // Mostra dialog para coletar nota e comentário
    showDialog(
        context: context,
        builder: (BuildContext dialogContext) {
          double nota = 3.0;
          final comentarioController = TextEditingController();
          return StatefulBuilder(builder: (context, setStateDialog) { // Usa context interno do builder
            return AlertDialog(
              title: const Text('Avaliar Serviço'),
              content: SingleChildScrollView( /* ... Conteúdo do dialog ... */ ),
              actions: [
                TextButton(
                    child: const Text('Cancelar'),
                    onPressed: () => closeLocalDialog(dialogContext)
                ),
                TextButton(
                    child: const Text('Enviar Avaliação'),
                    onPressed: () async {
                      final int notaInt = nota.toInt();
                      final String comentario = comentarioController.text.trim();
                      print('Avaliação: Agd=${agendamento.idAgendamento}, Nota=$notaInt, Comentário=$comentario');

                      closeLocalDialog(dialogContext); // Fecha este dialog ANTES

                      if (!context.mounted) return; // Verifica contexto original
                      _showLoadingDialog(context, message: "Enviando avaliação...");
                      try {
                        // *** TODO: IMPLEMENTAR LÓGICA REAL DE ENVIO ***
                        await Future.delayed(const Duration(seconds: 1)); // Simulação
                        if (!context.mounted) return;
                        _hideLoadingDialog(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Obrigado pela sua avaliação!'), backgroundColor: Colors.green));
                        onSuccess();
                      } catch (e) {
                        if (!context.mounted) return;
                        _hideLoadingDialog(context);
                        print("Erro ao enviar avaliação (simulada): $e");
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao enviar avaliação.'), backgroundColor: Colors.red));
                        onFailure();
                      }
                    }
                ),
              ],
            );
          });
        }
    );
  }

  /// Cliente/Prestador: Mostra dialog com o motivo da recusa.
  static void verDetalhesRecusa(BuildContext context, Agendamento agendamento, Function onSuccess, Function onFailure, Function(BuildContext) closeLocalDialog) async {
    if (agendamento.status != 'recusado') { onSuccess(); return; }

    String motivo = agendamento.motivoRecusa ?? '';

    if (!context.mounted) return;

    if (motivo.isNotEmpty) {
      showDialog(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
              title: const Text('Motivo da Recusa'),
              content: Text(motivo),
              actions: [ TextButton( onPressed: () => closeLocalDialog(dialogContext), child: const Text('Fechar'))]
          )
      ).then((_) { onSuccess(); }); // Chama onSuccess quando o dialog é fechado
    } else {
      // Tenta buscar no banco (pode ser redundante)
      _showLoadingDialog(context, message: 'Buscando motivo...');
      try {
        Agendamento detalhes = await AgendamentoService().obterDetalhesAgendamento(agendamento.idAgendamento);
        if (!context.mounted) return;
        motivo = detalhes.motivoRecusa ?? 'Motivo não informado.';
        _hideLoadingDialog(context);

        showDialog(
            context: context,
            builder: (BuildContext dialogContext) => AlertDialog(
                title: const Text('Motivo da Recusa'),
                content: Text(motivo),
                actions: [ TextButton( onPressed: () => closeLocalDialog(dialogContext), child: const Text('Fechar'))]
            )
        ).then((_) { onSuccess(); }); // Chama onSuccess quando o dialog é fechado
      } catch (e) {
        if (!context.mounted) return;
        _hideLoadingDialog(context);
        print("Erro ao buscar motivo da recusa: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar motivo: ${e.toString()}'), backgroundColor: Colors.red));
        onFailure(); // Chama onFailure se erro ao buscar
      }
    }
  }

} // Fim da classe AgendamentoActions