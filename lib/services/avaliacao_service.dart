import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:servblu/models/avaliacoes/avaliacao.dart';

class AvaliacaoService {
  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();

  /// Cria uma nova avaliação para um serviço concluído
  Future<void> criarAvaliacao(Avaliacao avaliacao) async {
    try {
      // Verificar se a nota está dentro do intervalo permitido (1-5)
      if (!Avaliacao.isNotaValida(avaliacao.nota)) {
        throw Exception('A nota deve estar entre 1 e 5');
      }

      // Verificar se o agendamento existe e está concluído
      final agendamentos = await supabase
          .from('agendamentos')
          .select()
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

      // Inserir a avaliação no banco de dados
      await supabase.from('avaliacoes').insert(avaliacao.toJson());
    } catch (e) {
      throw Exception('Erro ao criar avaliação: $e');
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
            final clienteResponse = await supabase
                .from('usuarios')
                .select('nome')
                .eq('id_usuario', item['agendamentos']['id_cliente'])
                .single();
            avaliacao.nomeCliente = clienteResponse['nome'];
          } catch (e) {
            print('Erro ao buscar nome do cliente: $e');
          }
        }

        avaliacoes.add(avaliacao);
      }

      return avaliacoes;
    } catch (e) {
      throw Exception('Erro ao listar avaliações do prestador: $e');
    }
  }

  /// Calcula a média das avaliações de um prestador
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

      // Calcular e retornar a média
      return somaNotas / response.length;
    } catch (e) {
      throw Exception('Erro ao calcular média de avaliações: $e');
    }
  }
}
