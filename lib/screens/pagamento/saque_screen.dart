import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:servblu/providers/pix_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:lottie/lottie.dart';

class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({Key? key}) : super(key: key);

  @override
  _WithdrawalScreenState createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _pixKeyController = TextEditingController();
  String _selectedPixKeyType = 'cpf';
  bool _isProcessing = false;
  String? saldoUsuario;
  double? saldoNumerico;
  late AnimationController _animationController;
  late Animation<double> _saldoAnimation;
  bool _showSuccess = false;

  final List<Map<String, dynamic>> _pixKeyTypes = [
    {'value': 'cpf', 'label': 'CPF', 'icon': Icons.perm_identity},
    {'value': 'cnpj', 'label': 'CNPJ', 'icon': Icons.business},
    {'value': 'telefone', 'label': 'Telefone', 'icon': Icons.phone},
    {'value': 'email', 'label': 'E-mail', 'icon': Icons.email},
    {'value': 'aleatoria', 'label': 'Chave Aleatória', 'icon': Icons.vpn_key},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _saldoAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    carregarSaldoUsuario();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _pixKeyController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> carregarSaldoUsuario() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('usuarios')
          .select('saldo')
          .eq('id_usuario', user.id)
          .maybeSingle();

      setState(() {
        if (response?['saldo'] != null) {
          saldoNumerico = response!['saldo'];
          saldoUsuario = NumberFormat("#,##0.00", "pt_BR").format(saldoNumerico!);
        } else {
          saldoUsuario = "0,00";
          saldoNumerico = 0;
        }
      });
    }
  }

  void _animateSaldoUpdate(double novoSaldo) {
    _saldoAnimation = Tween<double>(
      begin: saldoNumerico ?? 0,
      end: novoSaldo,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _saldoAnimation.addListener(() {
      setState(() {
        saldoUsuario = NumberFormat("#,##0.00", "pt_BR").format(_saldoAnimation.value);
      });
    });

    _animationController.forward(from: 0);
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

      // Atualizar o saldo
      final double novoSaldo = (saldoNumerico ?? 0) - amount;
      saldoNumerico = novoSaldo;

      // Animar a atualização do saldo
      _animateSaldoUpdate(novoSaldo);

      // Mostrar animação de sucesso
      setState(() {
        _showSuccess = true;
        _isProcessing = false;
      });

      // Esconder a animação após alguns segundos
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showSuccess = false;
          });
        }
      });

      // Limpa o formulário
      _amountController.clear();
      _pixKeyController.clear();
    } catch (e) {
      // Exibe mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text('Sacar Fundos'),
        centerTitle: true,
        backgroundColor: isDark ? Colors.black : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navegar para o histórico de saques
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Fundo com um detalhe de design
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Conteúdo principal
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card de saldo com design minimalista
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [Colors.grey[900]!, Colors.grey[800]!]
                            : [Colors.blueAccent, Colors.blue.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet,
                              color: isDark ? Colors.white70 : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Saldo Disponível',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Text(
                              'R\$ $saldoUsuario',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Atualizado agora',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.white70,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Valor para saque com design minimalista
                  Text(
                    'Valor para saque',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      prefixText: 'R\$ ',
                      hintText: '0,00',
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,]')),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe o valor do saque';
                      }
                      final valueNumber = double.tryParse(value.replaceAll(',', '.'));
                      if (valueNumber == null) {
                        return 'Valor inválido';
                      }
                      if (valueNumber < 1) {
                        return 'Valor mínimo: R\$ 1,00';
                      }
                      if (valueNumber > (saldoNumerico ?? 0)) {
                        return 'Saldo insuficiente';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Tipo de chave PIX com design melhorado
                  Text(
                    'Tipo de Chave PIX',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      value: _selectedPixKeyType,
                      dropdownColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      items: _pixKeyTypes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['value'] as String,
                          child: Row(
                            children: [
                              Icon(
                                type['icon'] as IconData,
                                size: 18,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 12),
                              Text(type['label'] as String),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedPixKeyType = value!;
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Chave PIX
                  Text(
                    'Chave PIX',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pixKeyController,
                    decoration: InputDecoration(
                      hintText: _selectedPixKeyType == 'cpf'
                          ? '000.000.000-00'
                          : _selectedPixKeyType == 'email'
                          ? 'exemplo@email.com'
                          : 'Digite sua chave',
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                      suffixIcon: Icon(
                        _selectedPixKeyType == 'telefone'
                            ? Icons.phone
                            : _selectedPixKeyType == 'email'
                            ? Icons.email
                            : Icons.perm_identity,
                        color: Colors.grey,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Informe sua chave PIX';
                      }

                      // Validações específicas para cada tipo de chave
                      if (_selectedPixKeyType == 'email' && !value.contains('@')) {
                        return 'Digite um e-mail válido';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Botão de saque com design moderno
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processWithdrawal,
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        backgroundColor: Colors.blueAccent,
                      ),
                      child: _isProcessing
                          ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : Text(
                        'Realizar Saque',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.white
                        ),
                      ),
                    ),
                  ),

                  // Informações adicionais
                  if (!_showSuccess)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'O saque será processado em até 1 dia útil',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.black54,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Animação de sucesso
          if (_showSuccess)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Idealmente, você precisaria adicionar o package Lottie e ter um arquivo de animação
                  // Aqui está um placeholder para isso
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                      size: 100,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Saque solicitado com sucesso!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'O valor será processado em breve',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}