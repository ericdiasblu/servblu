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
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final idCliente = supabase.auth.currentUser!.id;
      final agendamentos =
      await _agendamentoService.listarAgendamentosPorCliente(idCliente);

      if (mounted) {
        setState(() {
          _agendamentosPendentes = agendamentos
              .where((a) => a.status == 'solicitado' && a.isPix == true)
              .toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar agendamentos: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Função de histórico será expandida em breve')),
    );
  }

  void _verificarPagamentos() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Função de verificar pagamentos em breve')),
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
        child: ToolLoadingIndicator(color: Colors.white, size: 45),
      )
          : SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          BuildHeader(
          title: 'Minha Carteira',
          backPage: false,
          refresh: true,
          onRefresh: () => _carregarAgendamentos(),
        ),

        // Card do Saldo
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                const Text(
                  'Saldo Disponível',
                  style: TextStyle(
                    color: Color(0xFF017DFE),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatarValor(_saldo),
                  style: const TextStyle(
                    color: Color(0xFF017DFE),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Botões de ação em formato slide
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _actionButtons.length,
              itemExtent: 140,
              itemBuilder: (context, index) {
                final action = _actionButtons[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: _buildActionButton(
                      action['icon'], action['label'], action['onTap']),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Pagamentos Pendentes - Seção expandida e que ocupa até o final
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.payment,
                          color: Color(0xFF017DFE), size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Pagamentos Pendentes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF017DFE),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _agendamentosPendentes.isEmpty
                      ? _buildEmptyState('Não há pagamentos pendentes')
                      : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _agendamentosPendentes.length,
                    itemBuilder: (context, index) {
                      final agendamento =
                      _agendamentosPendentes[index];
                      return _buildAgendamentoCard(agendamento);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

      ],
    ),
    ),





    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        foregroundColor: Color(0xFF017DFE),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF017DFE),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, size: 48, color: Color(0xFF017DFE).withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF017DFE),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendamentoCard(Agendamento agendamento) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              agendamento.nomeServico ?? 'Serviço',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data: ${agendamento.dataServico}',
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatarValor(agendamento.precoServico ?? 0),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF017DFE),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF017DFE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Ver Pagamento',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
      subtitle: Text(
        _formatarData(transacao['data']),
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
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