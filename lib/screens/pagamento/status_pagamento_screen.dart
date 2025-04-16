import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/agendamento.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentStatusScreen extends StatefulWidget {
  final bool successful;
  final String? errorMessage;
  final String txid;
  final double? valorServico; // Valor do serviço a ser adicionado ao saldo
  final String prestadorId; // ID do prestador que receberá o valor
  final String agendamentoId; // Add this field
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
  bool _atualizandoSaldo = false;
  bool _saldoAtualizado = false;
  String? _mensagemErro;
  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    if (widget.successful) {
      _atualizarSaldoPrestador();
    }
  }

  Future<void> _registrarPagamento() async {
    try {
      // First check if this transaction is already registered
      final existingPayment = await _supabase
          .from('pagamentos')
          .select()
          .eq('pix_transaction_id', widget.txid)
          .limit(1);

      // If payment already exists, don't create another one
      if (existingPayment.isNotEmpty) { // Changed this line
        print('Pagamento já registrado anteriormente. Ignorando inserção.');
        return;
      }

      // Dados a serem inseridos na tabela de pagamentos
      final pagamentoData = {
        'id_agendamento': widget.agendamentoId,
        'valor': widget.valorServico,
        'is_pix': true,
        'pix_transaction_id': widget.txid,
        'data_pagamento': DateTime.now().toIso8601String(),
        'status': 'confirmado'
      };

      // Insere os dados na tabela de pagamentos
      await _supabase.from('pagamentos').insert(pagamentoData);

      print('Pagamento registrado com sucesso!');
    } catch (error) {
      print('Erro ao registrar pagamento: $error');
      // Instead of throwing an exception, we'll just log the error
      // This prevents the error from propagating up
    }
  }

  Future<void> _atualizarSaldoPrestador() async {
    if (widget.valorServico == null || widget.valorServico! <= 0) {
      setState(() {
        _mensagemErro = 'Valor do serviço inválido';
      });
      return;
    }

    setState(() {
      _atualizandoSaldo = true;
    });

    try {
      // Verificamos se o saldo já foi atualizado para este pagamento
      final existingPayment = await _supabase
          .from('pagamentos')
          .select('status_saldo')
          .eq('pix_transaction_id', widget.txid)
          .limit(1);

      // Se encontramos o pagamento e o status_saldo já está como 'processado',
      // significa que o saldo já foi atualizado
      if (existingPayment.isNotEmpty &&
          existingPayment[0]['status_saldo'] == 'processado') {
        setState(() {
          _saldoAtualizado = true;
          _atualizandoSaldo = false;
        });
        print('Saldo já foi processado anteriormente. Ignorando atualização.');
        return;
      }

      // Registramos o pagamento (se ainda não existir)
      await _registrarPagamento();

      // Obtemos o saldo atual do prestador
      final response = await _supabase
          .from('usuarios')
          .select('saldo')
          .eq('id_usuario', widget.prestadorId)
          .single();

      // Obtém o saldo atual (ou define como 0 se for nulo)
      double saldoAtual = (response['saldo'] as num?)?.toDouble() ?? 0.0;

      // Calcula o novo saldo
      double novoSaldo = saldoAtual + widget.valorServico!;

      // Atualiza o saldo na tabela de usuários
      await _supabase
          .from('usuarios')
          .update({'saldo': novoSaldo})
          .eq('id_usuario', widget.prestadorId);

      // Marca o pagamento como processado para não atualizar o saldo novamente
      await _supabase
          .from('pagamentos')
          .update({'status_saldo': 'processado'})
          .eq('pix_transaction_id', widget.txid);

      setState(() {
        _saldoAtualizado = true;
        _atualizandoSaldo = false;
      });
    } catch (error) {
      setState(() {
        _mensagemErro = 'Erro ao atualizar saldo: ${error.toString()}';
        _atualizandoSaldo = false;
      });
      print('Erro ao atualizar saldo: $error');
    }
  }
  @override
  Widget build(BuildContext context) {
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
                widget.successful ? Icons.check_circle : Icons.error,
                color: widget.successful ? Colors.green : Colors.red,
                size: 80,
              ),
              const SizedBox(height: 24),
              Text(
                widget.successful
                    ? 'Pagamento Confirmado!'
                    : 'Falha no Pagamento',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: widget.successful ? Colors.green : Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (widget.successful && _atualizandoSaldo)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Atualizando saldo do prestador...'),
                  ],
                ),
              if (widget.successful && _saldoAtualizado)
                const Text(
                  'Saldo do prestador atualizado com sucesso!',
                  style: TextStyle(fontSize: 16, color: Colors.green),
                  textAlign: TextAlign.center,
                ),
              if (_mensagemErro != null)
                Text(
                  _mensagemErro!,
                  style: const TextStyle(fontSize: 16, color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              if (!widget.successful && widget.errorMessage != null)
                Text(
                  widget.errorMessage!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 8),
              Text(
                'ID da transação: ${widget.txid}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              if (widget.successful)
                Text(
                  'Valor do serviço: R\$ ${widget.valorServico?.toStringAsFixed(2) ?? "0.00"}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: const Text('Voltar para o Início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}