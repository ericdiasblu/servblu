import 'dart:async'; // Necessário para Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servblu/models/servicos/agendamento.dart'; // Verifique o caminho
import 'package:servblu/providers/pix_provider.dart'; // Verifique o caminho
import 'package:servblu/screens/pagamento/status_pagamento_screen.dart'; // Verifique o caminho
import 'package:servblu/widgets/pix_qrcode_widget.dart'; // Verifique o caminho

class PaymentScreen extends StatefulWidget {
  final String description;
  final Agendamento agendamento;

  const PaymentScreen({
    Key? key,
    required this.description,
    required this.agendamento,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isNavigating = false; // Lock de navegação unificado
  Timer? _periodicCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Validação inicial
      if (widget.agendamento.idAgendamento.isEmpty || widget.agendamento.idPrestador.isEmpty) {
        print("ERRO FATAL PaymentScreen initState: Dados do Agendamento inválidos.");
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Erro interno: Dados do agendamento inválidos.')));
          Navigator.maybePop(context);
        }
        return;
      }
      _initializePayment();
    });
  }

  /// Inicializa a criação da cobrança PIX.
  void _initializePayment() {
    final pixProvider = Provider.of<PixProvider>(context, listen: false);
    pixProvider.clear();

    double valorServico = (widget.agendamento.precoServico ?? 1.0);
    if (valorServico < 0.01) valorServico = 0.01;

    print("PaymentScreen: Iniciando criação de cobrança PIX (Valor: $valorServico)...");
    pixProvider.createCharge( amount: valorServico, description: widget.description,)
        .then((_) {
      if (mounted && pixProvider.currentCharge != null) {
        print("Cobrança PIX criada (txid: ${pixProvider.currentCharge!.txid}). Iniciando verificação periódica.");
        _startPeriodicCheck(context, pixProvider);
      } else if (mounted) {
        print("Falha ao criar cobrança PIX ou provider não atualizou.");
      }
    }).catchError((error) {
      print("Erro CRÍTICO ao criar cobrança PIX: $error");
    });
  }

  @override
  void dispose() {
    _periodicCheckTimer?.cancel();
    print("PaymentScreen dispose: Timer cancelado.");
    super.dispose();
  }

  /// Inicia o Timer para verificar o status do PIX periodicamente.
  void _startPeriodicCheck(BuildContext context, PixProvider pixProvider) {
    _periodicCheckTimer?.cancel();
    print("Iniciando nova verificação periódica (intervalo: 10s).");

    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_isNavigating && pixProvider.currentCharge != null) {
        print("Timer: Verificando status (txid: ${pixProvider.currentCharge!.txid})...");
        _checkPaymentStatus(context, pixProvider, isPeriodic: true);
      } else {
        print("Timer: Verificação periódica cancelada (mounted: $mounted, navigating: $_isNavigating, chargeExists: ${pixProvider.currentCharge != null}).");
        timer.cancel();
      }
    });
  }

  /// Verifica o status da cobrança PIX e decide a ação (navegar ou informar).
  void _checkPaymentStatus(BuildContext context, PixProvider pixProvider, {bool isPeriodic = false}) async {
    if (_isNavigating || !mounted || pixProvider.currentCharge == null) {
      print("_checkPaymentStatus: Ignorado (navigating: $_isNavigating, mounted: $mounted, chargeExists: ${pixProvider.currentCharge != null})");
      return;
    }

    final String txid = pixProvider.currentCharge!.txid;
    print("_checkPaymentStatus: Verificando TXID $txid (isPeriodic: $isPeriodic)");

    // Não mostra loading visual na verificação periódica

    try {
      await pixProvider.checkChargeStatus(txid);

      if (!mounted || pixProvider.currentCharge == null || _isNavigating) {
        print("_checkPaymentStatus: Retornando após check (mounted: $mounted, chargeExists: ${pixProvider.currentCharge != null}, navigating: $_isNavigating)");
        return;
      }

      final status = pixProvider.currentCharge?.status;
      final expiresAt = pixProvider.currentCharge?.expiresAt;
      print("_checkPaymentStatus: Status retornado para $txid = $status");

      bool shouldNavigate = false;
      bool success = false;
      String? errorMessage;

      if (status == 'CONCLUIDA') { shouldNavigate = true; success = true; }
      else if (expiresAt != null && DateTime.now().isAfter(expiresAt)) { shouldNavigate = true; success = false; errorMessage = 'Pagamento expirado'; }
      else if (status == 'REMOVIDA_PELO_PSP' || status == 'REMOVIDA_PELO_USUARIO_RECEBEDOR') { shouldNavigate = true; success = false; errorMessage = 'Cobrança PIX foi removida ($status)'; }
      else if (status != 'ATIVA') { shouldNavigate = true; success = false; errorMessage = 'Status inesperado do PIX: $status'; }

      if (shouldNavigate) {
        if (!_isNavigating) { // Dupla checagem do lock
          print("_checkPaymentStatus: Estado terminal detectado ($status). ATIVANDO LOCK e navegando para StatusScreen...");
          _isNavigating = true; // <<< ATIVA O LOCK AQUI!
          _periodicCheckTimer?.cancel(); // Para o timer imediatamente
          _navigateToStatusScreen(context, pixProvider, success, errorMessage); // Navega
        } else {
          print("_checkPaymentStatus: Estado terminal detectado ($status), mas lock já estava ativo. Ignorando navegação duplicada.");
        }
      } else if (status == 'ATIVA') {
        if (!isPeriodic && mounted) {
          ScaffoldMessenger.of(context).showSnackBar( const SnackBar(content: Text('Pagamento ainda não confirmado pelo banco.')),);
        }
        print("_checkPaymentStatus: Status ATIVO para $txid, aguardando...");
      }

    } catch (error) {
      if (mounted && !_isNavigating) {
        print("_checkPaymentStatus: Erro ao verificar status para $txid: $error");
        if (!isPeriodic) {
          ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Erro ao verificar status: ${error.toString()}')),);
        }
      }
    }
  }

  /// Navega para a tela de Status.
  void _navigateToStatusScreen(BuildContext context, PixProvider pixProvider, bool success, String? errorMessage) {
    // O lock _isNavigating já foi ativado no _checkPaymentStatus
    print("Executando _navigateToStatusScreen (Success: $success)...");

    final String? txid = pixProvider.currentCharge?.txid;
    final double? valor = widget.agendamento.precoServico;
    final String? prestadorId = widget.agendamento.idPrestador;
    final String? agendamentoId = widget.agendamento.idAgendamento;

    // Validação (mantida como estava, parece ok)
    // ... (código de validação dos dados txid, prestadorId, etc.) ...
    bool dataOk = true;
    if (txid == null || txid.isEmpty) { errorMessage = (errorMessage ?? "") + " (Erro Interno: ID Transação PIX ausente)"; success = false; dataOk = false; }
    if (prestadorId == null || prestadorId.isEmpty) { errorMessage = (errorMessage ?? "") + " (Erro Interno: ID Prestador ausente)"; success = false; dataOk = false; }
    if (agendamentoId == null || agendamentoId.isEmpty) { errorMessage = (errorMessage ?? "") + " (Erro Interno: ID Agendamento ausente)"; success = false; dataOk = false; }
    if (valor == null || valor <= 0) { errorMessage = (errorMessage ?? "") + " (Erro Interno: Valor serviço inválido)"; success = false; dataOk = false; }


    print("Navegando com: success=$success, txid=$txid, prestadorId=$prestadorId, agendamentoId=$agendamentoId, valor=$valor");

    // Navega substituindo a tela atual
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentStatusScreen(
          successful: success,
          errorMessage: errorMessage,
          txid: txid ?? 'ERRO_TXID_AUSENTE',
          valorServico: valor,
          prestadorId: prestadorId ?? 'ERRO_PRESTADOR_ID_AUSENTE',
          agendamentoId: agendamentoId ?? 'ERRO_AGENDAMENTO_ID_AUSENTE',
          agendamento: widget.agendamento,
        ),
      ),
    );
    // Lock _isNavigating permanece ativo pois a tela foi substituída/fechada.
  }


  // Build da tela
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        print("WillPopScope: Navegação de volta detectada. Cancelando timer.");
        _periodicCheckTimer?.cancel();
        return true; // Permite voltar
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pagamento PIX'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              print("Botão Voltar AppBar: Cancelando timer e voltando.");
              _periodicCheckTimer?.cancel();
              Navigator.maybePop(context);
            },
          ),
        ),
        body: Consumer<PixProvider>(
          builder: (context, pixProvider, child) {
            // Loading Inicial
            if (pixProvider.isLoading && pixProvider.currentCharge == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // Erro na Geração
            if (pixProvider.error != null) {
              return Center(
                child: Padding( padding: const EdgeInsets.all(20.0), child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60), const SizedBox(height: 20),
                  Text( 'Erro no Pagamento PIX', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red), textAlign: TextAlign.center,), const SizedBox(height: 10),
                  Text( pixProvider.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)), const SizedBox(height: 30),
                  ElevatedButton( onPressed: _isNavigating ? null : _initializePayment, child: const Text('Tentar Novamente')),
                ],),),
              );
            }

            // Tela Principal com QR Code
            if (pixProvider.currentCharge != null && pixProvider.currentQRCode != null) {
              return SingleChildScrollView(
                child: Padding( padding: const EdgeInsets.all(16.0), child: Column( crossAxisAlignment: CrossAxisAlignment.center, children: [
                  const Text( 'Pague com PIX', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
                  Text( 'Valor: R\$ ${widget.agendamento.precoServico?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontSize: 18)), const SizedBox(height: 8),
                  Text( widget.description, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center), const SizedBox(height: 24),
                  PixQRCodeWidget( qrCodeImage: pixProvider.currentQRCode!.qrCodeImage, qrCodeText: pixProvider.currentQRCode!.qrCodeText), const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isNavigating || pixProvider.isLoading ? null : () { // Usa isLoading do provider também
                      print("Botão 'Verificar Manualmente' pressionado.");
                      _checkPaymentStatus(context, pixProvider, isPeriodic: false);
                    },
                    // Mostra loading no botão se o provider estiver checando
                    child: pixProvider.isLoading ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Verificar Pagamento Manualmente'),
                  ),
                  const SizedBox(height: 10),
                  const Text( 'O status do pagamento será verificado automaticamente.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 10),
                  if (_periodicCheckTimer?.isActive ?? false)
                    Row( mainAxisSize: MainAxisSize.min, children: [ SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 1.5)), SizedBox(width: 8), Text('Verificação automática ativa...', style: TextStyle(fontSize: 11, color: Colors.grey))])
                ],),),
              );
            }

            // Estado inicial/inesperado
            return const Center( child: Column( mainAxisAlignment: MainAxisAlignment.center, children: [ CircularProgressIndicator(), SizedBox(height: 16), Text('Iniciando pagamento PIX...'),],));
          },
        ),
      ),
    );
  }
}