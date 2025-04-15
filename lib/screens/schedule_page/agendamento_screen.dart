import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:servblu/models/servicos/disponibilidade.dart';
import 'package:servblu/models/servicos/agendamento.dart';
import 'package:servblu/services/disponibilidade_service.dart';
import 'package:servblu/services/agendamento_service.dart';
import 'package:uuid/uuid.dart';
import 'package:servblu/utils/helpers/date_helper.dart';

class AgendamentoScreen extends StatefulWidget {
  final String idServico;
  final String idPrestador;
  final String? nomeServico; // Novo parâmetro para o nome do serviço

  const AgendamentoScreen({
    Key? key,
    required this.idServico,
    required this.idPrestador,
    this.nomeServico,
  }) : super(key: key);

  @override
  _AgendamentoScreenState createState() => _AgendamentoScreenState();
}

class _AgendamentoScreenState extends State<AgendamentoScreen> {
  final DisponibilidadeService _disponibilidadeService = DisponibilidadeService();
  final AgendamentoService _agendamentoService = AgendamentoService();
  final Uuid _uuid = Uuid();

  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();

  Map<String, List<HorarioDisponivel>> _disponibilidadePrestador = {};
  List<int> _horariosDisponiveis = [];
  int? _selectedHorario;
  bool _isLoading = true;
  bool _isPix = false;
  String _formaPagamento = 'Dinheiro'; // Valor padrão

  final supabase = Supabase.instance.client;

  // Opções de pagamento disponíveis
  final List<String> _opcoesPagamento = [
    'Dinheiro',
    'Cartão de Crédito',
    'Cartão de Débito',
    'Pix',
    'Transferência Bancária'
  ];

  // Lista de dias da semana em português
  final List<String> _diasSemana = DateHelper.diasSemana;

  @override
  void initState() {
    super.initState();
    _carregarDisponibilidade();
  }

  Future<void> _carregarDisponibilidade() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _disponibilidadePrestador = await _disponibilidadeService.obterDisponibilidade(widget.idPrestador);

