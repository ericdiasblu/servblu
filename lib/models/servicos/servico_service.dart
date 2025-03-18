import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servblu/models/servicos/servico.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class ServicoService {
  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();

  Future<String?> uploadImagem(File imagem) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Usuário não está logado');

      if (!imagem.existsSync()) throw Exception('Arquivo de imagem não existe: ${imagem.path}');

      final String fileExtension = path.extension(imagem.path);
      final String fileName = '${_uuid.v4()}$fileExtension';

      print('Iniciando upload: $fileName (${(await imagem.length()) / 1024} KB)');

      // Verifica a existência do bucket
      try {
        await supabase.storage.getBucket('servicos');
      } catch (e) {
        print('Bucket "servicos" não encontrado. Tentando criar...');
        await supabase.storage.createBucket('servicos', const BucketOptions(public: true));
      }

      await supabase.storage.from('servicos').upload(
        fileName,
        imagem,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      final String imageUrl = supabase.storage.from('servicos').getPublicUrl(fileName);
      print('Upload concluído: $imageUrl');

      return imageUrl;
    } catch (e, stackTrace) {
      print('Erro ao fazer upload da imagem: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  Future<List<Servico>> listarServicos({String? categoria}) async {
    var query = supabase.from('servicos').select();

    if (categoria != null && categoria.isNotEmpty) {
      query = query.filter('categoria', 'eq', categoria);
    }

    final response = await query.order('nome', ascending: true);

    if (response is! List) throw Exception('Erro ao buscar serviços');

    return response.map((json) => Servico.fromJson(json)).toList();
  }

  Future<void> cadastrarServico(Servico servico) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('Usuário não está logado');

    final servicoComPrestador = servico.copyWith(
      idServico: _uuid.v4(),
      idPrestador: user.id,
    );

    try {
      await supabase.from('servicos').upsert(servicoComPrestador.toJson());
    } catch (e) {
      print('Erro ao cadastrar serviço: $e');
      throw Exception('Erro ao cadastrar serviço');
    }
  }

  Future<void> editarServico(Servico servico) async {
    if (servico.idServico == null) throw Exception('ID do serviço não pode ser nulo');

    try {
      await supabase.from('servicos').upsert(servico.toJson());
    } catch (e) {
      print('Erro ao editar serviço: $e');
      throw Exception('Erro ao editar serviço');
    }
  }

  Future<void> removerServico(String idServico) async {
    final response = await supabase.from('servicos').delete().eq('id_servico', idServico);

    if (response.isEmpty) return;
    throw Exception('Erro ao remover serviço');
  }

  Future<List<Servico>> obterServicosPorPrestador(String idPrestador) async {
    final data = await supabase.from('servicos').select().eq('id_prestador', idPrestador);

    if (data is! List) throw Exception('Erro ao buscar serviços do prestador');

    return data.map((json) => Servico.fromJson(json)).toList();
  }
}
