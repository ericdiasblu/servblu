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

  /// Retorna os agendamentos recebidos por um prestador.

  /// Atualiza o status do agendamento.
  Future<void> atualizarStatusAgendamento(
      String idAgendamento, String novoStatus) async {
    try {
      final validStatuses = [
        'solicitado',
        'aguardando',
        'confirmado',
        'concluído',
        'cancelado',
        'recusado'
      ];
      if (!validStatuses.contains(novoStatus)) {
        throw Exception('Status inválido.');
      }

      await supabase
          .from('agendamentos')
          .update({'status': novoStatus}).eq('id_agendamento', idAgendamento);
    } catch (e) {
      throw Exception('Erro ao atualizar status: $e');
    }
  }

  /// Verifica se o horário já foi agendado para o prestador em determinada data.
  Future<bool> verificarDisponibilidade(
      String idPrestador, String dataServico, String idHorario) async {
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

  /// Obtém detalhes de um agendamento específico
  Future<Agendamento> obterDetalhesAgendamento(String idAgendamento) async {
    try {
      final List<Map<String, dynamic>> response =
          await supabase.from('agendamentos').select('''
            *,
            servicos:id_servico (nome),
            prestadores:id_prestador (nome),
            clientes:id_cliente (nome)
          ''').eq('id_agendamento', idAgendamento).limit(1);

      if (response.isEmpty) {
        throw Exception('Agendamento não encontrado');
      }

      final json = response.first;
      final agendamento = Agendamento.fromJson(json);
      agendamento.nomeServico = json['servicos']?['nome'];
      agendamento.nomePrestador = json['prestadores']?['nome'];
      agendamento.nomeCliente = json['clientes']?['nome'];

      return agendamento;
    } catch (e) {
      throw Exception('Erro ao obter detalhes do agendamento: $e');
    }
  }

  // Listar agendamentos onde o usuário é o cliente
  Future<List<Agendamento>> listarAgendamentosPorCliente(
      String idCliente) async {
    try {
      // Consulta para buscar agendamentos onde o usuário é o cliente
      final response = await supabase.from('agendamentos').select('''
            *,
            servicos:id_servico (nome),
            usuarios!id_prestador (nome)
          ''').eq('id_cliente', idCliente);

      // Mapear os resultados para objetos Agendamento
      final List<Agendamento> agendamentos = [];
      for (final item in response) {
        final agendamento = Agendamento.fromJson(item);

        // Adicionar informações adicionais do serviço
        if (item['servicos'] != null) {
          agendamento.nomeServico = item['servicos']['nome'];
        }

        // Adicionar nome do prestador
        if (item['usuarios'] != null) {
          agendamento.nomePrestador = item['usuarios']['nome'];
        }

        agendamentos.add(agendamento);
      }

      return agendamentos;
    } catch (e) {
      print('Erro ao listar agendamentos do cliente: $e');
      throw Exception('Erro ao listar agendamentos do cliente: $e');
    }
  }

  // Listar agendamentos onde o usuário é o prestador
  Future<List<Agendamento>> listarAgendamentosPorPrestador(
      String idPrestador) async {
    try {
      // Consulta para buscar agendamentos onde o usuário é o prestador
      final response = await supabase.from('agendamentos').select('''
            *,
            servicos:id_servico (nome),
            usuarios!id_cliente (nome)
          ''').eq('id_prestador', idPrestador);

      // Mapear os resultados para objetos Agendamento
      final List<Agendamento> agendamentos = [];
      for (final item in response) {
        final agendamento = Agendamento.fromJson(item);

        // Adicionar informações adicionais do serviço
        if (item['servicos'] != null) {
          agendamento.nomeServico = item['servicos']['nome'];
        }

        // Adicionar nome do cliente
        if (item['usuarios'] != null) {
          agendamento.nomeCliente = item['usuarios']['nome'];
        }

        agendamentos.add(agendamento);
      }

      return agendamentos;
    } catch (e) {
      print('Erro ao listar agendamentos do prestador: $e');
      throw Exception('Erro ao listar agendamentos do prestador: $e');
    }
  }

  // Buscar detalhes de um agendamento específico
  Future<Agendamento> buscarAgendamento(String idAgendamento) async {
    try {
      final response = await supabase.from('agendamentos').select('''
            *,
            servicos:id_servico (nome),
            prestador:usuarios!id_prestador (nome),
            cliente:usuarios!id_cliente (nome)
          ''').eq('id_agendamento', idAgendamento).single();

      final agendamento = Agendamento.fromJson(response);

      // Adicionar informações adicionais
      if (response['servicos'] != null) {
        agendamento.nomeServico = response['servicos']['nome'];
      }

      if (response['prestador'] != null) {
        agendamento.nomePrestador = response['prestador']['nome'];
      }

      if (response['cliente'] != null) {
        agendamento.nomeCliente = response['cliente']['nome'];
      }

      return agendamento;
    } catch (e) {
      print('Erro ao buscar detalhes do agendamento: $e');
      throw Exception('Erro ao buscar detalhes do agendamento: $e');
    }
  }
}
