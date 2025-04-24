import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servblu/router/routes.dart';
import 'package:servblu/widgets/build_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servblu/services/disponibilidade_service.dart';
import 'package:servblu/models/servicos/disponibilidade.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../widgets/tool_loading.dart';

class DisponibilidadeScreen extends StatefulWidget {
  const DisponibilidadeScreen({super.key});

  @override
  _DisponibilidadeScreenState createState() => _DisponibilidadeScreenState();
}

class _DisponibilidadeScreenState extends State<DisponibilidadeScreen> with TickerProviderStateMixin {
  final SupabaseClient supabase = Supabase.instance.client;
  final DisponibilidadeService disponibilidadeService = DisponibilidadeService();

  // Map que guarda os dias selecionados (chave: dia da semana, valor: Set de horários)
  final Map<String, Set<int>> disponibilidade = {};

  // Map para armazenar o id_disponibilidade de cada dia
  final Map<String, String> idsDias = {};

  // Set para rastrear os dias originalmente carregados - para poder detectar remoções
  final Set<String> diasOriginais = {};

  // Flag para controlar se os dados estão carregando
  bool isLoading = true;

  // Flag para determinar se estamos editando ou criando
  bool isEditing = false;

  // Dias disponíveis para seleção
  final List<String> diasSemana = [
    'Segunda-feira',
    'Terça-feira',
    'Quarta-feira',
    'Quinta-feira',
    'Sexta-feira',
    'Sábado',
    'Domingo'
  ];

  // Códigos de dias para ícones
  final Map<String, IconData> diasIcons = {
    'Segunda-feira': Icons.looks_one,
    'Terça-feira': Icons.looks_two,
    'Quarta-feira': Icons.looks_3,
    'Quinta-feira': Icons.looks_4,
    'Sexta-feira': Icons.looks_5,
    'Sábado': Icons.weekend,
    'Domingo': Icons.wb_sunny,
  };

  // Horários disponíveis para seleção (ex.: 900 = 09:00, 1300 = 13:00, etc.)
  final List<int> horarios = [900, 1000, 1100, 1400, 1500, 1600, 1700, 1800];

  // Controller para a animação do calendário
  late TabController _tabController;

  // Lista de dias selecionados para uso no TabController
  List<String> diasSelecionados = [];

  @override
  void initState() {
    super.initState();
    // Inicialmente não temos dias selecionados
    _tabController = TabController(length: 0, vsync: this);
    _carregarDisponibilidade();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Método para reconstruir o TabController quando o número de dias muda
  void _atualizarTabController() {
    // Atualiza a lista de dias selecionados em ordem
    diasSelecionados = disponibilidade.keys.toList();

    // Cria um novo controller com o número correto de tabs
    final int index = _tabController.index.clamp(0, diasSelecionados.length - 1 < 0 ? 0 : diasSelecionados.length - 1);
    _tabController.dispose();
    _tabController = TabController(
      length: diasSelecionados.length,
      vsync: this,
      initialIndex: diasSelecionados.isEmpty ? 0 : (index >= diasSelecionados.length ? 0 : index),
    );
  }

  /// Carrega a disponibilidade existente do usuário
  Future<void> _carregarDisponibilidade() async {
    setState(() {
      isLoading = true;
    });

    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final Map<String, List<HorarioDisponivel>> dispExistente =
      await disponibilidadeService.obterDisponibilidade(user.id);

      // Se temos dados, estamos editando
      isEditing = dispExistente.isNotEmpty;

      // Percorre os dias e horários carregados e atualiza os maps
      for (var dia in dispExistente.keys) {
        if (dispExistente[dia]!.isNotEmpty) {
          // Obtém o id_disponibilidade do primeiro item (todos os horários do mesmo dia terão o mesmo id_disponibilidade)
          idsDias[dia] = dispExistente[dia]![0].idDisponibilidade;

          // Cria um Set para os horários deste dia
          disponibilidade[dia] = <int>{};

          // Adiciona todos os horários ao Set
          for (var horario in dispExistente[dia]!) {
            disponibilidade[dia]!.add(horario.horario);
          }

          // Adiciona este dia ao set de dias originais
          diasOriginais.add(dia);
        }
      }

      // Atualiza o TabController para os dias carregados
      _atualizarTabController();

      // Log para depuração
      print('Dias originais carregados: $diasOriginais');
      print('IDs dos dias: $idsDias');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao carregar disponibilidade: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Alterna a seleção de um dia da semana.
  void toggleDia(String dia) {
    setState(() {
      if (disponibilidade.containsKey(dia)) {
        print('Removendo dia: $dia');
        disponibilidade.remove(dia);
      } else {
        print('Adicionando dia: $dia');
        disponibilidade[dia] = <int>{};
      }

      // Atualiza o TabController após a mudança
      _atualizarTabController();

      // Se adicionamos um dia, navega para a tab desse dia
      if (disponibilidade.containsKey(dia)) {
        final int index = diasSelecionados.indexOf(dia);
        if (index >= 0 && index < _tabController.length) {
          _tabController.animateTo(index);
        }
      }
    });
  }

  /// Alterna a seleção de um horário para um dia.
  void toggleHorario(String dia, int horario) {
    setState(() {
      if (!disponibilidade.containsKey(dia)) return;

      if (disponibilidade[dia]!.contains(horario)) {
        disponibilidade[dia]!.remove(horario);

        // Se todos os horários foram removidos, remove o dia também
        if (disponibilidade[dia]!.isEmpty) {
          print('Todos horários removidos, removendo dia: $dia');
          disponibilidade.remove(dia);

          // Atualiza o TabController após a remoção do dia
          _atualizarTabController();
        }
      } else {
        disponibilidade[dia]!.add(horario);
      }
    });
  }

  /// Salva ou atualiza a disponibilidade
  Future<void> salvarDisponibilidade() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Mostrar loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: ToolLoadingIndicator(color: Colors.blue, size: 45),
      ),
    );

