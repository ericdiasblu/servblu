import 'dart:async'; // Necessário para Timer
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// ****** VERIFIQUE SEUS CAMINHOS DE IMPORT ******
import 'package:servblu/screens/pagamento/status_pagamento_screen.dart';
import 'package:servblu/models/servicos/agendamento.dart';
import 'package:servblu/providers/pix_provider.dart';
import 'package:servblu/widgets/pix_qrcode_widget.dart';
// ****** FIM VERIFICAÇÃO CAMINHOS ******

class PaymentScreen extends StatefulWidget {
  final String description;
  final Agendamento agendamento; // Recebe o objeto Agendamento completo

  const PaymentScreen({
    Key? key,
    required this.description,
    required this.agendamento, // Garanta que agendamento não seja null aqui
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  // Variável de controle para o lock de navegação (essencial!)
  bool _isNavigatingToStatus = false;
  // Timer para a verificação periódica
  Timer? _periodicCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Validação inicial dos dados do agendamento recebidos
      if (widget.agendamento == null ||
          widget.agendamento.idPrestador == null || widget.agendamento.idPrestador.isEmpty ||
          widget.agendamento.idAgendamento == null || widget.agendamento.idAgendamento.isEmpty) {
        print("ERRO FATAL em PaymentScreen initState: Dados do Agendamento inválidos recebidos.");
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro interno: Dados do agendamento inválidos. Não é possível iniciar o pagamento.'))
          );
          // Talvez fechar a tela ou mostrar um estado de erro permanente
          // Navigator.pop(context); // Exemplo
        }
        return; // Não prossegue se dados essenciais faltam
      }

