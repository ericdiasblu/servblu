import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/agendamento.dart';
import 'package:servblu/services/agendamento_service.dart';
import 'package:servblu/widgets/buildheaderwithtabs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

final List<String> tabItems = [
  'Solicitado',
  'Aguardando',
  'Concluído',
  'Recusado'
];

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _currentTabIndex = 0; // 0: Minhas Solicitações, 1: Minhas Ofertas
  int _currentStatusIndex =
      0; // 0: Solicitado, 1: Aguardando, 2: Concluído, 3: Recusado

  final AgendamentoService _agendamentoService = AgendamentoService();
  List<Agendamento> _agendamentos = [];
  bool _isLoading = true;
  String? _errorMessage;
  Agendamento? _selectedAgendamento;

  @override
  void initState() {
    super.initState();
    _carregarAgendamentos();
  }

  Future<void> _carregarAgendamentos() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String userId = Supabase.instance.client.auth.currentUser!.id;
      List<Agendamento> agendamentos;

      // Determinar qual tipo de agendamentos carregar
      if (_currentTabIndex == 0) {
        // Minhas Solicitações (como cliente)
        agendamentos =
            await _agendamentoService.listarAgendamentosPorCliente(userId);
      } else {
        // Minhas Ofertas (como prestador)
        agendamentos =
            await _agendamentoService.listarAgendamentosPorPrestador(userId);
      }

      // Filtrar por status
      String statusFiltro;
      switch (_currentStatusIndex) {
        case 0:
          statusFiltro = 'solicitado';
          break;
        case 1:
          statusFiltro = 'aguardando';
          break;
        case 2:
          statusFiltro = 'concluído';
          break;
        case 3:
          statusFiltro = 'recusado';
          break;
        default:
          statusFiltro = 'solicitado';
      }

      // Filtrar a lista de agendamentos pelo status atual
      agendamentos =
          agendamentos.where((a) => a.status == statusFiltro).toList();

      setState(() {
        _agendamentos = agendamentos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar agendamentos: $e')),
        );
      }
    }
  }

  // Formatar horário (agora com tratamento robusto de tipos)
  String _formatarHorario(dynamic horario) {
    // Se já for string, tenta formatar
    if (horario is String) {
      try {
        int horarioInt = int.parse(horario);
        String horarioStr = horarioInt.toString().padLeft(4, '0');
        return '${horarioStr.substring(0, 2)}:${horarioStr.substring(2)}';
      } catch (e) {
        return horario.toString();
      }
    }
    // Se for inteiro, formata diretamente
    else if (horario is int) {
      String horarioStr = horario.toString().padLeft(4, '0');
      return '${horarioStr.substring(0, 2)}:${horarioStr.substring(2)}';
    }
    // Qualquer outro tipo, converte para string
    else {
      return horario?.toString() ?? 'N/A';
    }
  }

  void _mostrarDetalhesAgendamento(Agendamento agendamento) {
    setState(() {
      _selectedAgendamento = agendamento;
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Nome do serviço (grande)
                Text(
                  agendamento.nomeServico ?? 'Serviço',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Detalhes do agendamento
                _buildInfoRow('Data', _formatarData(agendamento.dataServico)),
                _buildInfoRow(
                    'Horário', _formatarHorario(agendamento.idHorario)),

                // Mostrar nome do prestador ou cliente dependendo da aba
                _buildInfoRow(
                    _currentTabIndex == 0 ? 'Prestador' : 'Cliente',
                    _currentTabIndex == 0
                        ? agendamento.nomePrestador ?? 'Não informado'
                        : agendamento.nomeCliente ?? 'Não informado'),

                // Forma de pagamento
                _buildInfoRow(
                    'Forma de pagamento',
                    agendamento.formaPagamento ??
                        (agendamento.isPix ? 'Pix' : 'Não informado')),

                // ID do agendamento
                _buildInfoRow('ID do agendamento', agendamento.idAgendamento),

                const SizedBox(height: 30),

                // Status com ícone
                Row(
                  children: [
                    Icon(
                      _getIconForStatus(agendamento.status),
                      color: _getColorForStatus(agendamento.status),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Status: ${agendamento.status}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getColorForStatus(agendamento.status),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Botão de ação baseado no status
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Executar a ação apropriada baseada no status
                      _executeActionForStatus(agendamento.status, agendamento);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      _getButtonTextForStatus(agendamento.status),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getButtonTextForStatus(String status) {
    switch (status) {
      case 'solicitado':
        return _currentTabIndex == 0
            ? 'Cancelar Solicitação'
            : 'Aceitar Solicitação';
      case 'aguardando':
        return _currentTabIndex == 0
            ? 'Confirmar Pagamento'
            : 'Verificar Pagamento';
      case 'concluído':
        return _currentTabIndex == 0 ? 'Avaliar Serviço' : 'Ver Detalhes';
      case 'recusado':
        return _currentTabIndex == 0 ? 'Ver Detalhes' : 'Ver Detalhes';
      default:
        return 'Ver Detalhes';
    }
  }

  void _executeActionForStatus(String status, Agendamento agendamento) {
    switch (status) {
      case 'solicitado':
        if (_currentTabIndex == 0) {
          _cancelarSolicitacao(agendamento);
        } else {
          _aceitarSolicitacao(agendamento);
        }
        break;
      case 'aguardando':
        if (_currentTabIndex == 0) {
          _confirmarPagamento(agendamento);
        } else {
          _verificarPagamento(agendamento);
        }
        break;
      case 'concluído':
        if (_currentTabIndex == 0) {
          _avaliarServico(agendamento);
        } else {
          _verDetalhes(agendamento);
        }
        break;
      case 'recusado':
        _verDetalhes(agendamento);
        break;
      default:
        _verDetalhes(agendamento);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Usar o novo header com tabs
          BuildHeaderWithTabs(
            title: 'Agendamentos',
            backPage: false,
            tabs: ['Minhas Solicitações', 'Minhas Ofertas'],
            currentTabIndex: _currentTabIndex,
            onTabChanged: (index) {
              setState(() {
                _currentTabIndex = index;
              });
              _carregarAgendamentos();
            },
          ),

          // Custom Tab Bar para os status

// Agora vamos transformar o widget em um ListView.separated
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              height: 40, // Define uma altura para o ListView
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tabItems.length,
                // Item builder
                itemBuilder: (context, index) {
                  return _buildTabButton(tabItems[index], index);
                },
                // Separator builder
                separatorBuilder: (context, index) {
                  return const SizedBox(width: 8); // Espaço entre os itens
                },
              ),
            ),
          ),

          // Content based on selected tab
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 48),
                            SizedBox(height: 16),
                            Text(
                              'Erro ao carregar agendamentos:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(_errorMessage!),
                            ),
                            ElevatedButton(
                              onPressed: _carregarAgendamentos,
                              child: Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      )
                    : _agendamentos.isEmpty
                        ? Center(
                            child: Text(
                              _currentTabIndex == 0
                                  ? 'Você não tem solicitações neste status'
                                  : 'Você não tem ofertas neste status',
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _agendamentos.length,
                            itemBuilder: (context, index) {
                              final agendamento = _agendamentos[index];
                              return _buildAgendamentoCard(agendamento);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Container(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStatusIndex = index;
              });
              _carregarAgendamentos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _currentStatusIndex == index ? Colors.blue : Colors.white,
              foregroundColor:
                  _currentStatusIndex == index ? Colors.white : Colors.blue,
              side: BorderSide(color: Colors.blue),
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgendamentoCard(Agendamento agendamento) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _mostrarDetalhesAgendamento(agendamento),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome do serviço (grande)
              Text(
                agendamento.nomeServico ?? 'Serviço',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Data e hora
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    _formatarData(agendamento.dataServico),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    _formatarHorario(agendamento.idHorario),
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Indicador de status
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getColorForStatus(agendamento.status)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getColorForStatus(agendamento.status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getIconForStatus(agendamento.status),
                          color: _getColorForStatus(agendamento.status),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          agendamento.status,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getColorForStatus(agendamento.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatarId(String id) {
    return id.length > 8 ? id.substring(0, 8) : id;
  }

  String _formatarData(String dataString) {
    try {
      final data = DateTime.parse(dataString);
      return DateFormat('dd/MM/yyyy').format(data);
    } catch (e) {
      return dataString;
    }
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'solicitado':
        return Icons.pending_outlined;
      case 'aguardando':
        return Icons.payment;
      case 'concluído':
        return Icons.check_circle_outline;
      case 'recusado':
        return Icons.cancel_outlined;
      default:
        return Icons.error_outline;
    }
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'solicitado':
        return Colors.orange;
      case 'aguardando':
        return Colors.deepPurple;
      case 'concluído':
        return Colors.green;
      case 'recusado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _cancelarSolicitacao(Agendamento agendamento) async {
    try {
      final agendamentoService = AgendamentoService();
      await agendamentoService.atualizarStatusAgendamento(
          agendamento.idAgendamento, 'cancelado');

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitação cancelada com sucesso')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao cancelar solicitação: $e')),
      );
    }
  }

  void _aceitarSolicitacao(Agendamento agendamento) async {
    try {
      final agendamentoService = AgendamentoService();
      await agendamentoService.atualizarStatusAgendamento(
          agendamento.idAgendamento, 'aguardando');

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Solicitação aceita com sucesso')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao aceitar solicitação: $e')),
      );
    }
  }

  void _recusarSolicitacao(Agendamento agendamento) {
    // Abrir modal para confirmar recusa e solicitar motivo
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String motivo = '';
        return AlertDialog(
          title: Text('Recusar Solicitação'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Tem certeza que deseja recusar esta solicitação?'),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Motivo da recusa (obrigatório)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (value) => motivo = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Confirmar'),
              onPressed: () async {
                if (motivo.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Informe o motivo da recusa')),
                  );
                  return;
                }

                try {
                  final agendamentoService = AgendamentoService();
                  await agendamentoService.atualizarStatusAgendamento(
                      agendamento.idAgendamento, 'recusado');

                  // Aqui você poderia adicionar o motivo em um campo específico no banco de dados
                  // Por enquanto, vamos apenas fechar os diálogos e mostrar mensagem
                  Navigator.pop(context); // Fecha o diálogo de confirmação
                  Navigator.pop(context); // Fecha o modal de detalhes

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Solicitação recusada com sucesso')),
                  );
                } catch (e) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao recusar solicitação: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmarPagamento(Agendamento agendamento) async {
    try {
      final agendamentoService = AgendamentoService();
      await agendamentoService.atualizarStatusAgendamento(
          agendamento.idAgendamento, 'confirmado');

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pagamento confirmado com sucesso')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao confirmar pagamento: $e')),
      );
    }
  }

  void _verificarPagamento(Agendamento agendamento) async {
    try {
      // Buscar dados atualizados do agendamento
      final agendamentoService = AgendamentoService();
      final agendamentoAtualizado = await agendamentoService.buscarAgendamento(
          agendamento.idAgendamento);

      Navigator.pop(context);

      // Verificar se o pagamento foi confirmado
      if (agendamentoAtualizado.status == 'confirmado') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pagamento já realizado')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Aguardando pagamento')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao verificar pagamento: $e')),
      );
    }
  }

  void _avaliarServico(Agendamento agendamento) {
    // Abrir modal para avaliação
    showDialog(
      context: context,
      builder: (BuildContext context) {
        double nota = 3.0; // Valor padrão
        return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Avaliar Serviço'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Como você avalia o serviço prestado?'),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${nota.toInt()}'),
                        SizedBox(width: 8),
                        Expanded(
                          child: Slider(
                            value: nota,
                            min: 1,
                            max: 5,
                            divisions: 4,
                            onChanged: (value) {
                              setState(() {
                                nota = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Comentário (opcional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: Text('Cancelar'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  TextButton(
                    child: Text('Enviar Avaliação'),
                    onPressed: () async {
                      // Aqui você implementaria o envio da avaliação para o banco de dados
                      // Por ora, apenas fechamos o modal e exibimos mensagem

                      Navigator.pop(context); // Fecha o diálogo de avaliação
                      Navigator.pop(context); // Fecha o modal de detalhes

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Avaliação enviada com sucesso')),
                      );
                    },
                  ),
                ],
              );
            }
        );
      },
    );
  }

  void _verDetalhes(Agendamento agendamento) async {
    try {
      // Buscar detalhes completos do agendamento
      final agendamentoService = AgendamentoService();
      final detalhes = await agendamentoService.obterDetalhesAgendamento(
          agendamento.idAgendamento);

      // Aqui você pode manter o modal aberto e exibir os detalhes
      // Em vez de fechar como estava fazendo antes

      // Como estamos dentro de um modal que já exibe detalhes,
      // esta função poderia ser usada para atualizar os dados exibidos
      setState(() {
        // Atualizar os detalhes exibidos no modal atual
        // Ex: agendamentoDetalhado = detalhes;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar detalhes: $e')),
      );
    }
  }

// Função para gerenciar ação de minhas ofertas quando status é solicitado
  void _gerenciarSolicitacao(Agendamento agendamento) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Gerenciar Solicitação'),
          content: Text('Como deseja proceder com esta solicitação?'),
          actions: [
            TextButton(
              child: Text('Aceitar'),
              onPressed: () {
                Navigator.pop(context); // Fecha este diálogo
                _aceitarSolicitacao(agendamento);
              },
            ),
            TextButton(
              child: Text('Recusar'),
              onPressed: () {
                Navigator.pop(context); // Fecha este diálogo
                _recusarSolicitacao(agendamento);
              },
            ),
            TextButton(
              child: Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }
}


