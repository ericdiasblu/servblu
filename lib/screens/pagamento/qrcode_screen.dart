import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servblu/screens/pagamento/status_pagamento_screen.dart';
import '../../models/servicos/agendamento.dart';
import '../../providers/pix_provider.dart';
import '../../widgets/pix_qrcode_widget.dart';

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
  @override
  void initState() {
    super.initState();
    // Limpa dados anteriores e cria uma nova cobrança
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pixProvider = Provider.of<PixProvider>(context, listen: false);
      pixProvider.clear();

      double? valorServico = widget.agendamento.precoServico;

      // Guarantee minimum amount
      valorServico = (valorServico != null && valorServico >= 1) ? valorServico : 1.0;

      pixProvider.createCharge(
        amount: valorServico,
        description: widget.description,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pagamento PIX')),
      body: Consumer<PixProvider>(
        builder: (context, pixProvider, child) {
          if (pixProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (pixProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Erro ao gerar PIX: ${pixProvider.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      pixProvider.createCharge(
                        amount: widget.agendamento.precoServico ?? 0.0,
                        description: widget.description,
                      );
                    },
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (pixProvider.currentCharge != null && pixProvider.currentQRCode != null) {
            // Verificação periódica do status da cobrança
            _checkPaymentStatusPeriodically(context, pixProvider);

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Pagamento com PIX',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Valor: R\$ ${widget.agendamento.precoServico?.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Descrição: ${widget.description}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    PixQRCodeWidget(
                      qrCodeImage: pixProvider.currentQRCode!.qrCodeImage,
                      qrCodeText: pixProvider.currentQRCode!.qrCodeText,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        _checkPaymentStatus(context, pixProvider);
                      },
                      child: const Text('Verificar Pagamento'),
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(child: Text('Aguardando dados do pagamento...'));
        },
      ),
    );
  }

  void _checkPaymentStatusPeriodically(BuildContext context, PixProvider pixProvider) {
    // Verifica o status a cada 10 segundos
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && pixProvider.currentCharge != null) {
        pixProvider.checkChargeStatus(pixProvider.currentCharge!.txid).then((_) {
          final status = pixProvider.currentCharge?.status;
          if (status == 'CONCLUIDA') {
            // Pagamento confirmado
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentStatusScreen(
                  successful: true,
                  txid: pixProvider.currentCharge!.txid,
                ),
              ),
            );
          } else if (DateTime.now().isAfter(pixProvider.currentCharge!.expiresAt)) {
            // Pagamento expirado
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentStatusScreen(
                  successful: false,
                  errorMessage: 'Pagamento expirado',
                  txid: pixProvider.currentCharge!.txid,
                ),
              ),
            );
          } else {
            // Continua verificando
            _checkPaymentStatusPeriodically(context, pixProvider);
          }
        });
      }
    });
  }

  void _checkPaymentStatus(BuildContext context, PixProvider pixProvider) {
    pixProvider.checkChargeStatus(pixProvider.currentCharge!.txid).then((_) {
      final status = pixProvider.currentCharge?.status;
      if (status == 'CONCLUIDA') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentStatusScreen(
              successful: true,
              txid: pixProvider.currentCharge!.txid,
            ),
          ),
        );
      } else if (status == 'ATIVA') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pagamento ainda não recebido. Tente novamente em alguns instantes.')),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentStatusScreen(
              successful: false,
              errorMessage: 'Status do pagamento: $status',
              txid: pixProvider.currentCharge!.txid,
            ),
          ),
        );
      }
    });
  }
}