    try {
      // Log para depuração
      print('Salvando disponibilidade...');
      print('Dias atuais: ${disponibilidade.keys}');
      print('Dias originais: $diasOriginais');

      // Verificar dias removidos (estavam em diasOriginais mas não estão mais em disponibilidade)
      for (String diaOriginal in diasOriginais) {
        if (!disponibilidade.containsKey(diaOriginal) && idsDias.containsKey(diaOriginal)) {
          print('Removendo dia que foi desmarcado: $diaOriginal com ID: ${idsDias[diaOriginal]}');

          // Remove o dia e seus horários
          await disponibilidadeService.removerDiaDisponivel(idsDias[diaOriginal]!);
        }
      }

      // Para cada dia no disponibilidade
      for (var dia in disponibilidade.keys) {
        // Verifica se todos os horários foram removidos
        if (disponibilidade[dia]!.isEmpty) {
          if (idsDias.containsKey(dia)) {
            print('Dia $dia tem horários vazios, removendo do banco...');
            await disponibilidadeService.removerDiaDisponivel(idsDias[dia]!);
            idsDias.remove(dia);
          }
          continue; // Pula para o próximo dia
        }

        if (isEditing && idsDias.containsKey(dia)) {
          // Se estamos editando e já temos um ID para este dia, atualizamos
          print('Atualizando dia: $dia com ID: ${idsDias[dia]}');
          await disponibilidadeService.editarDisponibilidade(
              idsDias[dia]!,
              disponibilidade[dia]!.toList()
          );
        } else {
          // Se é um novo dia, inserimos
          print('Inserindo novo dia: $dia');
          final idDisponibilidade = await disponibilidadeService.definirDisponibilidade(user.id, dia);
          idsDias[dia] = idDisponibilidade; // Armazena o novo ID

          // Se houver horários selecionados para este dia, insere-os
          if (disponibilidade[dia]!.isNotEmpty) {
            print('Inserindo ${disponibilidade[dia]!.length} horários para $dia');
            await disponibilidadeService.adicionarHorarios(
                idDisponibilidade,
                disponibilidade[dia]!.toList()
            );
          }
        }
      }

      // Fechar o dialog de loading
      Navigator.pop(context);

      // Mostrar animação de sucesso
      _mostrarAnimacaoSucesso();

      // Navegar após um atraso para permitir que a animação seja vista
      Future.delayed(const Duration(milliseconds: 1500), () {
        GoRouter.of(context).go(Routes.homePage);
      });

    } catch (e) {
      // Fechar o dialog de loading
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Erro ao salvar disponibilidade: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _mostrarAnimacaoSucesso() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 80,
              ).animate()
                  .scale(duration: 500.ms, curve: Curves.easeOut)
                  .fade(duration: 500.ms),
              const SizedBox(height: 20),
              Text(
                "Disponibilidade salva com sucesso!",
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ).animate().fade(delay: 300.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }

