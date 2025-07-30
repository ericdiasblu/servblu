import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:servblu/models/servicos/disponibilidade.dart';

class DisponibilidadeService {
  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();

  /// Define a disponibilidade do prestador para um dia específico.
  /// Insere o dia na tabela dias_disponiveis.
  Future<String> definirDisponibilidade(String idPrestador, String dia) async {
    try {
      final response = await supabase.from('dias_disponiveis').insert({
        'id_disponibilidade': _uuid.v4(),
        'id_prestador': idPrestador,
        'dia': dia,
      }).select('id_disponibilidade').single();
      return response['id_disponibilidade'] as String;
    } catch (e) {
      throw Exception('Erro ao definir disponibilidade: $e');
    }
  }

  /// Adiciona horários para um dia já definido.
  Future<void> adicionarHorarios(String idDisponibilidade, List<int> horarios) async {
    try {
      // Prepara os dados para inserção múltipla
      final List<Map<String, dynamic>> inserts = horarios.map((h) {
        return {
          'id_disponibilidade': idDisponibilidade,
          'horario': h,
        };
      }).toList();
      await supabase.from('horarios_disponiveis').insert(inserts);
    } catch (e) {
      throw Exception('Erro ao adicionar horários: $e');
    }
  }

  /// Retorna todos os dias disponíveis com seus respectivos horários para um prestador.
  Future<Map<String, List<HorarioDisponivel>>> obterDisponibilidade(String idPrestador) async {
    try {
      // Busca os dias disponíveis
      final List<Map<String, dynamic>> diasResponse = await supabase
          .from('dias_disponiveis')
          .select()
          .eq('id_prestador', idPrestador);

      Map<String, List<HorarioDisponivel>> disponibilidade = {};

      for (var dia in diasResponse) {
        final String diaSemana = dia['dia'];
        final String idDisp = dia['id_disponibilidade'];

        // Busca os horários vinculados a este dia
        final List<Map<String, dynamic>> horariosResponse = await supabase
            .from('horarios_disponiveis')
            .select()
            .eq('id_disponibilidade', idDisp);

        List<HorarioDisponivel> listaHorarios = horariosResponse
            .map((h) => HorarioDisponivel.fromJson(h))
            .toList();

        disponibilidade[diaSemana] = listaHorarios;
      }

      return disponibilidade;
    } catch (e) {
      throw Exception('Erro ao obter disponibilidade: $e');
    }
  }

  /// Atualiza os horários para um dia específico: remove os horários antigos e insere os novos.
  Future<void> editarDisponibilidade(String idDisponibilidade, List<int> novosHorarios) async {
    try {
      // Remove os horários existentes para este id_disponibilidade
      await supabase
          .from('horarios_disponiveis')
          .delete()
          .eq('id_disponibilidade', idDisponibilidade);

      // Adiciona os novos horários
      await adicionarHorarios(idDisponibilidade, novosHorarios);
    } catch (e) {
      throw Exception('Erro ao editar disponibilidade: $e');
    }
  }

  /// Remove um dia disponível e seus horários.
  Future<void> removerDiaDisponivel(String idDisponibilidade) async {
    try {
      // Primeiro removemos os horários associados
      await supabase
          .from('horarios_disponiveis')
          .delete()
          .eq('id_disponibilidade', idDisponibilidade);

      // Depois removemos o dia
      await supabase
          .from('dias_disponiveis')
          .delete()
          .eq('id_disponibilidade', idDisponibilidade);
    } catch (e) {
      throw Exception('Erro ao remover dia disponível: $e');
    }
  }
}