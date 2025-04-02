// services/agendamento_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:servblu/models/servicos/agendamento.dart';

class AgendamentoService {
  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();

  /// Registra um novo agendamento, verificando previamente a disponibilidade.
  Future<void> criarAgendamento(Agendamento agendamento) async {
    try {
      // Opcional: Verificar a disponibilidade antes de criar o agendamento.
      await supabase.from('agendamentos').insert(agendamento.toJson());
    } catch (e) {
      throw Exception('Erro ao criar agendamento: $e');
    }
  }

  /// Retorna os agendamentos realizados por um contratante.
  Future<List<Agendamento>> listarAgendamentosPorCliente(String idCliente) async {
    try {
      final List<Map<String, dynamic>> response = await supabase
          .from('agendamentos')
          .select()
          .eq('id_cliente', idCliente)
          .order('data_servico', ascending: true);

      return response
          .map((json) => Agendamento.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao listar agendamentos do cliente: $e');
    }
  }

  /// Retorna os agendamentos recebidos por um prestador.
  Future<List<Agendamento>> listarAgendamentosPorPrestador(String idPrestador) async {
    try {
      final List<Map<String, dynamic>> response = await supabase
          .from('agendamentos')
          .select()
          .eq('id_prestador', idPrestador)
          .order('data_servico', ascending: true);

      return response
          .map((json) => Agendamento.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao listar agendamentos do prestador: $e');
    }
  }

  /// Atualiza o status do agendamento.
  Future<void> atualizarStatusAgendamento(String idAgendamento, String novoStatus) async {
    try {
      final validStatuses = ['pendente', 'aguardando confirmação', 'confirmado', 'concluído', 'cancelado'];
      if (!validStatuses.contains(novoStatus)) {
        throw Exception('Status inválido.');
      }

      await supabase
          .from('agendamentos')
          .update({'status': novoStatus})
          .eq('id_agendamento', idAgendamento);
    } catch (e) {
      throw Exception('Erro ao atualizar status: $e');
    }
  }

  /// Verifica se o horário já foi agendado para o prestador em determinada data.
  Future<bool> verificarDisponibilidade(String idPrestador, String dataServico, String idHorario) async {
    try {
      final List<Map<String, dynamic>> response = await supabase
          .from('agendamentos')
          .select()
          .eq('id_prestador', idPrestador)
          .eq('data_servico', dataServico)
          .eq('horario', idHorario);

      // Se não há agendamento com o mesmo idHorario e data, está disponível.
      return response.isEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar disponibilidade: $e');
    }
  }
}