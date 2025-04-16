import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/agendamento.dart'; // Verifique o caminho
import 'package:servblu/services/agendamento_service.dart'; // **** IMPORT NECESSÁRIO ****
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentStatusScreen extends StatefulWidget {
  final bool successful;
  final String? errorMessage;
  final String txid;
  final double? valorServico;
  final String prestadorId;
  final String agendamentoId;
  final Agendamento? agendamento;

  const PaymentStatusScreen({
    Key? key,
    required this.successful,
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
  bool _processando = false;
  bool _statusAgendamentoAtualizado = false;
  bool _saldoPrestadorAtualizado = false;
  String? _mensagemErroProcessamento;
  final _supabase = Supabase.instance.client;
  final AgendamentoService _agendamentoService = AgendamentoService();

  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    print("--- PaymentStatusScreen initState ---");
    print("TXID: ${widget.txid}, Successful (PIX): ${widget.successful}, AgendamentoID: ${widget.agendamentoId}");
    print("------------------------------------");

    if (widget.successful) {
      bool dataOk = true;
      String validationError = "";
      if (widget.txid.isEmpty || widget.txid.contains("ERRO_")) { validationError = "ID da Transação PIX inválido"; dataOk = false; }
      else if (widget.prestadorId.isEmpty || widget.prestadorId.contains("ERRO_")) { validationError = "ID do Prestador inválido"; dataOk = false; }
      else if (widget.agendamentoId.isEmpty || widget.agendamentoId.contains("ERRO_")) { validationError = "ID do Agendamento inválido"; dataOk = false; }
      else if (widget.valorServico == null || widget.valorServico! <= 0) { validationError = "Valor do serviço inválido"; dataOk = false; }

      if (!dataOk) {
        print("ERRO FATAL no initState PaymentStatusScreen: $validationError");
        if (mounted) {
          setState(() {
            _mensagemErroProcessamento = "Erro interno: $validationError. Não foi possível processar.";
            _processando = false;
          });
        }
      } else {
        print("initState PaymentStatusScreen: Dados validados. Iniciando processamento completo...");
        _processarPagamentoCompletoComLock();
      }
    } else {
      print("initState PaymentStatusScreen: Pagamento PIX não foi bem-sucedido. Nenhum processamento iniciado.");
      _processando = false;
    }
  }

  Future<void> _processarPagamentoCompletoComLock() async {
    if (_isProcessing) {
      print("Lock Geral: Ignorando chamada duplicada (txid: ${widget.txid})");
      return;
    }
    _isProcessing = true;
    print("Lock Geral: Ativado para txid ${widget.txid}.");

    if (mounted) {
      setState(() { _processando = true; _mensagemErroProcessamento = null; });
    }

    bool agendamentoStatusOk = false;
    bool saldoOk = false;

    try {
      agendamentoStatusOk = await _atualizarStatusAgendamentoParaConfirmado();
      if (agendamentoStatusOk) {
        if(mounted) setState(() => _statusAgendamentoAtualizado = true);
        saldoOk = await _atualizarSaldoPrestador();
        if(saldoOk && mounted) setState(() => _saldoPrestadorAtualizado = true);
      }
    } catch (e) {
      print("Erro GERAL inesperado em _processarPagamentoCompleto: $e");
      if(mounted) { setState(() { _mensagemErroProcessamento = "Erro inesperado: ${e.toString()}"; }); }
    } finally {
      if (mounted) { setState(() { _processando = false; }); }
      _isProcessing = false;
      print("Lock Geral: Liberado para txid ${widget.txid}. (AgendamentoOK: $agendamentoStatusOk, SaldoOK: $saldoOk).");
    }
  }

  Future<bool> _atualizarStatusAgendamentoParaConfirmado() async {
    print("_atualizarStatusAgendamento: Atualizando agendamento ${widget.agendamentoId} para 'confirmado'.");
    try {
      final currentAgendamento = await _supabase.from('agendamentos').select('status').eq('id_agendamento', widget.agendamentoId).maybeSingle();
      if (currentAgendamento != null && currentAgendamento['status'] == 'confirmado') {
        print("_atualizarStatusAgendamento: Agendamento ${widget.agendamentoId} já estava 'confirmado'. OK.");
        return true;
      }
      await _agendamentoService.atualizarStatusAgendamento( widget.agendamentoId, 'confirmado');
      print("_atualizarStatusAgendamento: Agendamento ${widget.agendamentoId} atualizado para 'confirmado' com sucesso.");
      return true;
    } catch (e) {
      print("ERRO ao atualizar status do agendamento ${widget.agendamentoId}: $e");
      if (mounted) { setState(() { _mensagemErroProcessamento = "Erro ao confirmar agendamento: ${e.toString()}"; _statusAgendamentoAtualizado = false; }); }
      return false;
    }
  }

  Future<bool> _registrarPagamento() async {
    final String tabelaPagamentos = 'pagamentos';
    print("_registrarPagamento: Iniciando para txid ${widget.txid} na tabela '$tabelaPagamentos'");
    try {
      final existingPayment = await _supabase.from(tabelaPagamentos).select('id_pagamento').eq('pix_transaction_id', widget.txid).limit(1).maybeSingle();
      if (existingPayment != null) { print('_registrarPagamento: Pagamento (txid: ${widget.txid}) já existe. OK.'); return true; }
      print('_registrarPagamento: Pagamento (txid: ${widget.txid}) não encontrado. Tentando inserir...');
      final pagamentoData = { 'id_agendamento': widget.agendamentoId, 'valor': widget.valorServico, 'is_pix': true, 'pix_transaction_id': widget.txid, 'data_pagamento': DateTime.now().toIso8601String(), 'status': 'confirmado', 'status_saldo': 'pendente' };
      await _supabase.from(tabelaPagamentos).insert(pagamentoData);
      print('_registrarPagamento: Pagamento (txid: ${widget.txid}) inserido com sucesso.'); return true;
    } on PostgrestException catch (error) {
      if (error.code == '23505') { print('_registrarPagamento: Ignorando erro de chave duplicada (23505) para txid ${widget.txid}. OK.'); return true; }
      else { print('_registrarPagamento: Erro DB inesperado para txid ${widget.txid}: code=${error.code}, message=${error.message}'); if(mounted) setState(() => _mensagemErroProcessamento = 'Erro DB ao registrar pag.: ${error.message}'); return false; }
    } catch (error) { print('_registrarPagamento: Erro genérico para txid ${widget.txid}: $error'); if(mounted) setState(() => _mensagemErroProcessamento = 'Erro geral ao registrar pag.: ${error.toString()}'); return false; }
  }

  Future<bool> _atualizarSaldoPrestador() async {
    final String tabelaPagamentos = 'pagamentos'; final String tabelaUsuarios = 'usuarios'; final String colIdPagamento = 'id_pagamento'; final String colPixTxId = 'pix_transaction_id'; final String colStatusSaldo = 'status_saldo'; final String colIdUsuario = 'id_usuario'; final String colSaldoUsuario = 'saldo';
    bool success = false;
    try {
      print("_atualizarSaldoPrestador: Iniciando saldo txid ${widget.txid}.");
      bool registroOk = await _registrarPagamento(); if (!registroOk) { print("_atualizarSaldoPrestador: Falha registro pag txid ${widget.txid}. Abortando saldo."); return false; }
      print("_atualizarSaldoPrestador: Registro OK. Marcando $colStatusSaldo 'processado'...");
      final updateResponse = await _supabase.from(tabelaPagamentos).update({colStatusSaldo: 'processado'}).eq(colPixTxId, widget.txid).neq(colStatusSaldo, 'processado').select(colIdPagamento).maybeSingle();
      if (updateResponse == null) { print("_atualizarSaldoPrestador: $colStatusSaldo já 'processado' txid ${widget.txid}. OK."); success = true; return success; }
      print("_atualizarSaldoPrestador: Marcação $colStatusSaldo OK. Buscando user ${widget.prestadorId}...");
      final userResponse = await _supabase.from(tabelaUsuarios).select(colSaldoUsuario).eq(colIdUsuario, widget.prestadorId).maybeSingle();
      if (userResponse == null) { print("ERRO CRÍTICO _atualizarSaldoPrestador: Prestador ${widget.prestadorId} NÃO ENCONTRADO (txid: ${widget.txid})."); await _supabase.from(tabelaPagamentos).update({colStatusSaldo: 'falha_usuario_nao_encontrado'}).eq(colPixTxId, widget.txid); if (mounted) setState(() => _mensagemErroProcessamento = 'Erro Crítico: Prestador não encontrado.'); return false; }
      print("_atualizarSaldoPrestador: User ${widget.prestadorId} encontrado. Atualizando saldo...");
      double saldoAtual = (userResponse[colSaldoUsuario] as num?)?.toDouble() ?? 0.0; double novoSaldo = saldoAtual + widget.valorServico!;
      await _supabase.from(tabelaUsuarios).update({colSaldoUsuario: novoSaldo}).eq(colIdUsuario, widget.prestadorId);
      print("_atualizarSaldoPrestador: Saldo user ${widget.prestadorId} atualizado. Sucesso."); success = true; return success;
    } catch (error) {
      print("_atualizarSaldoPrestador: ERRO INESPERADO saldo txid ${widget.txid}: $error");
      bool showErrorInUI = true; if (error is PostgrestException && error.code == 406 && (error.message.contains('PGRST116') || error.message.contains('0 rows'))) { print("Erro PGRST116/406 ignorado UI txid: ${widget.txid}."); showErrorInUI = false; }
      if (mounted && showErrorInUI) { setState(() { _mensagemErroProcessamento = 'Erro saldo: ${error.toString().split('\n').first}'; }); }
      try { final String statusRevert = showErrorInUI ? 'falha_processamento_saldo' : 'aviso_concorrencia_saldo'; await _supabase.from(tabelaPagamentos).update({colStatusSaldo: statusRevert}).eq(colPixTxId, widget.txid); } catch (_) {}
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    String? displayError = _mensagemErroProcessamento ?? widget.errorMessage;
    bool showSuccessMessage = widget.successful && _statusAgendamentoAtualizado && _saldoPrestadorAtualizado && !_processando && displayError == null;
    bool isFullySuccessful = showSuccessMessage;

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
              Icon(
                isFullySuccessful ? Icons.check_circle : Icons.error,
                color: isFullySuccessful ? Colors.green : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                widget.successful
                    ? (showSuccessMessage ? 'Pagamento e Agendamento Confirmados!' : (displayError!= null ? 'Erro no Processamento' : ( _processando ? 'Processando...' : 'Pagamento PIX Confirmado')))
                    : 'Falha no Pagamento PIX',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isFullySuccessful ? Colors.green : (widget.successful ? Colors.orange : Colors.red),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // --- Detalhes do Processamento ---
              if (_processando)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Aguarde, processando informações...'),
                  ],
                ),

              // Mensagem de Sucesso Total
              if (showSuccessMessage)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Seu agendamento está confirmado e o saldo do prestador foi atualizado.',
                    style: TextStyle(fontSize: 16, color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Mensagem de Sucesso Parcial (Agendamento OK, erro/pendente no saldo)
              if (widget.successful && _statusAgendamentoAtualizado && !_saldoPrestadorAtualizado && !_processando && displayError == null)
                const Padding( // Caso de já ter sido processado antes
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Seu agendamento foi confirmado! (O saldo já havia sido processado).',
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Mensagem de ERRO (Geral ou de Processamento)
              if (displayError != null && !_processando)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    displayError,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              // --- Fim Detalhes do Processamento ---

              const SizedBox(height: 8),
              Text( 'ID PIX: ${widget.txid}', style: const TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
              if (widget.successful && widget.valorServico != null)
                Text( 'Valor: R\$ ${widget.valorServico!.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: () {
                  print("PaymentStatusScreen: Botão 'Voltar' pressionado. Voltando para ScheduleScreen via popUntil.");
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Voltar para Agendamentos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}