      // Verifica se há algum dia disponível, se não houver, mostra mensagem
      if (_disponibilidadePrestador.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('O prestador não possui horários disponíveis.')),
        );
      } else {
        _verificarHorariosDisponiveisPorData(_selectedDay);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar disponibilidade: $e')),
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

  void _verificarHorariosDisponiveisPorData(DateTime data) {
    // Obter o dia da semana em português
    // DateTime.weekday retorna 1 para segunda-feira, ..., 7 para domingo
    String diaSemana = _diasSemana[data.weekday - 1];

    setState(() {
      _horariosDisponiveis = [];
      _selectedHorario = null;

      // Se o prestador tem disponibilidade para este dia da semana
      if (_disponibilidadePrestador.containsKey(diaSemana)) {
        // Extrair apenas os valores dos horários
        _horariosDisponiveis = _disponibilidadePrestador[diaSemana]!
            .map((h) => h.horario)
            .toList()
        // Ordenar horários em ordem crescente
          ..sort();
      }
    });
  }

  Future<void> _criarAgendamento() async {
    if (_selectedHorario == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um horário')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Formatar a data para o formato esperado pelo banco de dados
      String dataFormatada = DateFormat('yyyy-MM-dd').format(_selectedDay);

      // Identificar qual é o id_disponibilidade para o dia da semana selecionado
      String diaSemana = _diasSemana[_selectedDay.weekday - 1];
      List<HorarioDisponivel> horarios = _disponibilidadePrestador[diaSemana] ?? [];

      // Encontrar o horário específico selecionado
      HorarioDisponivel? horarioObj = horarios.firstWhere(
            (h) => h.horario == _selectedHorario,
        orElse: () => throw Exception('Horário não encontrado'),
      );

      // Para simplificar, vamos usar o próprio valor numérico do horário
      int idHorarioParaAgendamento = _selectedHorario!; // Já verificamos que não é nulo acima

      // Verificar se o horário já está agendado para esta data usando o valor numérico
      bool disponivel = await _agendamentoService.verificarDisponibilidade(
          widget.idPrestador,
          dataFormatada,
          idHorarioParaAgendamento.toString() // Convertemos para string por precaução
      );

      if (!disponivel) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Este horário já foi reservado. Por favor, escolha outro.')),
        );
        return;
      }

      // Criar o agendamento
      String idCliente = Supabase.instance.client.auth.currentUser!.id;

      // Define o isPix com base na forma de pagamento selecionada
      bool isPix = _formaPagamento == 'Pix';

      // Criar o novo agendamento com a forma de pagamento
      Agendamento novoAgendamento = Agendamento(
        idAgendamento: _uuid.v4(),
        idCliente: idCliente,
        idPrestador: widget.idPrestador,
        idServico: widget.idServico,
        idHorario: idHorarioParaAgendamento.toString(),
        dataServico: dataFormatada,
        status: 'solicitado',
        isPix: isPix,
        formaPagamento: _formaPagamento,
        nomeServico: widget.nomeServico,
      );

      await _agendamentoService.criarAgendamento(novoAgendamento);

      // Exibir mensagem de sucesso e voltar para a tela anterior
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agendamento solicitado com sucesso!')),
        );
        // Sistema Notificação
        final response = await supabase.functions.invoke('send-notification', body: {
          'to_user_id': widget.idPrestador,   // <— chave correta
          'title': 'Novo Agendamento!',
          'body': 'Um usuário acabou de agendar seu serviço. Confira agora!'
        });

        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar agendamento: $e')),
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

  // Formatar horário de inteiro para string (ex: 930 -> 9:30)
  String _formatarHorario(int horario) {
    String horarioStr = horario.toString().padLeft(4, '0');
    return '${horarioStr.substring(0, 2)}:${horarioStr.substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendar Serviço'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nome do serviço
            if (widget.nomeServico != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Card(
                  elevation: 2,
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Serviço:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.nomeServico!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const Text(
              'Selecione uma data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Calendário
            Card(
              elevation: 4,
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 90)),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _verificarHorariosDisponiveisPorData(selectedDay);
                  });
                },
                // Desabilitar dias sem disponibilidade
                enabledDayPredicate: (day) {
                  String diaSemana = _diasSemana[day.weekday - 1];
                  return _disponibilidadePrestador.containsKey(diaSemana);
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Mostrar dia selecionado
            Text(
              'Data selecionada: ${DateFormat('dd/MM/yyyy').format(_selectedDay)} (${_diasSemana[_selectedDay.weekday - 1]})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            // Seleção de horários
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecione um horário',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _horariosDisponiveis.isEmpty
                    ? const Text('Não há horários disponíveis para este dia.')
                    : Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: _horariosDisponiveis.map((horario) {
                    return ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedHorario = horario;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedHorario == horario
                            ? Theme.of(context).primaryColor
                            : Colors.grey.shade200,
                        foregroundColor: _selectedHorario == horario
                            ? Colors.white
                            : Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: Text(_formatarHorario(horario)),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Seleção de forma de pagamento
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Forma de Pagamento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: _opcoesPagamento.map((opcao) {
                        final bool isPagamentoPix = opcao == 'Pix';

                        return RadioListTile<String>(
                          title: Row(
                            children: [
                              Text(opcao),
                              if (isPagamentoPix)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    '(Pagamento pelo app)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          value: opcao,
                          groupValue: _formaPagamento,
                          onChanged: (value) {
                            setState(() {
                              _formaPagamento = value!;
                              _isPix = isPagamentoPix;
                            });
                          },
                          activeColor: Theme.of(context).primaryColor,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Botão para confirmar agendamento
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedHorario == null ? null : _criarAgendamento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Confirmar Agendamento',
                  style: TextStyle(
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
    );
  }
}