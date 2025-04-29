import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:servblu/models/avaliacoes/avaliacao.dart';

class AvaliacaoService {
  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();

  /// Cria uma nova avaliação para um serviço concluído e atualiza a média no serviço
  Future<void> criarAvaliacao(Avaliacao avaliacao) async {
    try {
      // Verificar se a nota está dentro do intervalo permitido (1-5)
      if (!Avaliacao.isNotaValida(avaliacao.nota)) {
        throw Exception('A nota deve estar entre 1 e 5');
      }

      // Verificar se o agendamento existe e está concluído
      final agendamentos = await supabase
          .from('agendamentos')
          .select('*, servicos:id_servico (id_prestador, id_servico)')
          .eq('id_agendamento', avaliacao.idAgendamento)
          .eq('status', 'concluído');

      if (agendamentos.isEmpty) {
        throw Exception('O agendamento não existe ou não está concluído');
      }

      // Verificar se o agendamento já foi avaliado
      final avaliacaoExistente = await supabase
          .from('avaliacoes')
          .select()
          .eq('id_agendamento', avaliacao.idAgendamento);

      if (avaliacaoExistente.isNotEmpty) {
        throw Exception('Este serviço já foi avaliado');
      }

      // Obter o ID do serviço do agendamento
      final idServico = agendamentos[0]['servicos']['id_servico'];

      // Obter o ID do cliente para buscar nome do cliente
      final idCliente = agendamentos[0]['id_cliente'];
      final clienteInfo = await supabase
          .from('usuarios')
          .select('nome, foto_perfil')
          .eq('id_usuario', idCliente)
          .single();

      final nomeCliente = clienteInfo['nome'];
      final fotoPerfilCliente = clienteInfo['foto_perfil'];

      // Criar objeto de avaliação completo
      final avaliacaoCompleta = Avaliacao(
        idAvaliacao: avaliacao.idAvaliacao,
        idAgendamento: avaliacao.idAgendamento,
        idServico: idServico, // Agora armazenamos o ID do serviço
        nota: avaliacao.nota,
        comentario: avaliacao.comentario,
        dataAvaliacao: avaliacao.dataAvaliacao,
        nomeCliente: nomeCliente, // Armazenamos o nome do cliente
        fotoPerfilCliente: fotoPerfilCliente,
      );

      // Inserir a avaliação no banco de dados
      await supabase.from('avaliacoes').insert(avaliacaoCompleta.toJson());

      // Obter o ID do prestador para atualizar sua média de avaliações
      final idPrestador = agendamentos[0]['servicos']['id_prestador'];

      // Atualizar a média de avaliações no serviço específico
      await _atualizarMediaAvaliacoesServico(idServico);

      // Atualizar a média geral em todos os serviços do prestador
      if (idPrestador != null) {
        await _atualizarMediaAvaliacoes(idPrestador);
      }
    } catch (e) {
      throw Exception('Erro ao criar avaliação: $e');
    }
  }

  /// Atualiza a média de avaliações de um serviço específico
  Future<void> _atualizarMediaAvaliacoesServico(String idServico) async {
    try {
      // Calcular a média das avaliações para este serviço específico
      final media = await calcularMediaAvaliacoesServico(idServico);

      // Atualizar a média apenas neste serviço
      await supabase
          .from('servicos')
          .update({'avaliacao_media': media})
          .eq('id_servico', idServico);

    } catch (e) {
      print('Erro ao atualizar média de avaliações do serviço: $e');
    }
  }

  /// Atualiza média de avaliações do prestador
  Future<void> _atualizarMediaAvaliacoes(String idPrestador) async {
    try {
      // Calcular a média das avaliações
      final media = await calcularMediaAvaliacoesPrestador(idPrestador);

      // Atualizar a média do prestador
      await supabase
          .from('usuarios')
          .update({'avaliacao_usuarios': media})
          .eq('id_usuario', idPrestador);

    } catch (e) {
      print('Erro ao atualizar média de avaliações: $e');
    }
  }

  /// Obtém a avaliação de um agendamento específico
  Future<Avaliacao?> obterAvaliacaoPorAgendamento(String idAgendamento) async {
    try {
      final List<Map<String, dynamic>> response = await supabase
          .from('avaliacoes')
          .select()
          .eq('id_agendamento', idAgendamento);

      if (response.isEmpty) {
        return null; // Nenhuma avaliação encontrada
      }

      return Avaliacao.fromJson(response.first);
    } catch (e) {
      throw Exception('Erro ao obter avaliação: $e');
    }
  }

  /// Verifica se um agendamento já foi avaliado
  Future<bool> verificarAgendamentoAvaliado(String idAgendamento) async {
    try {
      final List<Map<String, dynamic>> response = await supabase
          .from('avaliacoes')
          .select()
          .eq('id_agendamento', idAgendamento);

      return response.isNotEmpty;
    } catch (e) {
      throw Exception('Erro ao verificar avaliação: $e');
    }
  }