  String _formatarHorario(int horario) {
    String horarioStr = horario.toString().padLeft(4, '0');
    return '${horarioStr.substring(0, 2)}:${horarioStr.substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child:ToolLoadingIndicator(color: Colors.blue, size: 45))
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade100, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header personalizado com design moderno
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.blue),
                      onPressed: () {
                        GoRouter.of(context).go(Routes.profilePage);
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'Defina sua disponibilidade',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.help_outline, color: Colors.blue),
                      onPressed: () {
                        // Mostrar dica de ajuda
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Como funciona?'),
                            content: const Text(
                                'Selecione os dias da semana em que você está disponível e em seguida escolha os horários específicos para cada dia selecionado.'
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Entendi'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Calendário Semanal animado
              Container(
                height: 120,
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: diasSemana.length,
                  itemBuilder: (context, index) {
                    final dia = diasSemana[index];
                    final bool selecionado = disponibilidade.containsKey(dia);

                    return GestureDetector(
                      onTap: () => toggleDia(dia),
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.symmetric(horizontal: 8.0),
                        decoration: BoxDecoration(
                          color: selecionado ? Colors.blue : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              diasIcons[dia] ?? Icons.calendar_today,
                              color: selecionado ? Colors.white : Colors.blue,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dia.split('-')[0], // Pega apenas "Segunda", "Terça", etc.
                              style: TextStyle(
                                color: selecionado ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (selecionado)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ).animate()
                          .scale(
                        duration: 200.ms,
                        curve: Curves.easeInOut,
                        begin: const Offset(0.95, 0.95),
                        end: const Offset(1.0, 1.0),
                      )
                          .animate(target: selecionado ? 1 : 0)
                          .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.3))
                      ,
                    );
                  },
                ),
              ),

              // Subtítulo
              if (disponibilidade.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Selecione os horários para cada dia:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),

              // Se nenhum dia selecionado, mostrar mensagem
              if (disponibilidade.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Selecione os dias em que você\nestá disponível',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Conteúdo dos dias com TabBarView para navegação
              if (disponibilidade.isNotEmpty)
                Expanded(
                  child: Column(
                    children: [
                      // Tabs para os dias selecionados - verificando se temos dias antes de mostrar
                      if (diasSelecionados.isNotEmpty)
                        TabBar(
                          controller: _tabController,
                          tabs: diasSelecionados.map((dia) {
                            return Tab(
                              text: dia.split('-')[0],
                              icon: Icon(diasIcons[dia] ?? Icons.calendar_today),
                            );
                          }).toList(),
                          isScrollable: true,
                          indicatorColor: Colors.blue,
                          labelColor: Colors.blue,
                          unselectedLabelColor: Colors.grey,
                        ),

                      // Conteúdo das tabs - verificando se temos dias antes de mostrar
                      if (diasSelecionados.isNotEmpty)
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: diasSelecionados.map((dia) {
                              return SingleChildScrollView(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Grid de horários
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        childAspectRatio: 2.5,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                      ),
                                      itemCount: horarios.length,
                                      itemBuilder: (context, index) {
                                        final horario = horarios[index];
                                        final bool selecionado = disponibilidade[dia]!.contains(horario);

                                        return GestureDetector(
                                          onTap: () => toggleHorario(dia, horario),
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 300),
                                            decoration: BoxDecoration(
                                              color: selecionado
                                                  ? Colors.green
                                                  : Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.1),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            alignment: Alignment.center,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  color: selecionado ? Colors.white : Colors.grey,
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatarHorario(horario),
                                                  style: TextStyle(
                                                    color: selecionado ? Colors.white : Colors.black87,
                                                    fontWeight: selecionado ? FontWeight.bold : FontWeight.normal,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ).animate(target: selecionado ? 1 : 0)
                                              .scaleXY(end: 1.05, duration: 200.ms)
                                              .then()
                                              .scaleXY(end: 1.0, duration: 200.ms),
                                        );
                                      },
                                    ),

                                    // Imagem ilustrativa
                                    Padding(
                                      padding: const EdgeInsets.only(top: 24),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              size: 64,
                                              color: Colors.blue.withOpacity(0.5),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Horários selecionados: ${disponibilidade[dia]!.length}',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),

              // Botão para salvar a disponibilidade
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: salvarDisponibilidade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                  ),
                  child: Container(
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save),
                        const SizedBox(width: 8),
                        Text(
                          isEditing ? "Salvar Alterações" : "Salvar Disponibilidade",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOut),
              ),
            ],
          ),
        ),
      ),
    );
  }
}