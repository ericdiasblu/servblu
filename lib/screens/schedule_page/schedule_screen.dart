import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/agendamento.dart';
import 'package:servblu/services/agendamento_service.dart';
import 'package:servblu/widgets/buildheaderwithtabs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servblu/utils/formatters/agendamento_formatter.dart';
import 'package:servblu/utils/helpers/agendamento_status_helper.dart';
import 'package:servblu/services/agendamento_actions.dart';

// Passo 1: Remover 'Confirmado' da lista de tabs
final List<String> tabItems = [
  'Solicitado',
  'Aguardando', // Agora engloba 'aguardando' e 'confirmado'
  'Concluído',
  'Recusado'
];

// (O resto da classe ScheduleScreen permanece igual até initState)

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _currentTabIndex = 0; // 0: Minhas Solicitações, 1: Minhas Ofertas
  int _currentStatusIndex = 0; // 0: Solicitado, 1: Aguardando, 2: Concluído, 3: Recusado

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

  Future<void> _verificarEAtualizarStatusAgendamentos(List<Agendamento> agendamentos) async {
    final now = DateTime.now();
    final atualizacoes = <Future<void>>[];

    for (final agendamento in agendamentos) {
      // Verifica agendamentos com status "confirmado"
      if (agendamento.status == 'confirmado') {
        try {
          // Converter a data de string para DateTime
          final dataServico = DateTime.parse(agendamento.dataServico);

          // Converter o horário de int para horas e minutos
          final horarioInt = int.tryParse(agendamento.idHorario.toString()) ?? 0;
          final hora = horarioInt ~/ 100;
          final minuto = horarioInt % 100;

          // Criar um DateTime com a data do serviço e o horário
          final dataHoraServico = DateTime(
            dataServico.year,
            dataServico.month,
            dataServico.day,
            hora,
            minuto,
          );

          // Se o horário do serviço já passou, atualizar o status para 'concluído'
          if (now.isAfter(dataHoraServico)) {
            atualizacoes.add(
                _agendamentoService.atualizarStatusAgendamento(
                    agendamento.idAgendamento,
                    'concluído'
                )
            );
          }
        } catch (e) {
          print('Erro ao verificar agendamento ${agendamento.idAgendamento}: $e');
        }
      }
    }

    // Esperar todas as atualizações terminarem
    if (atualizacoes.isNotEmpty) {
      await Future.wait(atualizacoes);
    }
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
        agendamentos = await _agendamentoService.listarAgendamentosPorCliente(userId);
      } else {
        // Minhas Ofertas (como prestador)
        agendamentos = await _agendamentoService.listarAgendamentosPorPrestador(userId);
      }

      // Verificar e atualizar status de agendamentos que já passaram do horário
      await _verificarEAtualizarStatusAgendamentos(agendamentos);

      // Recarregar a lista após as atualizações (se alguma atualização ocorreu)
      if (agendamentos.any((a) => a.status == 'confirmado' && /* condição de ter passado a data/hora */ false)) { // A lógica exata pode precisar de ajuste se _verificarEAtualizar não retornar info
        if (_currentTabIndex == 0) {
          agendamentos = await _agendamentoService.listarAgendamentosPorCliente(userId);
        } else {
          agendamentos = await _agendamentoService.listarAgendamentosPorPrestador(userId);
        }
      }


      // Filtrar por status com base no novo mapeamento de tabs
      List<String> statusFiltro = [];
      switch (_currentStatusIndex) {
        case 0: // Solicitado
          statusFiltro = ['solicitado'];
          break;
        case 1: // Aguardando (agora inclui 'aguardando' e 'confirmado')
          statusFiltro = ['aguardando', 'confirmado']; // MODIFICADO AQUI
          break;
        case 2: // Concluído
          statusFiltro = ['concluído'];
          break;
        case 3: // Recusado
          statusFiltro = ['recusado'];
          break;
        default:
          statusFiltro = ['solicitado'];
      }

      // Filtrar a lista de agendamentos pelos status permitidos na tab atual
      agendamentos = agendamentos.where((a) => statusFiltro.contains(a.status)).toList();

      // Opcional: Ordenar dentro da aba 'Aguardando' para mostrar 'confirmado' primeiro/último se desejado
      if (_currentStatusIndex == 1) {
        agendamentos.sort((a, b) {
          // Exemplo: Coloca 'confirmado' antes de 'aguardando'
          if (a.status == 'confirmado' && b.status != 'confirmado') return -1;
          if (a.status != 'confirmado' && b.status == 'confirmado') return 1;
          // Se ambos têm o mesmo status ou nenhum é 'confirmado', mantenha a ordem original ou ordene por data, etc.
          return a.dataServico.compareTo(b.dataServico); // Exemplo: ordena por data
        });
      }


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


  void _mostrarDetalhesAgendamento(Agendamento agendamento) {
    setState(() {
      _selectedAgendamento = agendamento;
    });

    // Define o texto descritivo para o status 'confirmado'
    String statusDisplay = agendamento.status;
    if (agendamento.status == 'confirmado') {
      statusDisplay = 'Pago e Agendado'; // <- TEXTO PERSONALIZADO
    }

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
                _buildInfoRow('Data', AgendamentoFormatter.formatarData(agendamento.dataServico)),
                _buildInfoRow(
                    'Horário', AgendamentoFormatter.formatarHorario(agendamento.idHorario)),

                // Mostrar nome do prestador ou cliente dependendo da aba
                _buildInfoRow(
                    _currentTabIndex == 0 ? 'Prestador' : 'Cliente',
                    _currentTabIndex == 0
                        ? agendamento.nomePrestador ?? 'Não disponível' // Adicionado fallback
                        : agendamento.nomeCliente ?? 'Não disponível'), // Adicionado fallback
                _buildInfoRow('Valor', agendamento.precoServico != null ? 'R\$ ${agendamento.precoServico!.toStringAsFixed(2)}' : 'N/A'), // Formatado e com fallback
                // Forma de pagamento
                _buildInfoRow(
                    'Forma de pagamento',
                    agendamento.formaPagamento ?? (agendamento.isPix == true ? 'Pix' : 'N/A') // Verificação de nullabilidade
                ),

                // ID do agendamento
                _buildInfoRow('ID do agendamento', AgendamentoFormatter.formatarId(agendamento.idAgendamento)),

                const SizedBox(height: 30),

                // Status com ícone e texto personalizado
                Row(
                  children: [
                    Icon(
                      AgendamentoStatusHelper.getIconForStatus(agendamento.status),
                      // Usar a cor do status original ('confirmado') para manter a consistência visual
                      color: AgendamentoStatusHelper.getColorForStatus(agendamento.status),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      // Usar o texto personalizado definido acima
                      'Status: $statusDisplay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        // Usar a cor do status original ('confirmado')
                        color: AgendamentoStatusHelper.getColorForStatus(agendamento.status),
                      ),
                    ),
                  ],
                ),

                // Adiciona o motivo da recusa se o status for 'recusado'
                if (agendamento.status == 'recusado' && agendamento.motivoRecusa != null && agendamento.motivoRecusa!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildInfoRow('Motivo da Recusa', agendamento.motivoRecusa!),
                ],

                const SizedBox(height: 40),

                // Botão de ação baseado no status (a lógica interna do AgendamentoActions já lida com o status 'confirmado')
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // A função executeActionForStatus já sabe o que fazer com base no agendamento.status ('confirmado')
                      AgendamentoActions.executeActionForStatus(
                        context,
                        agendamento.status, // Passa o status real ('confirmado')
                        agendamento,
                        _currentTabIndex, // Passa a aba de ROL (Solicitações/Ofertas)
                            () {
                          // Função de callback para atualizar a UI
                          // Fecha o modal após a ação ser executada com sucesso (se ainda estiver aberto)
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                          _carregarAgendamentos(); // Recarrega a lista
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      // O texto do botão também deve vir do status real ('confirmado')
                      AgendamentoStatusHelper.getButtonTextForStatus(agendamento.status, _currentTabIndex),
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
    ).whenComplete(() {
      // Opcional: Limpar _selectedAgendamento quando o modal for fechado
      // setState(() {
      //   _selectedAgendamento = null;
      // });
    });
  }


  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140, // Ajuste a largura conforme necessário
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header principal com as tabs de ROL (Solicitações/Ofertas)
          BuildHeaderWithTabs(
            title: 'Agendamentos',
            backPage: false,
            tabs: ['Minhas Solicitações', 'Minhas Ofertas'],
            currentTabIndex: _currentTabIndex,
            onTabChanged: (index) {
              setState(() {
                _currentTabIndex = index;
                _currentStatusIndex = 0; // Reset status tab ao trocar de ROL
              });
              _carregarAgendamentos();
            },
          ),

          // Barra de TABS de STATUS (Agora sem 'Confirmado')
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              height: 40,
              // Usando Row com Expanded para distribuir espaço, pois ListView pode não ser ideal para poucos itens fixos
              child: Row(
                children: List.generate(tabItems.length, (index) {
                  return _buildTabButton(tabItems[index], index);
                }),
              ),
            ),
          ),

          // Conteúdo (Lista de Agendamentos)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center( /* ... Error message widget ... */ )
                : _agendamentos.isEmpty
                ? Center(
              child: Padding( // Adiciona padding para não colar nas bordas
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Nenhum agendamento encontrado para "${tabItems[_currentStatusIndex]}" em "${_currentTabIndex == 0 ? 'Minhas Solicitações' : 'Minhas Ofertas'}"',
                  textAlign: TextAlign.center, // Centraliza o texto
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]), // Estilo mais suave
                ),
              ),
            )
                : RefreshIndicator( // Adiciona RefreshIndicator
              onRefresh: _carregarAgendamentos,
              child: ListView.builder(
                itemCount: _agendamentos.length,
                itemBuilder: (context, index) {
                  final agendamento = _agendamentos[index];
                  return _buildAgendamentoCard(agendamento);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para construir cada botão da tab de status
  Widget _buildTabButton(String text, int index) {
    bool isActive = _currentStatusIndex == index;
    return Expanded( // Faz com que cada botão tente ocupar o mesmo espaço
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4), // Espaçamento entre botões
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              _currentStatusIndex = index;
            });
            _carregarAgendamentos(); // Recarrega os dados para a nova tab de status
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? Colors.blue : Colors.white,
            foregroundColor: isActive ? Colors.white : Colors.blue,
            side: const BorderSide(color: Colors.blue),
            shape: RoundedRectangleBorder( // Bordas arredondadas
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4), // Ajuste o padding interno
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), // Ajuste o estilo do texto
            elevation: isActive ? 2 : 0, // Sombra sutil quando ativo
          ),
          child: Text(
            text,
            textAlign: TextAlign.center, // Garante centralização
            overflow: TextOverflow.ellipsis, // Evita quebra de linha feia
            maxLines: 1,
          ),
        ),
      ),
    );
  }


  // Widget para construir cada card de agendamento
  Widget _buildAgendamentoCard(Agendamento agendamento) {

    // Define o texto descritivo para o status 'confirmado' no card
    String statusDisplay = agendamento.status;
    if (agendamento.status == 'confirmado') {
      statusDisplay = 'Pago e Agendado'; // <- TEXTO PERSONALIZADO para o card
    }

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
              // Nome do serviço
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
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    AgendamentoFormatter.formatarData(agendamento.dataServico),
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    AgendamentoFormatter.formatarHorario(agendamento.idHorario),
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ],
              ),

              const SizedBox(height: 12), // Aumenta o espaço antes do status

              // Indicador de status (agora na linha de baixo e à direita)
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Alinha à direita
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Ajuste o padding
                    decoration: BoxDecoration(
                      // Usar a cor do status original ('confirmado') para manter a consistência visual
                      color: AgendamentoStatusHelper.getColorForStatus(agendamento.status)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12), // Mais arredondado
                      border: Border.all(
                        // Usar a cor do status original ('confirmado')
                        color: AgendamentoStatusHelper.getColorForStatus(agendamento.status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          // Usar o ícone do status original ('confirmado')
                          AgendamentoStatusHelper.getIconForStatus(agendamento.status),
                          // Usar a cor do status original ('confirmado')
                          color: AgendamentoStatusHelper.getColorForStatus(agendamento.status),
                          size: 14,
                        ),
                        const SizedBox(width: 6), // Aumenta espaço para o ícone
                        Text(
                          // Usar o texto personalizado definido acima para o card
                          statusDisplay,
                          style: TextStyle(
                            fontSize: 12,
                            // Usar a cor do status original ('confirmado')
                            color: AgendamentoStatusHelper.getColorForStatus(agendamento.status),
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
} // Fim da classe _ScheduleScreenState