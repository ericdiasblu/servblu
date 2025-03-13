import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servblu/models/servicos/servico.dart';
import 'package:uuid/uuid.dart';

class ServicoService {
  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();

  Future<List<Servico>> listarServicos({String? categoria}) async {
    var query = supabase.from('servicos').select();

    if (categoria != null && categoria.isNotEmpty) {
      query = query.filter('categoria', 'eq', categoria);
    }

    final response = await query.order('nome', ascending: true);

    if (response is! List) {
      throw Exception('Erro ao buscar serviços');
    }

    return response.map((json) => Servico.fromJson(json)).toList();
  }

  Future<void> cadastrarServico(Servico servico) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não está logado');
    }

    // Gerar UUID para o novo serviço
    final String novoId = _uuid.v4();

    final servicoComPrestador = Servico(
      idServico: novoId,
      nome: servico.nome,
      descricao: servico.descricao,
      categoria: servico.categoria,
      imgServico: servico.imgServico,
      preco: servico.preco,
      idPrestador: user.id, // UUID do usuário logado
    );

    try {
      await supabase.from('servicos').upsert(servicoComPrestador.toJson());
      // Se não lançar exceção, consideramos que foi bem-sucedido
      return;
    } catch (e) {
      print('Erro real do Supabase: $e');
      throw Exception('Erro ao cadastrar serviço');
    }
  }

  Future<void> editarServico(Servico servico) async {
    if (servico.idServico == null) {
      throw Exception('ID do serviço não pode ser nulo para edição');
    }

    final response = await supabase.from('servicos').upsert(servico.toJson());

    if (response == null) {
      throw Exception('Erro ao editar serviço');
    }
  }

  Future<void> removerServico(String idServico) async {
    final response = await supabase
        .from('servicos')
        .delete()
        .eq('id_servico', idServico);

    if (response == null) {
      return; // Retorna sem valor
    } else {
      throw Exception('Erro ao remover serviço');
    }
  }

  Future<List<Servico>> obterServicosPorPrestador(String idPrestador) async {
    final data = await supabase
        .from('servicos')
        .select()
        .eq('id_prestador', idPrestador);

    if (data is! List) {
      throw Exception('Erro ao buscar serviços do prestador');
    }

    return data.map((json) => Servico.fromJson(json)).toList();
  }
}