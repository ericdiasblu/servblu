import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servblu/router/routes.dart';
import 'package:servblu/widgets/build_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servblu/services/disponibilidade_service.dart';
import 'package:servblu/models/servicos/disponibilidade.dart';

class DisponibilidadeScreen extends StatefulWidget {
  const DisponibilidadeScreen({super.key});

  @override
  _DisponibilidadeScreenState createState() => _DisponibilidadeScreenState();
}

class _DisponibilidadeScreenState extends State<DisponibilidadeScreen> {
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

  // Horários disponíveis para seleção (ex.: 900 = 09:00, 1300 = 13:00, etc.)
  final List<int> horarios = [900, 1000, 1100, 1400, 1500, 1600, 1700, 1800];

  @override
  void initState() {
    super.initState();
    _carregarDisponibilidade();
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
        // Não removemos o ID aqui, apenas na hora de salvar
      } else {
        print('Adicionando dia: $dia');
        disponibilidade[dia] = <int>{};
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Disponibilidade salva com sucesso!")),
      );
      // Retorna para a home ou outra rota, se desejado:
      GoRouter.of(context).go(Routes.homePage);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao salvar disponibilidade: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // BuildHeader já inclui a seta de voltar
          const BuildHeader(
            title: 'Disponibilidade',
            backPage: true,

          ),
          // Seletor de Dias da Semana
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 8,
              children: diasSemana.map((dia) {
                final bool selecionado = disponibilidade.containsKey(dia);
                return ChoiceChip(
                  label: Text(dia),
                  selected: selecionado,
                  onSelected: (_) => toggleDia(dia),
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: selecionado ? Colors.white : Colors.black,
                  ),
                );
              }).toList(),
            ),
          ),
          // Para cada dia selecionado, mostra os horários disponíveis
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: disponibilidade.keys.map((dia) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Horários para $dia:',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Wrap(
                      spacing: 8,
                      children: horarios.map((horario) {
                        final bool selecionado = disponibilidade[dia]!.contains(horario);
                        return ChoiceChip(
                          label: Text(
                              '${horario.toString().padLeft(4, '0').substring(0, 2)}:${horario.toString().padLeft(4, '0').substring(2)}'
                          ),
                          selected: selecionado,
                          onSelected: (_) => toggleHorario(dia, horario),
                          selectedColor: Colors.green,
                          labelStyle: TextStyle(
                            color: selecionado ? Colors.white : Colors.black,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ),
          ),
          // Botão para salvar a disponibilidade
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: salvarDisponibilidade,
              child: Text(isEditing ? "Salvar Alterações" : "Salvar Disponibilidade"),
            ),
          ),
        ],
      ),
    );
  }
}