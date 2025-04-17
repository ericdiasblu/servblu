import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/agendamento.dart'; // Verifique o caminho
import 'package:servblu/services/agendamento_service.dart'; // **** IMPORT NECESSÁRIO ****
import 'package:supabase_flutter/supabase_flutter.dart';
// Importar Provider se precisar chamar refresh do provider de agendamentos
// import 'package:provider/provider.dart';
// import 'package:servblu/providers/agendamento_provider.dart'; // Exemplo

class PaymentStatusScreen extends StatefulWidget {
  final bool successful; // Indica se o PIX foi CONCLUIDA (ou similar) ANTES de chamar esta tela
  final String? errorMessage; // Mensagem de erro da API PIX ou validação interna da PaymentScreen
  final String txid;
  final double? valorServico; // Valor pode ser nulo se houve erro antes
  final String prestadorId; // Pode ser placeholder de erro
  final String agendamentoId; // Pode ser placeholder de erro
  final Agendamento? agendamento; // Agendamento original

  const PaymentStatusScreen({
    Key? key,
    required this.successful, // Este é o status do PIX que levou a esta tela
    this.errorMessage,
    required this.txid,
    required this.valorServico,
    required this.prestadorId,
    required this.agendamentoId,
    this.agendamento,
  }) : super(key: key);

  @override
  State<PaymentStatusScreen> createState() => _PaymentStatusScreenState();
}

class _PaymentStatusScreenState extends State<PaymentStatusScreen> {
  bool _processandoBackend = false;
  bool _statusAgendamentoAtualizado = false;
  bool _saldoPrestadorAtualizado = false;
  String? _mensagemErroProcessamentoBackend;
  final _supabase = Supabase.instance.client;
  final AgendamentoService _agendamentoService = AgendamentoService();
  bool _isProcessingDatabase = false;

  // Guarda o resultado final do processamento backend para retornar
  bool _finalBackendResult = false;