      _initializePayment();
    });
  }

  /// Inicializa a criação da cobrança PIX.
  void _initializePayment() {
    final pixProvider = Provider.of<PixProvider>(context, listen: false);
    pixProvider.clear();

    double? valorServico = widget.agendamento.precoServico;
    valorServico = (valorServico != null && valorServico >= 1) ? valorServico : 1.0;

    print("PaymentScreen: Iniciando criação de cobrança PIX...");
    pixProvider.createCharge(
      amount: valorServico,
      description: widget.description,
    ).then((_) {
      if (mounted && pixProvider.currentCharge != null) {
        print("Cobrança PIX criada (txid: ${pixProvider.currentCharge!.txid}). Iniciando verificação periódica.");
        _startPeriodicCheck(context, pixProvider);
      } else if (mounted) {
        print("Falha ao criar cobrança PIX ou provider não atualizou.");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao iniciar pagamento PIX. Tente novamente mais tarde.'))
        );
      }
    }).catchError((error) {
      print("Erro CRÍTICO ao criar cobrança PIX: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro CRÍTICO ao iniciar PIX: ${error.toString()}'))
        );
        // Atualiza o estado do provider para refletir o erro na UI
      }
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
      if (mounted && !_isNavigatingToStatus && pixProvider.currentCharge != null) {
        print("Timer: Verificando status (txid: ${pixProvider.currentCharge!.txid})...");
        _checkPaymentStatus(context, pixProvider, isPeriodic: true);
      } else {
        print("Timer: Verificação periódica cancelada (mounted: $mounted, navigating: $_isNavigatingToStatus, chargeExists: ${pixProvider.currentCharge != null}).");
        timer.cancel();
      }
    });
  }

  /// Verifica o status da cobrança PIX e decide se navega para a tela de status.
  /// **Contém a lógica de lock de navegação aprimorada.**
  void _checkPaymentStatus(BuildContext context, PixProvider pixProvider, {bool isPeriodic = false}) {
    // Lock inicial e verificação de cobrança
    if (_isNavigatingToStatus || pixProvider.currentCharge == null) {
      print("_checkPaymentStatus: Ignorado no início (navigating: $_isNavigatingToStatus, chargeExists: ${pixProvider.currentCharge != null})");
      return;
    }

    final String txid = pixProvider.currentCharge!.txid;
    print("_checkPaymentStatus: Verificando TXID $txid (isPeriodic: $isPeriodic)");

    pixProvider.checkChargeStatus(txid).then((_) {
      // --- PONTO CRÍTICO DA CONCORRÊNCIA ---
      // Re-verifica as condições após o retorno assíncrono.
      if (!mounted || pixProvider.currentCharge == null || _isNavigatingToStatus) {
        print("_checkPaymentStatus: Retornando após check (mounted: $mounted, chargeExists: ${pixProvider.currentCharge != null}, navigating: $_isNavigatingToStatus)");
        return;
      }

      final status = pixProvider.currentCharge?.status;
      final expiresAt = pixProvider.currentCharge?.expiresAt;
      bool shouldNavigate = false; // Flag para decidir se navega
      bool success = false;
      String? errorMessage;

      print("_checkPaymentStatus: Status retornado para $txid = $status");

      // Verifica os status terminais que requerem navegação
      if (status == 'CONCLUIDA') {
        shouldNavigate = true;
        success = true;
        errorMessage = null;
      } else if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        shouldNavigate = true;
        success = false;
        errorMessage = 'Pagamento expirado';
      } else if (status == 'REMOVIDA_PELO_PSP' || status == 'REMOVIDA_PELO_USUARIO_RECEBEDOR'){
        shouldNavigate = true;
        success = false;
        errorMessage = 'Cobrança PIX foi removida ($status)';
      } else if (status != 'ATIVA') { // Trata outros status inesperados como erro terminal
        shouldNavigate = true;
        success = false;
        errorMessage = 'Status inesperado do PIX: $status';
      }

      // --- ATIVAÇÃO DO LOCK E NAVEGAÇÃO ---
      if (shouldNavigate) {
        // Tenta ativar o lock. Se já estiver ativo (outra chamada foi mais rápida),
        // esta chamada simplesmente não fará nada.
        if (!_isNavigatingToStatus) {
          print("_checkPaymentStatus: Estado terminal detectado ($status). ATIVANDO LOCK de navegação para $txid.");
          _isNavigatingToStatus = true; // <<< ATIVA O LOCK AQUI!
          _periodicCheckTimer?.cancel(); // Para o timer imediatamente

          // Chama a função de navegação (agora garantido ser chamada apenas uma vez)
          _navigateToStatusScreen(context, pixProvider, success, errorMessage);
        } else {
          print("_checkPaymentStatus: Estado terminal detectado ($status), mas lock de navegação JÁ ESTAVA ATIVO. Ignorando navegação duplicada para $txid.");
        }
      }
      // Lógica para status não-terminais (ATIVA)
      else if (!isPeriodic && status == 'ATIVA') { // Verificação Manual
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pagamento ainda não confirmado pelo banco.')),
          );
        }
      }
      else if (isPeriodic && status == 'ATIVA') { // Verificação Periódica
        print("_checkPaymentStatus: Status ATIVO (periódico) para $txid, aguardando próxima verificação.");
      }

    }).catchError((error) {
      // Só mostra erro se não estivermos já navegando
      if (mounted && !_isNavigatingToStatus) {
        print("_checkPaymentStatus: Erro ao verificar status para $txid: $error");
        if(!isPeriodic) { // Mostra erro na UI apenas se for verificação manual
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao verificar status: ${error.toString()}')),
          );
        }
      }
    });
  }

  /// Função centralizada para navegar para a tela de Status. Chamada por _checkPaymentStatus.
  void _navigateToStatusScreen(BuildContext context, PixProvider pixProvider, bool success, String? errorMessage) {
    // O lock principal já foi ativado no _checkPaymentStatus ANTES de chamar aqui.

    print("Executando _navigateToStatusScreen (Success: $success)...");

    // Coleta e validação CRÍTICA dos dados antes de navegar
    final String? txid = pixProvider.currentCharge?.txid;
    final double? valor = widget.agendamento.precoServico;
    final String? prestadorId = widget.agendamento.idPrestador;
    final String? agendamentoId = widget.agendamento.idAgendamento;
    bool dataOk = true; // Flag para validar dados

    // Realiza as validações e ajusta 'success' e 'errorMessage' se necessário
    if (txid == null || txid.isEmpty) {
      print("ERRO NAVEGAÇÃO: TXID está nulo ou vazio!");
      errorMessage = (errorMessage ?? "") + " (Erro Interno: ID Transação PIX ausente)";
      success = false; dataOk = false;
    }
    if (prestadorId == null || prestadorId.isEmpty) {
      print("ERRO NAVEGAÇÃO: prestadorId está nulo ou vazio!");
      errorMessage = (errorMessage ?? "") + " (Erro Interno: ID Prestador ausente)";
      success = false; dataOk = false;
    }
    if (agendamentoId == null || agendamentoId.isEmpty) {
      print("ERRO NAVEGAÇÃO: agendamentoId está nulo ou vazio!");
      errorMessage = (errorMessage ?? "") + " (Erro Interno: ID Agendamento ausente)";
      success = false; dataOk = false;
    }
    if (valor == null || valor <= 0) {
      print("ERRO NAVEGAÇÃO: Valor do serviço inválido ($valor)!");
      errorMessage = (errorMessage ?? "") + " (Erro Interno: Valor serviço inválido)";
      success = false; dataOk = false;
    }

    print("Navegando com: success=$success, txid=$txid, prestadorId=$prestadorId, agendamentoId=$agendamentoId, valor=$valor");

    // Navega substituindo a tela atual
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentStatusScreen(
          successful: success, // Usa o status validado
          errorMessage: errorMessage, // Passa a mensagem de erro (pode ter sido modificada)
          txid: txid ?? 'ERRO_TXID_AUSENTE', // Passa o txid (ou um placeholder de erro)
          valorServico: valor,
          prestadorId: prestadorId ?? 'ERRO_PRESTADOR_ID_AUSENTE', // Passa ID (ou placeholder)
          agendamentoId: agendamentoId ?? 'ERRO_AGENDAMENTO_ID_AUSENTE', // Passa ID (ou placeholder)
          agendamento: widget.agendamento, // Passa o objeto se necessário
        ),
      ),
    );
    // Não resetamos o lock aqui (_isNavigatingToStatus).
  }


  // Build da tela
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento PIX')),
      body: Consumer<PixProvider>(
        builder: (context, pixProvider, child) {
          // Tela de Carregamento
          if (pixProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Tela de Erro na Geração/Verificação Inicial do PIX
          if (pixProvider.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 20),
                    Text(
                      'Erro no Pagamento PIX',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      pixProvider.error!, // Mostra o erro específico
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        print("Botão 'Tentar Novamente' pressionado.");
                        _initializePayment(); // Tenta recriar a cobrança
                      },
                      child: const Text('Tentar Novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Tela Principal com QR Code
          if (pixProvider.currentCharge != null && pixProvider.currentQRCode != null) {
            // A verificação periódica já foi iniciada no initState/then
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Pague com PIX',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Valor: R\$ ${widget.agendamento.precoServico?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.description, // Usa a descrição passada
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Widget que mostra o QR Code e o Copia e Cola
                    PixQRCodeWidget(
                      qrCodeImage: pixProvider.currentQRCode!.qrCodeImage,
                      qrCodeText: pixProvider.currentQRCode!.qrCodeText,
                    ),
                    const SizedBox(height: 24),
                    // Botão para verificar manualmente (desabilitado se já navegando)
                    ElevatedButton(
                      onPressed: _isNavigatingToStatus ? null : () {
                        print("Botão 'Verificar Manualmente' pressionado.");
                        _checkPaymentStatus(context, pixProvider, isPeriodic: false);
                      },
                      child: const Text('Verificar Pagamento Manualmente'),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'O status do pagamento será verificado automaticamente.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // Estado inicial ou inesperado (antes da cobrança ser criada)
          return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Iniciando pagamento PIX...'),
                ],
              )
          );
        },
      ),
    );
  }
}