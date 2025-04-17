import 'package:flutter/material.dart';
import 'package:servblu/models/servicos/agendamento.dart';
import 'package:servblu/services/agendamento_service.dart';
import 'package:servblu/widgets/buildheaderwithtabs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servblu/utils/formatters/agendamento_formatter.dart';
import 'package:servblu/utils/helpers/agendamento_status_helper.dart';
import 'package:servblu/services/agendamento_actions.dart';

import '../../widgets/tool_loading.dart'; // Verifique o caminho

// Ordem das tabs de status - IMPORTANTE para os índices
final List<String> tabItems = [
  'Solicitado',  // Índice 0
  'Aguardando',  // Índice 1
  'Concluído',   // Índice 2
  'Recusado'     // Índice 3
];

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int _currentTabIndex = 0; // 0: Minhas Solicitações, 1: Minhas Ofertas
  int _currentStatusIndex = 0; // Índice baseado na lista tabItems

  final AgendamentoService _agendamentoService = AgendamentoService();
  List<Agendamento> _agendamentos = [];
  bool _isLoading = true;
  String? _errorMessage;
  Agendamento? _selectedAgendamento; // Mantém o agendamento selecionado para o modal

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
          final dataServico = DateTime.parse(agendamento.dataServico);
          final horarioInt = int.tryParse(agendamento.idHorario.toString()) ?? 0;
          final hora = horarioInt ~/ 100;
          final minuto = horarioInt % 100;
          final dataHoraServico = DateTime(
            dataServico.year, dataServico.month, dataServico.day, hora, minuto,
          );

          if (now.isAfter(dataHoraServico)) {
            print("Agendamento ${agendamento.idAgendamento} confirmado passou do prazo, marcando como concluído.");
            atualizacoes.add(
                _agendamentoService.atualizarStatusAgendamento(
                    agendamento.idAgendamento,
                    'concluído'
                )
            );
          }
        } catch (e) {
          print('Erro ao verificar/converter data/hora do agendamento ${agendamento.idAgendamento}: $e');
        }
      }
    }

    if (atualizacoes.isNotEmpty) {
      print("Aguardando ${atualizacoes.length} atualizações de status para concluído...");
      await Future.wait(atualizacoes);
      print("Atualizações concluídas.");
      // Indica que precisa recarregar os dados depois
      return Future.value(); // Sinaliza que houve mudança
    }
  }

  Future<void> _carregarAgendamentos() async {
    if (!mounted) return; // Evita erro se o widget for removido durante a carga
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final String userId = Supabase.instance.client.auth.currentUser!.id;
      List<Agendamento> agendamentosBase;

      // 1. Carregar agendamentos baseados na ROL (Cliente/Prestador)
      if (_currentTabIndex == 0) {
        agendamentosBase = await _agendamentoService.listarAgendamentosPorCliente(userId);
      } else {
        agendamentosBase = await _agendamentoService.listarAgendamentosPorPrestador(userId);
      }

      // 2. Verificar e atualizar status (ex: confirmado -> concluído)
      //    Se houver atualizações, vamos precisar recarregar depois.
      bool precisaRecarregarAposUpdate = false;
      try {
        await _verificarEAtualizarStatusAgendamentos(agendamentosBase);
        // Se a função acima atualizou algo, recarregamos para pegar os status novos
        if (agendamentosBase.any((a) => a.status == 'confirmado' /* && condição de ter passado */)) {
          // A lógica exata da condição de ter passado já está em _verificarEAtualizar...
          // A chamada Future.wait garante que as atualizações terminaram.
          // Recarregamos para garantir que a lista local reflita o BD.
          print("Recarregando agendamentos após atualização de status...");
          if (_currentTabIndex == 0) {
            agendamentosBase = await _agendamentoService.listarAgendamentosPorCliente(userId);
          } else {
            agendamentosBase = await _agendamentoService.listarAgendamentosPorPrestador(userId);
          }
          precisaRecarregarAposUpdate = true; // Apenas para log, a recarga já foi feita
        }
      } catch (e) {
        print("Erro durante _verificarEAtualizarStatusAgendamentos: $e");
        // Continua mesmo assim, mas loga o erro.
      }


      // 3. Filtrar por status baseado na aba de STATUS atual
      List<String> statusFiltro = [];
      switch (_currentStatusIndex) {
        case 0: statusFiltro = ['solicitado']; break; // Solicitado
        case 1: statusFiltro = ['aguardando', 'confirmado']; break; // Aguardando (e Pago)
        case 2: statusFiltro = ['concluído']; break; // Concluído
        case 3: statusFiltro = ['recusado']; break; // Recusado
        default: statusFiltro = []; // Caso inesperado
      }

      List<Agendamento> agendamentosFiltrados = agendamentosBase
          .where((a) => statusFiltro.contains(a.status))
          .toList();

      // 4. Ordenar (opcional, exemplo para 'Aguardando')
      if (_currentStatusIndex == 1) { // Aba 'Aguardando'
        agendamentosFiltrados.sort((a, b) {
          // 'confirmado' (Pago) vem antes de 'aguardando'
          if (a.status == 'confirmado' && b.status != 'confirmado') return -1;
          if (a.status != 'confirmado' && b.status == 'confirmado') return 1;
          // Se status iguais, ordena por data (mais antigo primeiro)
          try {
            return DateTime.parse(a.dataServico).compareTo(DateTime.parse(b.dataServico));
          } catch (_) { return 0;} // Fallback se data inválida
        });
      } else {
        // Ordenação padrão por data para outras abas (mais antigo primeiro)
        agendamentosFiltrados.sort((a, b) {
          try {
            return DateTime.parse(a.dataServico).compareTo(DateTime.parse(b.dataServico));
          } catch (_) { return 0;}
        });
      }


      if (mounted) {
        setState(() {
          _agendamentos = agendamentosFiltrados;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro em _carregarAgendamentos: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Erro ao carregar: ${e.toString()}";
          _agendamentos = []; // Limpa a lista em caso de erro
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar agendamentos: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }


  // NOVA FUNÇÃO DE CALLBACK para lidar com o resultado das ações
  void _handleActionCompletion(bool success, {String? newStatus}) {
    // 1. Fecha o Modal de Detalhes (se ainda estiver aberto) ANTES de setState
    //    Verifica se o modal está na pilha de navegação deste contexto.
    if (Navigator.canPop(context)) {
      print("Modal de detalhes sendo fechado por _handleActionCompletion.");
      Navigator.pop(context);
    } else {
      print("Modal de detalhes já estava fechado ou não pertence a este contexto.");
    }

    if (success) {
      print("Ação completada com sucesso. Novo status recebido: $newStatus");
      int targetTabIndex = _currentStatusIndex; // Mantém a aba atual por padrão

      // 2. Verifica se precisa mudar de aba de status (Lógica do Prestador Aceitando/Recusando)
      bool shouldChangeTab = _currentTabIndex == 1 && // É Prestador ("Minhas Ofertas")
          _currentStatusIndex == 0 && // Estava na aba "Solicitado"
          newStatus != null;        // A ação resultou num novo status relevante

      if (shouldChangeTab) {
        print("Condições para mudança de aba atendidas.");
        if (newStatus == 'aguardando') {
          targetTabIndex = 1; // Índice da tab 'Aguardando'
          print("Mudando para a aba 'Aguardando' (índice $targetTabIndex).");
        } else if (newStatus == 'recusado') {
          targetTabIndex = 3; // Índice da tab 'Recusado'
          print("Mudando para a aba 'Recusado' (índice $targetTabIndex).");
        } else {
          print("Novo status '$newStatus' não requer mudança de aba específica.");
          shouldChangeTab = false; // Não muda se o status não for aguardando/recusado
        }
      } else {
        print("Condições para mudança de aba NÃO atendidas. Mantendo aba atual (índice $_currentStatusIndex).");
      }

      // 3. Atualiza o estado e recarrega os agendamentos para a aba correta
      //    Usar addPostFrameCallback garante que setState ocorra após o build atual (importante após pop).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // Garante que o widget ainda está na árvore
          print("Agendando setState para atualizar _currentStatusIndex para $targetTabIndex e recarregar.");
          setState(() {
            _currentStatusIndex = targetTabIndex; // Define a aba de status correta
            _selectedAgendamento = null; // Limpa seleção após ação
          });
          _carregarAgendamentos(); // Carrega os dados para a aba (possivelmente) nova
        } else {
          print("Widget não montado no momento do addPostFrameCallback. Abortando setState.");
        }
      });

    } else {
      // 4. Se a ação falhou, a mensagem de erro já foi (ou deveria ter sido) mostrada por AgendamentoActions.
      //    Não mudamos de aba. Podemos optar por recarregar a lista atual para consistência.
      print("Ação falhou. Nenhuma mudança de aba. Recarregando a aba atual para segurança.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _selectedAgendamento = null; // Limpa seleção
          _carregarAgendamentos();
        }
      });
    }
  }


  void _mostrarDetalhesAgendamento(Agendamento agendamento) {
    setState(() {
      _selectedAgendamento = agendamento; // Guarda o agendamento selecionado
    });

    String statusDisplay = AgendamentoStatusHelper.getDescriptionForStatus(agendamento.status); // Usa descrição
    if (agendamento.status == 'confirmado') {
      statusDisplay = 'Pago e Agendado'; // Texto especial para confirmado
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) => DraggableScrollableSheet( // Usar modalContext aqui
        initialChildSize: 0.6,
        minChildSize: 0.4, // Ajuste se necessário
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Container( // Container para cor e padding
          color: Colors.white, // Cor de fundo do modal
          padding: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0, top: 10.0),
          child: Column( // Usar Column diretamente
            children: [
              // Handle do Draggable
              Center(
                child: Container(
                  width: 60, height: 5,
                  decoration: BoxDecoration( color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 20),

              // Conteúdo rolável
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nome do serviço (grande)
                      Text( agendamento.nomeServico ?? 'Serviço', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),

                      // Detalhes
                      _buildInfoRow('Data', AgendamentoFormatter.formatarData(agendamento.dataServico)),
                      _buildInfoRow('Horário', AgendamentoFormatter.formatarHorario(agendamento.idHorario)),
                      _buildInfoRow(
                          _currentTabIndex == 0 ? 'Prestador' : 'Cliente',
                          _currentTabIndex == 0
                              ? agendamento.nomePrestador ?? 'Não disponível'
                              : agendamento.nomeCliente ?? 'Não disponível'
                      ),
                      _buildInfoRow('Valor', agendamento.precoServico != null ? 'R\$ ${agendamento.precoServico!.toStringAsFixed(2)}' : 'N/A'),
                      _buildInfoRow('Forma de pagamento', agendamento.formaPagamento ?? (agendamento.isPix == true ? 'Pix' : 'A combinar')),
                      _buildInfoRow('ID do agendamento', AgendamentoFormatter.formatarId(agendamento.idAgendamento)),
                      const SizedBox(height: 30),

                      // Status com ícone e texto
                      Row(
                        children: [
                          Icon(
                            AgendamentoStatusHelper.getIconForStatus(agendamento.status),
                            color: AgendamentoStatusHelper.getColorForStatus(agendamento.status),
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Expanded( // Para quebrar linha se necessário
                            child: Text(
                              'Status: $statusDisplay',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AgendamentoStatusHelper.getColorForStatus(agendamento.status),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Motivo da recusa (se aplicável)
                      if (agendamento.status == 'recusado' && agendamento.motivoRecusa != null && agendamento.motivoRecusa!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildInfoRow('Motivo da Recusa', agendamento.motivoRecusa!),
                      ],

                      const SizedBox(height: 40),

                      // Botão de ação
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // A função executeActionForStatus agora recebe o novo callback _handleActionCompletion
                            AgendamentoActions.executeActionForStatus(
                              modalContext, // Usa o contexto do modal
                              agendamento.status,
                              agendamento,
                              _currentTabIndex,
                              _handleActionCompletion, // <--- Passa o callback modificado
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(
                            AgendamentoStatusHelper.getButtonTextForStatus(agendamento.status, _currentTabIndex),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20), // Espaço extra no final
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      print("Modal de detalhes fechado (whenComplete). Limpando _selectedAgendamento.");
      // Limpar a seleção quando o modal for fechado manualmente ou por pop
      // Usar addPostFrameCallback para evitar erro de setState durante build/layout
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted && _selectedAgendamento?.idAgendamento == agendamento.idAgendamento) {
          setState(() { _selectedAgendamento = null; });
        }
      });
    });
  }


  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 16)),
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
          // Header principal (Cliente/Prestador)
          BuildHeaderWithTabs(
            title: 'Agendamentos',
            backPage: false,
            tabs: const ['Minhas Solicitações', 'Minhas Ofertas'],
            currentTabIndex: _currentTabIndex,
            onTabChanged: (index) {
              if (_currentTabIndex != index) {
                setState(() {
                  _currentTabIndex = index;
                  _currentStatusIndex = 0; // Reset status tab ao trocar ROL
                  _agendamentos = []; // Limpa a lista antiga
                  _isLoading = true; // Mostra loading imediatamente
                });
                _carregarAgendamentos();
              }
            },
          ),

          // Barra de TABS de STATUS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduzi padding H
            child: SizedBox(
              height: 40,
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
                ? const Center(child: ToolLoadingIndicator(color: Colors.blue, size: 45))
                : _errorMessage != null
                ? Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700]))))
                : _agendamentos.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Nenhum agendamento "${tabItems[_currentStatusIndex]}" em "${_currentTabIndex == 0 ? 'Minhas Solicitações' : 'Minhas Ofertas'}".',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ),
            )
                : RefreshIndicator(
              color: Colors.blue,
              onRefresh: _carregarAgendamentos,
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 16.0), // Espaço no final da lista
                itemCount: _agendamentos.length,
                itemBuilder: (context, index) {
                  final agendamento = _agendamentos[index];
                  // Adiciona uma Key única para ajudar o Flutter a identificar os itens
                  // especialmente útil quando a lista muda após ações.
                  return _buildAgendamentoCard(agendamento, ValueKey(agendamento.idAgendamento));
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
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          onPressed: () {
            if (_currentStatusIndex != index) {
              setState(() {
                _currentStatusIndex = index;
                _agendamentos = []; // Limpa lista antiga
                _isLoading = true; // Mostra loading
              });
              _carregarAgendamentos();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: isActive ? Colors.blue : Colors.white,
            foregroundColor: isActive ? Colors.white : Colors.blue,
            side: BorderSide(color: Colors.blue.withOpacity(isActive ? 1.0 : 0.5)), // Borda mais sutil se inativo
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            elevation: isActive ? 2 : 0,
            minimumSize: const Size(60, 36), // Garante altura mínima
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }


  // Widget para construir cada card de agendamento
  Widget _buildAgendamentoCard(Agendamento agendamento, Key key) { // Adicionada a Key
    String statusDisplay = agendamento.status;
    if (agendamento.status == 'confirmado') {
      statusDisplay = 'Pago e Agendado';
    } else {
      // Capitaliza a primeira letra do status para exibição no card
      statusDisplay = statusDisplay[0].toUpperCase() + statusDisplay.substring(1);
    }

    return Card(
      key: key, // Usa a Key passada
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), // Menos espaço vertical
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _mostrarDetalhesAgendamento(agendamento),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nome do serviço e Nome Cliente/Prestador (dependendo da aba)
              Text(
                agendamento.nomeServico ?? 'Serviço Indisponível',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _currentTabIndex == 0
                    ? 'Prestador: ${agendamento.nomePrestador ?? "Não informado"}'
                    : 'Cliente: ${agendamento.nomeCliente ?? "Não informado"}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                maxLines: 1, overflow: TextOverflow.ellipsis,
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
              const SizedBox(height: 12),

              // Status à direita
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AgendamentoStatusHelper.getColorForStatus(agendamento.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AgendamentoStatusHelper.getColorForStatus(agendamento.status),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AgendamentoStatusHelper.getIconForStatus(agendamento.status),
                          color: AgendamentoStatusHelper.getColorForStatus(agendamento.status),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusDisplay, // Usa o status capitalizado ou 'Pago e Agendado'
                          style: TextStyle(
                            fontSize: 12,
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
}