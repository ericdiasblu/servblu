import 'package:flutter/material.dart';
import 'package:servblu/widgets/build_header.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _currentIndex = 0;

  // Sample data lists (you'll replace these with your actual data)
  final List<Map<String, String>> _solicitadoList = [
    {'title': 'Serviço 1', 'details': 'Detalhes do serviço solicitado'},
    {'title': 'Serviço 2', 'details': 'Outro serviço solicitado'},
  ];

  final List<Map<String, String>> _pagamentoList = [
    {'title': 'Serviço A', 'details': 'Aguardando pagamento'},
    {'title': 'Serviço B', 'details': 'Pendente de confirmação'},
  ];

  final List<Map<String, String>> _concluidoList = [
    {'title': 'Serviço X', 'details': 'Finalizado em 20/03/2025'},
    {'title': 'Serviço Y', 'details': 'Concluído com sucesso'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BuildHeader(title: 'Agendamentos', backPage: false,),

          // Custom Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTabButton('Solicitado', 0),
                _buildTabButton('Aguardando', 1),
                _buildTabButton('Concluído', 2),
              ],
            ),
          ),

          // Content based on selected tab
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _currentIndex = index;
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _currentIndex == index
                ? Colors.blue
                : Colors.white,
            foregroundColor: _currentIndex == index
                ? Colors.white
                : Colors.blue,
            side: BorderSide(color: Colors.blue),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    List<Map<String, String>> currentList;

    switch (_currentIndex) {
      case 0:
        currentList = _solicitadoList;
        break;
      case 1:
        currentList = _pagamentoList;
        break;
      case 2:
        currentList = _concluidoList;
        break;
      default:
        currentList = [];
    }

    return ListView.builder(
      itemCount: currentList.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(currentList[index]['title'] ?? ''),
            subtitle: Text(currentList[index]['details'] ?? ''),
            trailing: Icon(
              _getIconForTab(_currentIndex),
              color: _getColorForTab(_currentIndex),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForTab(int index) {
    switch (index) {
      case 0: return Icons.pending_outlined;
      case 1: return Icons.payment;
      case 2: return Icons.check_circle_outline;
      default: return Icons.error_outline;
    }
  }

  Color _getColorForTab(int index) {
    switch (index) {
      case 0: return Colors.orange;
      case 1: return Colors.deepPurple;
      case 2: return Colors.green;
      default: return Colors.grey;
    }
  }
}