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

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  bool _isNavigating = false; // Lock de navegação unificado
  Timer? _periodicCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Validação inicial
      if (widget.agendamento.idAgendamento.isEmpty ||
          widget.agendamento.idPrestador.isEmpty) {
        print(
            "ERRO FATAL PaymentScreen initState: Dados do Agendamento inválidos.");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Erro interno: Dados do agendamento inválidos.')));
          // Retorna null indicando falha na inicialização
          Navigator.maybePop(context, false);
        }
        return;
      }
      _initializePayment();
    });
  }

  /// Inicializa a criação da cobrança PIX.
  void _initializePayment() {
    if (mounted) {
      setState(() {
        _isNavigating = false;
      });
    }

    final pixProvider = Provider.of<PixProvider>(context, listen: false);
    pixProvider.clear(); // Limpa estado anterior

    double valorServico = (widget.agendamento.precoServico ?? 1.0);
    if (valorServico < 0.01) valorServico = 0.01; // Garante valor mínimo

    print(
        "PaymentScreen: Iniciando criação de cobrança PIX (Valor: $valorServico)...");
    pixProvider
        .createCharge(
      amount: valorServico,
      description: widget.description,
    )
        .then((_) {
      if (mounted && pixProvider.currentCharge != null) {
        print(
            "Cobrança PIX criada (txid: ${pixProvider.currentCharge!.txid}). Iniciando verificação periódica.");
        _startPeriodicCheck(context, pixProvider);
      } else if (mounted) {
        print("Falha ao criar cobrança PIX ou provider não atualizou.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text(pixProvider.error ?? 'Falha ao criar cobrança PIX.')),
        );
        // Considerar voltar com falha se a criação falhar criticamente
        // Navigator.maybePop(context, false);
      }
    }).catchError((error) {
      print("Erro CRÍTICO ao criar cobrança PIX: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
              Text('Erro crítico ao iniciar PIX: ${error.toString()}')),
        );
        // Considerar voltar com falha
        // Navigator.maybePop(context, false);
      }
    });
  }

  @override
  void dispose() {
    _periodicCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    print("PaymentScreen dispose: Timer cancelado e Observer removido.");
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted && !_isNavigating) {
      print("App Resumed: Verificando status do pagamento...");
      final pixProvider = Provider.of<PixProvider>(context, listen: false);
      if (pixProvider.currentCharge != null) {
        _checkPaymentStatus(context, pixProvider, isPeriodic: false);
      } else {
        print("App Resumed: Nenhuma cobrança PIX ativa para verificar.");
      }
    } else if (state == AppLifecycleState.paused) {
      print("App Paused");
    }
  }

  /// Inicia o Timer para verificar o status do PIX periodicamente.
  void _startPeriodicCheck(BuildContext context, PixProvider pixProvider) {
    _periodicCheckTimer?.cancel(); // Cancela timer anterior se houver
    print("Iniciando nova verificação periódica (intervalo: 10s).");

    _periodicCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted && !_isNavigating && pixProvider.currentCharge != null) {
        print(
            "Timer: Verificando status (txid: ${pixProvider.currentCharge!.txid})...");
        _checkPaymentStatus(context, pixProvider, isPeriodic: true);
      } else {
        print(
            "Timer: Verificação periódica cancelada (mounted: $mounted, navigating: $_isNavigating, chargeExists: ${pixProvider.currentCharge != null}).");
        timer.cancel();
      }
    });
  }

  /// Verifica o status da cobrança PIX e decide a ação (navegar ou informar).
  void _checkPaymentStatus(BuildContext context, PixProvider pixProvider,
      {bool isPeriodic = false}) async {
    if (_isNavigating || !mounted || pixProvider.currentCharge == null) {
      print(
          "_checkPaymentStatus: Ignorado (navigating: $_isNavigating, mounted: $mounted, chargeExists: ${pixProvider.currentCharge != null})");
      return;
    }

    final String txid = pixProvider.currentCharge!.txid;
    print(
        "_checkPaymentStatus: Verificando TXID $txid (isPeriodic: $isPeriodic)");

    try {
      await pixProvider.checkChargeStatus(txid);

      if (!mounted || pixProvider.currentCharge == null || _isNavigating) {
        print(
            "_checkPaymentStatus: Retornando após check (mounted: $mounted, chargeExists: ${pixProvider.currentCharge != null}, navigating: $_isNavigating)");
        return;
      }

      final status = pixProvider.currentCharge?.status;
      final expiresAt = pixProvider.currentCharge?.expiresAt;
      print("_checkPaymentStatus: Status retornado para $txid = $status");

      bool shouldNavigate = false;
      bool success = false;
      String? errorMessage;

      // **** INÍCIO DA LÓGICA DE STATUS MODIFICADA ****
      // **** TODO: Verifique os status REAIS da sua API PIX! Estes são exemplos. ****
      final List<String> successStatus = ['CONCLUIDA', 'PAGO', 'LIQUIDADO', 'SETTLED'];
      final List<String> explicitFailureStatus = ['CANCELADA', 'FALHA']; // Adicione outros se houver
      final List<String> removalStatus = ['REMOVIDA_PELO_PSP', 'REMOVIDA_PELO_USUARIO_RECEBEDOR'];
      final List<String> pendingStatus = ['ATIVA', 'EM_PROCESSAMENTO', 'PENDENTE'];

      if (status == null) {
        // Tratar status nulo como erro ou pendente? Assumindo pendente por segurança.
        print("_checkPaymentStatus: Status NULO retornado para $txid. Aguardando...");
      } else if (successStatus.contains(status)) {
        shouldNavigate = true;
        success = true;
        print("_checkPaymentStatus: Pagamento CONFIRMADO ($status). Preparando navegação.");
      } else if (explicitFailureStatus.contains(status)) {
        shouldNavigate = true;
        success = false;
        errorMessage = 'Pagamento falhou ou foi cancelado ($status)';
        print("_checkPaymentStatus: Pagamento FALHOU/CANCELADO ($status). Preparando navegação.");
      } else if (removalStatus.contains(status)) {
        shouldNavigate = true;
        success = false;
        errorMessage = 'Cobrança PIX foi removida ($status)';
        print("_checkPaymentStatus: Cobrança REMOVIDA ($status). Preparando navegação.");
      } else if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
        // Verifica expiração APENAS se não for um status terminal já tratado
        shouldNavigate = true;
        success = false;
        errorMessage = 'Pagamento expirado';
        print("_checkPaymentStatus: Pagamento EXPIRADO. Preparando navegação.");
      } else if (pendingStatus.contains(status)) {
        // Status Ativo ou Pendente - não faz nada, continua aguardando
        if (!isPeriodic && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pagamento ainda não confirmado pelo banco.')),
          );
        }
        print("_checkPaymentStatus: Status ($status) para $txid, aguardando...");
      } else {
        // Status Inesperado/Desconhecido
        shouldNavigate = true;
        success = false;
        errorMessage = 'Status inesperado do PIX: $status';
        print("_checkPaymentStatus: Status INESPERADO ($status). Preparando navegação.");
      }
      // **** FIM DA LÓGICA DE STATUS MODIFICADA ****


      if (shouldNavigate) {
        if (!_isNavigating) {
          // Ativa o lock ANTES de qualquer ação assíncrona de navegação
          setState(() {
            _isNavigating = true;
          });
          print(
              "_checkPaymentStatus: Estado terminal/erro detectado ($status). ATIVANDO LOCK e navegando para StatusScreen...");
          _periodicCheckTimer?.cancel(); // Para o timer imediatamente

          // Garante que ainda está montado antes de chamar a navegação
          if (mounted) {
            // **** MODIFICAÇÃO: Chamada para _navigateToStatusScreen agora é async e espera resultado ****
            await _navigateToStatusScreen(context, pixProvider, success, errorMessage);
            // Após retornar da StatusScreen (seja por sucesso, falha ou back button),
            // resetamos o lock se ainda estivermos montados.
            if (mounted) {
              setState(() {
                _isNavigating = false;
              });
              print("_checkPaymentStatus: Lock de navegação resetado após retorno de _navigateToStatusScreen.");
            }
          }
        } else {
          print(
              "_checkPaymentStatus: Estado terminal detectado ($status), mas lock já estava ativo. Ignorando navegação duplicada.");
        }
      }
    } catch (error) {
      if (mounted && !_isNavigating) {
        print(
            "_checkPaymentStatus: Erro ao verificar status para $txid: $error");
        if (!isPeriodic) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erro ao verificar status: ${error.toString()}')),
          );
        }
      }
    }
  }

  /// Navega para a tela de Status e ESPERA o resultado.
  Future<void> _navigateToStatusScreen(BuildContext context, PixProvider pixProvider,
      bool success, String? errorMessage) async {
    // O lock _isNavigating já deve ter sido ativado no _checkPaymentStatus
    print("Executando _navigateToStatusScreen (Success: $success)...");

    final String? txid = pixProvider.currentCharge?.txid;
    final double? valor = widget.agendamento.precoServico;
    final String? prestadorId = widget.agendamento.idPrestador;
    final String? agendamentoId = widget.agendamento.idAgendamento;

    // Validação robusta dos dados essenciais ANTES de navegar
    bool dataOk = true;
    String validationErrorAccumulator = "";
    if (txid == null || txid.isEmpty) { validationErrorAccumulator += "ID TX PIX ausente. "; dataOk = false; }
    if (prestadorId == null || prestadorId.isEmpty) { validationErrorAccumulator += "ID Prestador ausente. "; dataOk = false; }
    if (agendamentoId == null || agendamentoId.isEmpty) { validationErrorAccumulator += "ID Agendamento ausente. "; dataOk = false; }
    if (valor == null || valor <= 0) { validationErrorAccumulator += "Valor inválido. "; dataOk = false; }

    if (!dataOk) {
      print("ERRO DE DADOS para navegação: $validationErrorAccumulator");
      success = false;
      errorMessage = (errorMessage == null || errorMessage.isEmpty)
          ? "Erro Interno: $validationErrorAccumulator"
          : "$errorMessage (Erro Interno: $validationErrorAccumulator)";
    }

    print("Navegando com push (aguardando resultado): success=$success, txid=$txid ...");

    bool? resultFromStatusScreen; // Variável para guardar o resultado
    try {
      if (mounted) {
        // **** MODIFICAÇÃO: Use push e aguarde o resultado (bool?) ****
        resultFromStatusScreen = await Navigator.push<bool?>(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentStatusScreen(
              successful: success, // O status inicial do PIX (pode ser false)
              errorMessage: errorMessage,
              txid: txid ?? 'ERRO_TXID_AUSENTE',
              valorServico: valor,
              prestadorId: prestadorId ?? 'ERRO_PRESTADOR_ID_AUSENTE',
              agendamentoId: agendamentoId ?? 'ERRO_AGENDAMENTO_ID_AUSENTE',
              agendamento: widget.agendamento,
            ),
          ),
        );
        print("Navegação para PaymentStatusScreen concluída. Resultado recebido: $resultFromStatusScreen");

        // Agora que PaymentStatusScreen foi fechada, precisamos retornar o resultado final para AgendamentoActions
        // Isso é feito fazendo o pop desta tela (PaymentScreen) com o resultado recebido.
        if(mounted) {
          // Se resultFromStatusScreen for null (ex: usuário usou botão voltar físico
          // na StatusScreen), consideramos como falha/cancelamento (false).
          Navigator.pop(context, resultFromStatusScreen ?? false);
        }

      } else {
        print("ERRO CRÍTICO: Tentativa de navegar após componente desmontado!");
        // Se não está montado, não podemos retornar resultado, o await original receberá null.
      }
    } catch (e) {
      print("ERRO CRÍTICO na navegação (push): $e");
      // Em caso de erro na própria navegação, tentamos voltar com 'false'
      if (mounted) {
        // Tentativa de fallback com pushAndRemoveUntil (remove PaymentScreen da pilha)
        // NÃO VAI RETORNAR RESULTADO para o await original
        /*
         Navigator.pushAndRemoveUntil(
           context,
           MaterialPageRoute(
             builder: (context) => PaymentStatusScreen(
               successful: false, // Força falha
               errorMessage: "Erro crítico durante navegação: ${e.toString()}",
               // ... outros parâmetros ...
             ),
           ),
           (route) => false,
         );
         */
        // Alternativa: Apenas voltar com false
        Navigator.maybePop(context, false);
      }
    }
    // O lock _isNavigating será resetado no chamador (_checkPaymentStatus) após este await retornar.
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Ação ao pressionar o botão físico/gesto de voltar
        print(
            "WillPopScope: Navegação de volta detectada. Cancelando timer e permitindo voltar com resultado 'null'.");
        _periodicCheckTimer?.cancel();
        // Retorna null para indicar cancelamento pelo usuário
        return true; // Permite a ação de voltar (que retornará null para o await)
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pagamento PIX'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              // Ação do botão de voltar na AppBar
              print("Botão Voltar AppBar: Cancelando timer e voltando com resultado 'null'.");
              _periodicCheckTimer?.cancel();
              // Retorna null para o await Navigator.push que chamou esta tela
              Navigator.maybePop(context, null);
            },
          ),
        ),
        body: Consumer<PixProvider>(
          builder: (context, pixProvider, child) {
            // Estado de Loading Inicial
            if (pixProvider.isLoading &&
                pixProvider.currentCharge == null &&
                pixProvider.error == null) {
              return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Gerando QR Code PIX...'),
                    ],
                  ));
            }

            // Erro na Geração da Cobrança
            if (pixProvider.error != null &&
                pixProvider.currentCharge == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 20),
                      Text('Erro ao Gerar PIX', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.red), textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      Text(pixProvider.error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red, fontSize: 16)),
                      const SizedBox(height: 30),
                      ElevatedButton(
                          onPressed: _isNavigating ? null : _initializePayment,
                          child: const Text('Tentar Novamente')),
                      const SizedBox(height: 10),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                          onPressed: () => Navigator.maybePop(context, false), // Volta com falha
                          child: const Text('Cancelar e Voltar')
                      ),
                    ],
                  ),
                ),
              );
            }

            // Tela Principal com QR Code
            if (pixProvider.currentCharge != null) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text('Pague com PIX', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Text('Valor: R\$ ${widget.agendamento.precoServico?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(widget.description, style: const TextStyle(fontSize: 16, color: Colors.grey), textAlign: TextAlign.center),
                      const SizedBox(height: 24),

                      (pixProvider.currentQRCode != null)
                          ? PixQRCodeWidget(
                          qrCodeImage: pixProvider.currentQRCode!.qrCodeImage,
                          qrCodeText: pixProvider.currentQRCode!.qrCodeText)
                          : const Padding( padding: EdgeInsets.symmetric(vertical: 40), child: CircularProgressIndicator()),

                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isNavigating || pixProvider.isLoading ? null : () {
                          print("Botão 'Verificar Manualmente' pressionado.");
                          _checkPaymentStatus(context, pixProvider, isPeriodic: false);
                        },
                        child: pixProvider.isLoading
                            ? const SizedBox( height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Verificar Pagamento Manualmente'),
                      ),
                      const SizedBox(height: 10),
                      const Text('O status será verificado automaticamente.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      const SizedBox(height: 10),
                      if (_periodicCheckTimer?.isActive ?? false)
                        const Row(mainAxisSize: MainAxisSize.min, children: [
                          SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 1.5)),
                          SizedBox(width: 8),
                          Text('Verificação automática ativa...', style: TextStyle(fontSize: 11, color: Colors.grey))
                        ])
                      else if (pixProvider.currentCharge?.status == 'ATIVA')
                        const Text('Verificação automática inativa.', style: TextStyle(fontSize: 11, color: Colors.orange))
                    ],
                  ),
                ),
              );
            }

            // Estado fallback
            return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Carregando informações...'),
                  ],
                ));
          },
        ),
      ),
    );
  }
}