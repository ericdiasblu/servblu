import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:servblu/providers/pix_provider.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({Key? key}) : super(key: key);

  @override
  _WithdrawalScreenState createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _pixKeyController = TextEditingController();
  String _selectedPixKeyType = 'cpf';
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _pixKeyTypes = [
    {'value': 'cpf', 'label': 'CPF'},
    {'value': 'cnpj', 'label': 'CNPJ'},
    {'value': 'telefone', 'label': 'Telefone'},
    {'value': 'email', 'label': 'E-mail'},
    {'value': 'aleatoria', 'label': 'Chave Aleatória'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _pixKeyController.dispose();
    super.dispose();
  }

  Future<void> _processWithdrawal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final pixProvider = Provider.of<PixProvider>(context, listen: false);

      // Parse amount (handle comma as decimal separator)
      final String amountText = _amountController.text.replaceAll(',', '.');
      final double amount = double.parse(amountText);

      await pixProvider.createWithdrawal(
        amount: amount,
        pixKey: _pixKeyController.text,
        pixKeyType: _selectedPixKeyType,
        description: 'Saque via app',
      );

      // Exibe mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saque processado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );

      // Limpa o formulário
      _amountController.clear();
      _pixKeyController.clear();
    } catch (e) {
      // Exibe mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pixProvider = Provider.of<PixProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solicitar Saque'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Exibe saldo disponível (você precisará adicionar esta informação ao seu provider)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Saldo Disponível',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 8),
                      // Substitua pelo seu getter de saldo real
                      Text(
                        'R\$ 100,00', // Exemplo - substitua pelo saldo real do usuário
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Campo de valor
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Valor para saque',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe o valor do saque';
                  }
                  final valueNumber =
                      double.tryParse(value.replaceAll(',', '.'));
                  if (valueNumber == null) {
                    return 'Valor inválido';
                  }
                  if (valueNumber < 1) {
                    return 'O valor mínimo para saque é R\$ 1,00';
                  }
                  // Aqui você poderia validar se o valor é menor ou igual ao saldo disponível
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipo de chave PIX
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tipo de Chave PIX',
                  border: OutlineInputBorder(),
                ),
                value: _selectedPixKeyType,
                items: _pixKeyTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['value'] as String,
                    child: Text(type['label'] as String),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPixKeyType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Chave PIX
              TextFormField(
                controller: _pixKeyController,
                decoration: const InputDecoration(
                  labelText: 'Chave PIX',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, informe sua chave PIX';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Botão de saque
              ElevatedButton(
                onPressed: _isProcessing ? null : _processWithdrawal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('SOLICITAR SAQUE'),
              ),

              // Área de status/resposta
              if (pixProvider.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    pixProvider.error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              if (pixProvider.withdrawalResult != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Card(
                    color: Colors.green[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Saque processado com sucesso!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'ID: ${pixProvider.withdrawalResult!['id'] ?? 'N/A'}'),
                          // Adicione mais campos conforme a resposta da sua API
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
