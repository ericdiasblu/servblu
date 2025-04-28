import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:servblu/widgets/build_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servblu/services/agendamento_service.dart';
import 'package:servblu/models/servicos/agendamento.dart';
import 'package:servblu/widgets/tool_loading.dart';

class CarteiraScreen extends StatefulWidget {
  @override
  _CarteiraScreenState createState() => _CarteiraScreenState();
}

class _CarteiraScreenState extends State<CarteiraScreen> {
  final supabase = Supabase.instance.client;
  final AgendamentoService _agendamentoService = AgendamentoService();
  final List<Map<String, dynamic>> _actionButtons = [];

  bool _isLoading = true;
  double _saldo = 125.50;
  List<Agendamento> _agendamentosPendentes = [];
  List<Map<String, dynamic>> _ultimasTransacoes = [
    {
      'titulo': 'Pagamento - Corte de Cabelo',
      'data': DateTime.now().subtract(const Duration(days: 2)),
      'valor': -45.00,
      'status': 'concluído'
    },
    {
      'titulo': 'Depósito via Pix',
      'data': DateTime.now().subtract(const Duration(days: 5)),
      'valor': 100.00,
      'status': 'concluído'
    },
    {
      'titulo': 'Pagamento - Manicure',
      'data': DateTime.now().subtract(const Duration(days: 7)),
      'valor': -35.00,
      'status': 'concluído'
    }
  ];

  @override
  void initState() {
    super.initState();
    _carregarAgendamentos();

    _actionButtons.addAll([
      {
        'icon': Icons.add_circle_outline,
        'label': 'Depositar',
        'onTap': _depositar,
      },
      {
        'icon': Icons.remove_circle_outline,
        'label': 'Sacar',
        'onTap': _sacar,
      },
      {
        'icon': Icons.history,
        'label': 'Histórico',
        'onTap': _verHistorico,
      },
      {
        'icon': Icons.verified,
        'label': 'Verificar Pagamentos',
        'onTap': _verificarPagamentos,
      },
    ]);
  }

  Future<void> _carregarAgendamentos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final idCliente = supabase.auth.currentUser!.id;
      final agendamentos =
          await _agendamentoService.listarAgendamentosPorCliente(idCliente);

      _agendamentosPendentes = agendamentos
          .where((a) => a.status == 'solicitado' && a.isPix == true)
          .toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar agendamentos: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _depositar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Função de depósito será implementada em breve')),
    );
  }

  void _sacar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Função de saque será implementada em breve')),
    );
  }

  void _verHistorico() {
    // Scroll automático até a seção de histórico (opcional no futuro)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Função de histórico será expandida em breve')),
    );
  }

  String _formatarValor(double valor) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(valor);
  }

  String _formatarData(DateTime data) {
    return DateFormat('dd/MM/yyyy').format(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF017DFE),
      body: _isLoading
          ? const Center(
              child: ToolLoadingIndicator(color: Colors.blue, size: 45),
            )
          : RefreshIndicator(
              onRefresh: _carregarAgendamentos,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BuildHeader(
                      title: 'Minha Carteira',
                      backPage: false,
                      refresh: false,
                    ),

                    // Área branca: Saldo e botões
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20),
                          bottomRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card do Saldo
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF017DFE),
                                    Color(0xFF4FA9FE),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Saldo Disponível',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatarValor(_saldo),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Botões de ação scrolláveis
                          SizedBox(
                            height: 70,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _actionButtons.length,
                              itemBuilder: (context, index) {
                                final action = _actionButtons[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _buildActionButton(action['icon'],
                                      action['label'], action['onTap']),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),

                    // Área azul: Pagamentos Pendentes
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('Pagamentos Pendentes'),
                          const SizedBox(height: 16),
                          _agendamentosPendentes.isEmpty
                              ? _buildEmptyState('Não há pagamentos pendentes')
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _agendamentosPendentes.length,
                                  itemBuilder: (context, index) {
                                    final agendamento =
                                        _agendamentosPendentes[index];
                                    return _buildAgendamentoCard(agendamento);
                                  },
                                ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  void _verificarPagamentos() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Função de verificar pagamentos em breve')),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF017DFE),
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFF017DFE), width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      icon: Icon(icon),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF017DFE),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 48, color: Colors.white70),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendamentoCard(Agendamento agendamento) {
    return Card(
      color: Colors.transparent,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              agendamento.nomeServico ?? 'Serviço',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text('Data: ${agendamento.dataServico}',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatarValor(agendamento.precoServico ?? 0),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Ver Pagamento',
                      style: TextStyle(color: Color(0xFF017DFE))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransacaoItem(Map<String, dynamic> transacao) {
    final bool isPositive = transacao['valor'] >= 0;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isPositive
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        child: Icon(
          isPositive ? Icons.arrow_downward : Icons.arrow_upward,
          color: isPositive ? Colors.green : Colors.red,
        ),
      ),
      title: Text(
        transacao['titulo'],
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(_formatarData(transacao['data']),
          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      trailing: Text(
        _formatarValor(transacao['valor'].abs()),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isPositive ? Colors.green : Colors.red,
        ),
      ),
    );
  }
}