  /// Lista avaliações de um serviço específico
  Future<List<Avaliacao>> listarAvaliacoesPorServico(String idServico) async {
    try {
      final response = await supabase
          .from('avaliacoes')
          .select()
          .eq('id_servico', idServico);

      // Mapear os resultados para objetos Avaliacao
      final List<Avaliacao> avaliacoes = [];
      for (final item in response) {
        final avaliacao = Avaliacao.fromJson(item);

        // Se o nome do cliente não estiver na avaliação, tente buscá-lo
        if (avaliacao.nomeCliente == null) {
          try {
            // Buscar o ID do cliente no agendamento
            final agendamentoResponse = await supabase
                .from('agendamentos')
                .select('id_cliente')
                .eq('id_agendamento', avaliacao.idAgendamento)
                .single();

            if (agendamentoResponse != null) {
              final idCliente = agendamentoResponse['id_cliente'];

              // Buscar nome e foto do cliente
              final clienteInfo = await buscarInfoCliente(idCliente);
              avaliacao.nomeCliente = clienteInfo['nome'];
              avaliacao.fotoPerfilCliente = clienteInfo['foto_perfil'];
            }
          } catch (e) {
            print('Erro ao buscar informações adicionais: $e');
          }
        }

        avaliacoes.add(avaliacao);
      }

      return avaliacoes;
    } catch (e) {
      throw Exception('Erro ao listar avaliações do serviço: $e');
    }
  }

  /// Busca informações do cliente (nome e foto de perfil)
  Future<Map<String, dynamic>> buscarInfoCliente(String idCliente) async {
    try {
      final clienteResponse = await supabase
          .from('usuarios')
          .select('nome, foto_perfil')
          .eq('id_usuario', idCliente)
          .single();

      return {
        'nome': clienteResponse['nome'],
        'foto_perfil': clienteResponse['foto_perfil']
      };
    } catch (e) {
      print('Erro ao buscar informações do cliente: $e');
      return {
        'nome': 'Cliente',
        'foto_perfil': null
      };
    }
  }

  /// Lista avaliações recebidas por um prestador
  Future<List<Avaliacao>> listarAvaliacoesPorPrestador(
      String idPrestador) async {
    try {
      // Consulta join entre avaliacoes e agendamentos para pegar as avaliações
      // onde o usuário é o prestador
      final response = await supabase.from('avaliacoes').select('''
            *,
            agendamentos:id_agendamento (id_cliente, id_prestador)
          ''').eq('agendamentos.id_prestador', idPrestador);

      // Mapear os resultados para objetos Avaliacao
      final List<Avaliacao> avaliacoes = [];
      for (final item in response) {
        final avaliacao = Avaliacao.fromJson(item);

        // Buscar informações adicionais se necessário
        if (item['agendamentos'] != null &&
            item['agendamentos']['id_cliente'] != null) {
          try {
            final clienteInfo = await buscarInfoCliente(item['agendamentos']['id_cliente']);
            avaliacao.nomeCliente = clienteInfo['nome'];
            avaliacao.fotoPerfilCliente = clienteInfo['foto_perfil'];
          } catch (e) {
            print('Erro ao buscar informações do cliente: $e');
          }
        }

        avaliacoes.add(avaliacao);
      }

      return avaliacoes;
    } catch (e) {
      throw Exception('Erro ao listar avaliações do prestador: $e');
    }
  }

  /// Calcula a média das avaliações de um serviço específico
  Future<double> calcularMediaAvaliacoesServico(String idServico) async {
    try {
      // Consulta direta nas avaliações usando o id_servico
      final response = await supabase
          .from('avaliacoes')
          .select('nota')
          .eq('id_servico', idServico);

      if (response.isEmpty) {
        return 0.0; // Sem avaliações
      }

      // Somar todas as notas
      double somaNotas = 0;
      for (final item in response) {
        somaNotas +=
        item['nota'] is int ? item['nota'].toDouble() : item['nota'] ?? 0.0;
      }

      // Calcular e retornar a média arredondada para uma casa decimal
      return double.parse((somaNotas / response.length).toStringAsFixed(1));
    } catch (e) {
      throw Exception('Erro ao calcular média de avaliações do serviço: $e');
    }
  }

  /// Calcula a média das avaliações de um prestador
  /// Está calculando média de todos os serviços para todos os prestadores
  Future<double> calcularMediaAvaliacoesPrestador(String idPrestador) async {
    try {
      // Consulta join entre avaliacoes e agendamentos
      final response = await supabase.from('avaliacoes').select('''
            nota,
            agendamentos:id_agendamento (id_prestador)
          ''').eq('agendamentos.id_prestador', idPrestador);

      if (response.isEmpty) {
        return 0.0; // Sem avaliações
      }

      // Somar todas as notas
      double somaNotas = 0;
      for (final item in response) {
        somaNotas +=
        item['nota'] is int ? item['nota'].toDouble() : item['nota'] ?? 0.0;
      }

      // Calcular e retornar a média arredondada para uma casa decimal
      return double.parse((somaNotas / response.length).toStringAsFixed(1));
    } catch (e) {
      throw Exception('Erro ao calcular média de avaliações: $e');
    }
  }

  /// Recupera a quantidade total de avaliações de um prestador
  Future<int> contarAvaliacoesPrestador(String idPrestador) async {
    try {
      final response = await supabase.from('avaliacoes').select('''
        id_avaliacao,
        agendamentos:id_agendamento (id_prestador)
      ''').eq('agendamentos.id_prestador', idPrestador);

      return response.length;
    } catch (e) {
      throw Exception('Erro ao contar avaliações: $e');
    }
  }

  /// Recupera a quantidade total de avaliações de um serviço específico
  Future<int> contarAvaliacoesServico(String idServico) async {
    try {
      final response = await supabase
          .from('avaliacoes')
          .select('id_avaliacao')
          .eq('id_servico', idServico);

      return response.length;
    } catch (e) {
      throw Exception('Erro ao contar avaliações do serviço: $e');
    }
  }
}