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

  /// Atualiza o status do agendamento.
  Future<void> atualizarStatusAgendamento(
      String idAgendamento, String novoStatus, {String? motivoRecusa}) async {
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

      // Preparar dados para atualização
      Map<String, dynamic> dadosAtualizacao = {'status': novoStatus};

      // Se o status for recusado e houver motivo, incluir o motivo na atualização
      if (novoStatus == 'recusado' && motivoRecusa != null && motivoRecusa.trim().isNotEmpty) {
        dadosAtualizacao['motivo_recusa'] = motivoRecusa;
      }

      // Atualizar o agendamento
      await supabase
          .from('agendamentos')
          .update(dadosAtualizacao)
          .eq('id_agendamento', idAgendamento);
    } catch (e) {
      throw Exception('Erro ao atualizar status: $e');
    }
  }

  /// Verifica se o horário já foi agendado para o prestador em determinada data.
  Future<bool> verificarDisponibilidade(
      String idPrestador, String dataServico, dynamic idHorario) async {
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
            servicos:id_servico (nome)
          ''').eq('id_agendamento', idAgendamento).limit(1);

      if (response.isEmpty) {
        throw Exception('Agendamento não encontrado');
      }

      final json = response.first;
      final agendamento = Agendamento.fromJson(json);

      if (json['servicos'] != null) {
        agendamento.nomeServico = json['servicos']['nome'];
      }

      // Buscar nomes de prestador e cliente
      try {
        final prestadorResponse = await supabase
            .from('usuarios')
            .select('nome')
            .eq('id_usuario', agendamento.idPrestador)
            .single();
        agendamento.nomePrestador = prestadorResponse['nome'];
      } catch (e) {
        print('Erro ao buscar nome do prestador: $e');
      }

      try {
        final clienteResponse = await supabase
            .from('usuarios')
            .select('nome')
            .eq('id_usuario', agendamento.idCliente)
            .single();
        agendamento.nomeCliente = clienteResponse['nome'];
      } catch (e) {
        print('Erro ao buscar nome do cliente: $e');
      }

      return agendamento;
    } catch (e) {
      throw Exception('Erro ao obter detalhes do agendamento: $e');
    }
  }

  // Adicione esta função ao AgendamentoService para buscar detalhes do prestador
  Future<Map<String, dynamic>> obterDetalhesPrestador(String idPrestador) async {
    try {
      final response = await supabase
          .from('usuarios')
          .select('nome, telefone')
          .eq('id_usuario', idPrestador)
          .single();

      return response;
    } catch (e) {
      print('Erro ao buscar detalhes do prestador: $e');
      throw Exception('Erro ao buscar informações do prestador: $e');
    }
  }

  // Listar agendamentos onde o usuário é o prestador
  Future<List<Agendamento>> listarAgendamentosPorPrestador(
      String idPrestador) async {
    try {
      // Consulta para buscar agendamentos onde o usuário é o prestador
      final response = await supabase.from('agendamentos').select('''
            *,
            servicos:id_servico (nome, preco)
          ''').eq('id_prestador', idPrestador);

      // Mapear os resultados para objetos Agendamento
      final List<Agendamento> agendamentos = [];
      for (final item in response) {
        final agendamento = Agendamento.fromJson(item);

        // Adicionar informações adicionais do serviço
        if (item['servicos'] != null) {
          agendamento.nomeServico = item['servicos']['nome'];
          // Atribuir o preço do serviço
          if (item['servicos']['preco'] != null) {
            agendamento.precoServico = double.parse(item['servicos']['preco'].toString());
          }
        }

        try {
          // Buscar nome do cliente
          final clienteResponse = await supabase
              .from('usuarios')
              .select('nome')
              .eq('id_usuario', agendamento.idCliente)
              .single();
          agendamento.nomeCliente = clienteResponse['nome'];
        } catch (e) {
          print('Erro ao buscar nome do cliente: $e');
        }

        agendamentos.add(agendamento);
      }

      return agendamentos;
    } catch (e) {
      print('Erro ao listar agendamentos do prestador: $e');
      throw Exception('Erro ao listar agendamentos do prestador: $e');
    }
  }

  // Listar agendamentos onde o usuário é o cliente
  Future<List<Agendamento>> listarAgendamentosPorCliente(
      String idCliente) async {
    try {
      // Consulta para buscar agendamentos onde o usuário é o cliente
      final response = await supabase.from('agendamentos').select('''
            *,
            servicos:id_servico (nome, preco)
          ''').eq('id_cliente', idCliente);

      // Mapear os resultados para objetos Agendamento
      final List<Agendamento> agendamentos = [];
      for (final item in response) {
        final agendamento = Agendamento.fromJson(item);

        // Adicionar informações adicionais do serviço
        if (item['servicos'] != null) {
          agendamento.nomeServico = item['servicos']['nome'];
          // Atribuir o preço do serviço
          if (item['servicos']['preco'] != null) {
            agendamento.precoServico = double.parse(item['servicos']['preco'].toString());
          }
        }

        try {
          // Buscar nome do prestador
          final prestadorResponse = await supabase
              .from('usuarios')
              .select('nome')
              .eq('id_usuario', agendamento.idPrestador)
              .single();
          agendamento.nomePrestador = prestadorResponse['nome'];
        } catch (e) {
          print('Erro ao buscar nome do prestador: $e');
        }

        agendamentos.add(agendamento);
      }

      return agendamentos;
    } catch (e) {
      print('Erro ao listar agendamentos do cliente: $e');
      throw Exception('Erro ao listar agendamentos do cliente: $e');
    }
  }

  // Buscar detalhes de um agendamento específico
  Future<Agendamento> buscarAgendamento(String idAgendamento) async {
    try {
      final response = await supabase
          .from('agendamentos')
          .select('*, servicos:id_servico (nome)')
          .eq('id_agendamento', idAgendamento)
          .single();

      final agendamento = Agendamento.fromJson(response);

      // Adicionar informações adicionais do serviço
      if (response['servicos'] != null) {
        agendamento.nomeServico = response['servicos']['nome'];
      }

      try {
        // Buscar nome do prestador
        final prestadorResponse = await supabase
            .from('usuarios')
            .select('nome')
            .eq('id_usuario', agendamento.idPrestador)
            .single();
        agendamento.nomePrestador = prestadorResponse['nome'];
      } catch (e) {
        print('Erro ao buscar nome do prestador: $e');
      }

      try {
        // Buscar nome do cliente
        final clienteResponse = await supabase
            .from('usuarios')
            .select('nome')
            .eq('id_usuario', agendamento.idCliente)
            .single();
        agendamento.nomeCliente = clienteResponse['nome'];
      } catch (e) {
        print('Erro ao buscar nome do cliente: $e');
      }

      return agendamento;
    } catch (e) {
      print('Erro ao buscar detalhes do agendamento: $e');
      throw Exception('Erro ao buscar detalhes do agendamento: $e');
    }
  }

  Future<void> removerAgendamento(String idAgendamento) async {
    try {
      await supabase.from('agendamentos').delete().eq('id_agendamento', idAgendamento);
      return; // Success
    } catch (e) {
      print('Erro ao remover agendamento: $e');
      throw Exception('Erro ao remover agendamento: $e');
    }
  }
}