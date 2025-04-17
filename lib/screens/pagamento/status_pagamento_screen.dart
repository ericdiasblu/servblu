import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/agendamento.dart';
import 'package:servblu/services/agendamento_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/tool_loading.dart';

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
  bool _processandoBackend = false;
  bool _statusAgendamentoAtualizado = false;
  bool _saldoPrestadorAtualizado = false;
  String? _mensagemErroProcessamentoBackend;
  final _supabase = Supabase.instance.client;
  final AgendamentoService _agendamentoService = AgendamentoService();
  bool _isProcessingDatabase = false;
  bool _finalBackendResult = false;

  @override
  void initState() {
    super.initState();
    print("--- PaymentStatusScreen initState ---");
    print("PIX Success ANTES da Tela: ${widget.successful}, TXID: ${widget.txid}, AgendamentoID: ${widget.agendamentoId}, PrestadorID: ${widget.prestadorId}, Valor: ${widget.valorServico}");
    print("Erro PIX pré-tela (se houver): ${widget.errorMessage}");
    print("------------------------------------");

    if (widget.successful &&
        widget.agendamentoId.isNotEmpty && !widget.agendamentoId.contains("ERRO_") &&
        widget.prestadorId.isNotEmpty && !widget.prestadorId.contains("ERRO_") &&
        widget.txid.isNotEmpty && !widget.txid.contains("ERRO_") &&
        widget.valorServico != null && widget.valorServico! > 0)
    {
      print("initState PaymentStatusScreen: PIX OK inicial. Iniciando processamento no backend...");
      _processarPagamentoCompletoComLock();
    } else if (!widget.successful) {
      print("initState PaymentStatusScreen: PIX falhou ANTES desta tela. Nenhum processamento backend.");
      _processandoBackend = false;
      _finalBackendResult = false;
    } else {
      print("ERRO FATAL no initState PaymentStatusScreen: Dados inválidos recebidos, apesar do PIX ter sido 'successful' antes. Abortando.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted) {
          setState(() {
            _mensagemErroProcessamentoBackend = "Erro interno: Dados inválidos (${widget.agendamentoId}, ${widget.prestadorId}, etc).";
            _processandoBackend = false;
            _finalBackendResult = false;
          });
        }
      });
    }
  }

  Future<void> _processarPagamentoCompletoComLock() async {
    // O código para esta função e as outras funções de processamento permanecem os mesmos
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
    bool processamentoGeralOk = false;

    try {
      agendamentoStatusOk = await _atualizarStatusAgendamentoParaConfirmado();

      if (agendamentoStatusOk) {
        if (mounted) setState(() => _statusAgendamentoAtualizado = true);
        saldoOk = await _atualizarSaldoPrestador();
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
      processamentoGeralOk = false;
    } finally {
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

  // Mantenha os métodos existentes: _atualizarStatusAgendamentoParaConfirmado, _registrarPagamento, _atualizarSaldoPrestador
  Future<bool> _atualizarStatusAgendamentoParaConfirmado() async {
    // Código existente...
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

  Future<bool> _registrarPagamento() async {
    // Código existente...
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

  Future<bool> _atualizarSaldoPrestador() async {
    // Código existente...
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
    // Erro combinado: prioriza erro do backend, senão erro do PIX
    String? displayError = _mensagemErroProcessamentoBackend ?? widget.errorMessage;

    // Condição de sucesso REAL (PIX foi OK ANTES + Backend processou TUDO OK AGORA)
    bool isFullySuccessful = widget.successful &&
        _statusAgendamentoAtualizado &&
        _saldoPrestadorAtualizado &&
        !_processandoBackend &&
        _mensagemErroProcessamentoBackend == null;

    // Condição de Falha no PIX (antes de chegar aqui)
    bool isPixFailure = !widget.successful;

    // Condição de Falha no Backend (PIX foi OK antes, mas algo falhou aqui)
    bool isBackendFailure = widget.successful && !_finalBackendResult && !_processandoBackend;

    // Definindo cores e ícones baseados no status
    IconData statusIcon;
    Color statusColor;
    String titleMessage;
    String? subMessage;

    if (_processandoBackend) {
      statusIcon = Icons.hourglass_empty;
      statusColor = const Color(0xFF017DFE); // Cor principal do app
      titleMessage = 'Processando Pagamento';
      subMessage = 'Aguarde um momento...';
    } else if (isFullySuccessful) {
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
      titleMessage = 'Pagamento Confirmado';
      subMessage = 'Seu agendamento foi confirmado com sucesso!';
    } else if (isPixFailure) {
      statusIcon = Icons.error;
      statusColor = Colors.red;
      titleMessage = 'Falha no Pagamento';
      subMessage = widget.errorMessage;
    } else if (isBackendFailure) {
      statusIcon = Icons.warning;
      statusColor = Colors.orange;
      titleMessage = 'Erro no Processamento';
      subMessage = _mensagemErroProcessamentoBackend;
    } else {
      statusIcon = Icons.help_outline;
      statusColor = Colors.grey;
      titleMessage = 'Status Indefinido';
      subMessage = 'Não foi possível determinar o status do pagamento.';
    }

    return Scaffold(
      body: Container(
        color: const Color(0xFFF3F3F3), // Mesma cor de fundo da HomePageContent
        child: Column(
            children: [
              // Header com estilo similar ao da HomePageContent
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF017DFE),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: const EdgeInsets.only(top: 50,bottom: 20,left: 30,right: 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context, _finalBackendResult);
                          },
                        ),
                        const SizedBox(width: 20),
                        const Text(
                          "Status do Pagamento",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Conteúdo principal
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        // Card de status
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 2,
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Ícone de status
                              _processandoBackend
                                  ? SizedBox(
                                height: 80,
                                width: 80,
                                child: ToolLoadingIndicator(color: Colors.blue, size: 45)
                              )
                                  : Icon(
                                statusIcon,
                                color: statusColor,
                                size: 80,
                              ),
                              const SizedBox(height: 24),
                              // Título
                              Text(
                                titleMessage,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              // Mensagem secundária
                              if (subMessage != null)
                                Text(
                                  subMessage,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              const SizedBox(height: 24),
                              // Linha separadora
                              Divider(color: Colors.grey.withOpacity(0.3)),
                              const SizedBox(height: 24),
                              // Detalhes da transação
                              _buildTransactionDetail(
                                'ID da Transação',
                                widget.txid,
                                Icons.receipt,
                              ),
                              const SizedBox(height: 16),
                              if (widget.valorServico != null)
                                _buildTransactionDetail(
                                  'Valor',
                                  'R\$ ${widget.valorServico!.toStringAsFixed(2)}',
                                  Icons.attach_money,
                                ),
                              if (isFullySuccessful) ...[
                                const SizedBox(height: 16),
                                _buildTransactionDetail(
                                  'Status',
                                  'Confirmado',
                                  Icons.verified,
                                  valueColor: Colors.green,
                                ),
                              ],
                              if (isPixFailure || isBackendFailure) ...[
                                const SizedBox(height: 16),
                                _buildTransactionDetail(
                                  'Status',
                                  isPixFailure ? 'Falha no PIX' : 'Erro de Processamento',
                                  Icons.error_outline,
                                  valueColor: Colors.red,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Botão de voltar para agendamentos
                        ElevatedButton(
                          onPressed: () {
                            print("Botão 'Voltar' pressionado. Retornando resultado: $_finalBackendResult");
                            Navigator.pop(context, _finalBackendResult);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF017DFE),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Voltar para Agendamentos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
      ),
    );
  }

  // Widget para detalhes da transação
  Widget _buildTransactionDetail(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF017DFE).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF017DFE),
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}