  @override
  void initState() {
    super.initState();
    print("--- PaymentStatusScreen initState ---");
    print("PIX Success ANTES da Tela: ${widget.successful}, TXID: ${widget.txid}, AgendamentoID: ${widget.agendamentoId}, PrestadorID: ${widget.prestadorId}, Valor: ${widget.valorServico}");
    print("Erro PIX pré-tela (se houver): ${widget.errorMessage}");
    print("------------------------------------");

    // Só tenta processar no backend se o pagamento PIX foi considerado bem-sucedido PELA TELA ANTERIOR
    if (widget.successful &&
        widget.agendamentoId.isNotEmpty && !widget.agendamentoId.contains("ERRO_") &&
        widget.prestadorId.isNotEmpty && !widget.prestadorId.contains("ERRO_") &&
        widget.txid.isNotEmpty && !widget.txid.contains("ERRO_") &&
        widget.valorServico != null && widget.valorServico! > 0)
    {
      print("initState PaymentStatusScreen: PIX OK inicial. Iniciando processamento no backend...");
      _processarPagamentoCompletoComLock(); // Não precisa de await aqui
    } else if (!widget.successful) {
      print("initState PaymentStatusScreen: PIX falhou ANTES desta tela. Nenhum processamento backend.");
      _processandoBackend = false;
      _finalBackendResult = false; // Garante que o resultado retornado será false
    } else {
      print("ERRO FATAL no initState PaymentStatusScreen: Dados inválidos recebidos, apesar do PIX ter sido 'successful' antes. Abortando.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted) {
          setState(() {
            _mensagemErroProcessamentoBackend = "Erro interno: Dados inválidos (${widget.agendamentoId}, ${widget.prestadorId}, etc).";
            _processandoBackend = false;
            _finalBackendResult = false; // Garante que o resultado retornado será false
          });
        }
      });
    }
  }

  Future<void> _processarPagamentoCompletoComLock() async {
    if (_isProcessingDatabase) {
      print("Lock DB: Ignorando chamada duplicada para processar txid: ${widget.txid}");
      return;
    }
    _isProcessingDatabase = true;
    print("Lock DB: Ativado para txid ${widget.txid}.");

    if (mounted) {
      setState(() {
        _processandoBackend = true;
        _mensagemErroProcessamentoBackend = null;
      });
    }

    bool agendamentoStatusOk = false;
    bool saldoOk = false;
    bool processamentoGeralOk = false; // Flag geral do backend

    try {
      agendamentoStatusOk = await _atualizarStatusAgendamentoParaConfirmado();

      if (agendamentoStatusOk) {
        if (mounted) setState(() => _statusAgendamentoAtualizado = true);
        saldoOk = await _atualizarSaldoPrestador(); // Já tem idempotência
        if (saldoOk && mounted) {
          setState(() => _saldoPrestadorAtualizado = true);
        } else if (!saldoOk && mounted && _mensagemErroProcessamentoBackend == null) {
          setState(() => _mensagemErroProcessamentoBackend = "Falha ao atualizar saldo.");
        }
      } else {
        if (mounted && _mensagemErroProcessamentoBackend == null) {
          setState(() => _mensagemErroProcessamentoBackend = "Falha ao confirmar agendamento.");
        }
      }
      // Define o sucesso geral do backend
      processamentoGeralOk = agendamentoStatusOk && saldoOk;

    } catch (e) {
      print("Erro GERAL inesperado em _processarPagamentoCompletoComLock: $e");
      if (mounted) {
        setState(() {
          _mensagemErroProcessamentoBackend = "Erro inesperado: ${e.toString()}";
          _statusAgendamentoAtualizado = false;
          _saldoPrestadorAtualizado = false;
        });
      }
      processamentoGeralOk = false; // Falha geral
    } finally {
      // Define o resultado final que será retornado ao fechar a tela
      _finalBackendResult = processamentoGeralOk;
      print("Processamento Backend Finalizado. Resultado final: $_finalBackendResult");

      if (mounted) {
        setState(() {
          _processandoBackend = false;
        });
      }
      _isProcessingDatabase = false;
      print("Lock DB: Liberado para txid ${widget.txid}. (GeralOK: $processamentoGeralOk)");
    }
  }

  // Função _atualizarStatusAgendamentoParaConfirmado (sem alterações)
  Future<bool> _atualizarStatusAgendamentoParaConfirmado() async {
    print("_atualizarStatusAgendamento: Tentando agendamento ${widget.agendamentoId} para 'confirmado'.");
    try {
      final currentAgendamento = await _supabase
          .from('agendamentos')
          .select('status')
          .eq('id_agendamento', widget.agendamentoId)
          .maybeSingle();

      if (currentAgendamento != null && currentAgendamento['status'] == 'confirmado') {
        print("_atualizarStatusAgendamento: Agendamento ${widget.agendamentoId} já estava 'confirmado'. OK.");
        return true;
      }

      await _agendamentoService.atualizarStatusAgendamento(
          widget.agendamentoId, 'confirmado'
      );
      print("_atualizarStatusAgendamento: Agendamento ${widget.agendamentoId} atualizado para 'confirmado' com sucesso.");
      return true;

    } catch (e) {
      print("ERRO ao atualizar status do agendamento ${widget.agendamentoId} para confirmado: $e");
      if (mounted) {
        setState(() {
          _mensagemErroProcessamentoBackend = "Erro ao confirmar agendamento: ${e.toString()}";
          _statusAgendamentoAtualizado = false;
        });
      }
      return false;
    }
  }

  // Função _registrarPagamento (sem alterações)
  Future<bool> _registrarPagamento() async {
    final String tabelaPagamentos = 'pagamentos';
    print("_registrarPagamento: Verificando/Inserindo txid ${widget.txid} em '$tabelaPagamentos'");
    try {
      final existingPayment = await _supabase
          .from(tabelaPagamentos)
          .select('id_pagamento')
          .eq('pix_transaction_id', widget.txid)
          .limit(1)
          .maybeSingle();

      if (existingPayment != null) {
        print('_registrarPagamento: Pagamento (txid: ${widget.txid}) já existe. OK.');
        return true;
      }

      print('_registrarPagamento: Pagamento (txid: ${widget.txid}) não encontrado. Inserindo...');
      final pagamentoData = {
        'id_agendamento': widget.agendamentoId,
        'valor': widget.valorServico,
        'is_pix': true,
        'pix_transaction_id': widget.txid,
        'data_pagamento': DateTime.now().toIso8601String(),
        'status': 'confirmado',
        'status_saldo': 'pendente'
      };
      await _supabase.from(tabelaPagamentos).insert(pagamentoData);
      print('_registrarPagamento: Pagamento (txid: ${widget.txid}) inserido.');
      return true;

    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        print('_registrarPagamento: Ignorando erro de chave duplicada (23505) para txid ${widget.txid}. OK.');
        return true;
      } else {
        print('_registrarPagamento: Erro DB inesperado txid ${widget.txid}: code=${error.code}, msg=${error.message}');
        if (mounted) setState(() => _mensagemErroProcessamentoBackend = 'Erro DB ao registrar pagamento: ${error.message}');
        return false;
      }
    } catch (error) {
      print('_registrarPagamento: Erro genérico txid ${widget.txid}: $error');
      if (mounted) setState(() => _mensagemErroProcessamentoBackend = 'Erro geral ao registrar pagamento: ${error.toString()}');
      return false;
    }
  }

  // Função _atualizarSaldoPrestador (sem alterações)
  Future<bool> _atualizarSaldoPrestador() async {
    final String tabelaPagamentos = 'pagamentos';
    final String tabelaUsuarios = 'usuarios';
    final String colIdPagamento = 'id_pagamento';
    final String colPixTxId = 'pix_transaction_id';
    final String colStatusSaldo = 'status_saldo';
    final String colIdUsuario = 'id_usuario';
    final String colSaldoUsuario = 'saldo';

    print("_atualizarSaldoPrestador: Iniciando saldo txid ${widget.txid}.");

    // 1. Garante registro
    bool registroOk = await _registrarPagamento();
    if (!registroOk) {
      print("_atualizarSaldoPrestador: Falha registro txid: ${widget.txid}. Abortando saldo.");
      return false;
    }
    print("_atualizarSaldoPrestador: Registro OK. Marcando status_saldo 'processado'...");

    // 2. Marca pagamento como 'processado' atomicamente
    try {
      final updateResponse = await _supabase
          .from(tabelaPagamentos)
          .update({colStatusSaldo: 'processado'})
          .eq(colPixTxId, widget.txid)
          .neq(colStatusSaldo, 'processado')
          .select(colIdPagamento)
          .maybeSingle();

      if (updateResponse == null) {
        print("_atualizarSaldoPrestador: Saldo txid ${widget.txid} já 'processado' ou não encontrado pendente. OK.");
        return true; // Idempotente
      }

      print("_atualizarSaldoPrestador: Status saldo txid ${widget.txid} (Pag: ${updateResponse[colIdPagamento]}) marcado 'processado'. Atualizando saldo prestador ${widget.prestadorId}...");

      // 3. Atualiza saldo do prestador
      final userResponse = await _supabase
          .from(tabelaUsuarios)
          .select(colSaldoUsuario)
          .eq(colIdUsuario, widget.prestadorId)
          .maybeSingle();

      if (userResponse == null) {
        print("ERRO CRÍTICO _atualizarSaldoPrestador: Prestador ${widget.prestadorId} NÃO ENCONTRADO (txid: ${widget.txid}). Revertendo status_saldo.");
        await _supabase
            .from(tabelaPagamentos)
            .update({colStatusSaldo: 'falha_usuario_nao_encontrado'})
            .eq(colPixTxId, widget.txid);
        if (mounted) setState(() => _mensagemErroProcessamentoBackend = 'Erro Crítico: Prestador não encontrado.');
        return false;
      }

      double saldoAtual = (userResponse[colSaldoUsuario] as num?)?.toDouble() ?? 0.0;
      double valorASomar = widget.valorServico!;
      double novoSaldo = saldoAtual + valorASomar;

      await _supabase
          .from(tabelaUsuarios)
          .update({colSaldoUsuario: novoSaldo})
          .eq(colIdUsuario, widget.prestadorId);

      print("_atualizarSaldoPrestador: Saldo prestador ${widget.prestadorId} atualizado para $novoSaldo (txid: ${widget.txid}).");
      return true;

    } catch (error) {
      print("_atualizarSaldoPrestador: ERRO INESPERADO saldo/status txid ${widget.txid}: $error");
      String statusRevert = 'falha_processamento_saldo';
      if (error is PostgrestException && error.code == 'PGRST116') {
        print("Aviso: Erro concorrência (PGRST116) txid ${widget.txid}. Provável outra chamada. Marcando aviso.");
        statusRevert = 'aviso_concorrencia_saldo';
      }

      try {
        await _supabase
            .from(tabelaPagamentos)
            .update({colStatusSaldo: statusRevert})
            .eq(colPixTxId, widget.txid);
      } catch (revertError) {
        print("Erro ao reverter status_saldo para $statusRevert (txid: ${widget.txid}): $revertError");
      }

      if (mounted) {
        setState(() {
          _mensagemErroProcessamentoBackend = 'Erro ao processar saldo: ${error.toString().split('\n').first}';
          _saldoPrestadorAtualizado = false;
        });
      }
      return false;
    }
  }


  @override
  Widget build(BuildContext context) {
    // Erro combinado: prioriza erro do backend, senão erro do PIX (que veio da tela anterior)
    String? displayError = _mensagemErroProcessamentoBackend ?? widget.errorMessage;

    // Condição de sucesso REAL (PIX foi OK ANTES + Backend processou TUDO OK AGORA)
    bool isFullySuccessful = widget.successful && // PIX foi OK antes
        _statusAgendamentoAtualizado && // Backend: Agendamento OK
        _saldoPrestadorAtualizado &&    // Backend: Saldo OK
        !_processandoBackend &&         // Backend: Não está mais processando
        _mensagemErroProcessamentoBackend == null; // Backend: Sem erros

    // Condição de Falha no PIX (antes de chegar aqui)
    bool isPixFailure = !widget.successful;

    // Condição de Falha no Backend (PIX foi OK antes, mas algo falhou aqui)
    bool isBackendFailure = widget.successful && !_finalBackendResult && !_processandoBackend;


    IconData statusIcon;
    Color statusColor;
    String titleMessage;

    if (_processandoBackend) {
      statusIcon = Icons.hourglass_empty;
      statusColor = Colors.blue;
      titleMessage = 'Processando Confirmação...';
    } else if (isFullySuccessful) {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
      titleMessage = 'Pagamento Confirmado!';
    } else if (isPixFailure) {
      statusIcon = Icons.error;
      statusColor = Colors.red;
      // Usa o erro que veio da PaymentScreen se houver, senão msg genérica
      titleMessage = widget.errorMessage ?? 'Falha no Pagamento PIX';
    } else if (isBackendFailure) {
      statusIcon = Icons.warning;
      statusColor = Colors.orange;
      // Usa o erro específico do backend se houver, senão msg genérica
      titleMessage = _mensagemErroProcessamentoBackend ?? 'Erro no Processamento Interno';
    } else { // Fallback
      statusIcon = Icons.help_outline;
      statusColor = Colors.grey;
      titleMessage = 'Status Indefinido';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Status do Pagamento'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(statusIcon, color: statusColor, size: 80),
              const SizedBox(height: 24),
              Text(
                titleMessage,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: statusColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Detalhes do Processamento Backend (Loading ou Resultado)
              if (_processandoBackend)
                const Column( children: [ CircularProgressIndicator(), SizedBox(height: 12), Text('Confirmando no sistema...', style: TextStyle(fontSize: 14)), ],),

              // Mensagem de Sucesso Total (Backend OK)
              if (isFullySuccessful)
                const Padding( padding: EdgeInsets.only(top: 8.0), child: Text( 'Seu agendamento foi confirmado.', style: TextStyle(fontSize: 16, color: Colors.black87), textAlign: TextAlign.center,),),

              // Mensagem de ERRO (PIX ou Backend) - Exibe APENAS se não estiver mais processando
              if (displayError != null && !_processandoBackend && !isFullySuccessful)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text( displayError, style: const TextStyle(fontSize: 16, color: Colors.red), textAlign: TextAlign.center,),
                ),

              const SizedBox(height: 24),

              // Detalhes Fixos
              Text('ID Transação PIX: ${widget.txid}', style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
              if (widget.valorServico != null && widget.valorServico! > 0)
                Text('Valor Pago: R\$ ${widget.valorServico!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 32),

              // Botão para voltar
              ElevatedButton(
                onPressed: () {
                  // **** MODIFICAÇÃO: Usa pop com o resultado FINAL do backend ****
                  // Se estava processando backend, _finalBackendResult terá true/false.
                  // Se PIX falhou antes, _finalBackendResult é false.
                  // Se houve erro de dados inválidos, _finalBackendResult é false.
                  print("PaymentStatusScreen: Botão 'Voltar' pressionado. Retornando resultado: $_finalBackendResult");
                  Navigator.pop(context, _finalBackendResult);
                },
                style: ElevatedButton.styleFrom( padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15), textStyle: const TextStyle(fontSize: 16) ),
                child: const Text('Voltar para Agendamentos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}