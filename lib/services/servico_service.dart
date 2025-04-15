import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servblu/models/servicos/servico.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class ServicoService {
  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();

  Future<String?> uploadImagem(File imagem) async {
    print('=== INICIANDO UPLOAD DE IMAGEM ===');
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        print('Erro: Usuário não está logado');
        throw Exception('Usuário não está logado');
      }
      print('Usuário autenticado: ${user.id}');

      // Verificar se o arquivo realmente existe
      print('Verificando existência do arquivo: ${imagem.path}');
      if (!imagem.existsSync()) {
        print('Erro: Arquivo não existe');
        throw Exception('Arquivo de imagem não existe: ${imagem.path}');
      }

      // Verificar o tamanho do arquivo
      final fileSize = await imagem.length();
      print('Tamanho do arquivo: ${fileSize / 1024} KB');

      if (fileSize > 5 * 1024 * 1024) {  // 5MB limite
        print('Erro: Arquivo muito grande');
        throw Exception('Arquivo muito grande. Limite: 5MB');
      }

      final String fileExtension = path.extension(imagem.path);
      final String fileName = '${_uuid.v4()}$fileExtension';
      print('Nome do arquivo gerado: $fileName');

      // Garantir que o bucket existe
      print('Usando bucket "servicos" para upload...');

      // Tentar fazer o upload
      print('Iniciando upload do arquivo para o bucket...');
      await supabase.storage.from('servicos').upload(
        fileName,
        imagem,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      print('Upload concluído com sucesso');

      // Obter a URL pública
      print('Obtendo URL pública...');
      final String imageUrl = supabase.storage.from('servicos').getPublicUrl(fileName);
      print('URL pública obtida: $imageUrl');
      return imageUrl;
    } catch (e, stackTrace) {
      print('ERRO AO FAZER UPLOAD DA IMAGEM: $e');
      print('Stack trace: $stackTrace');
      print('=== UPLOAD FALHOU ===');
      throw Exception('Erro no upload: $e'); // Throw instead of returning null
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
    print('>>> INICIANDO EDIÇÃO DE SERVIÇO <<<');
    print('Serviço recebido para edição:');
    print('- ID: ${servico.idServico}');
    print('- Nome: ${servico.nome}');
    print('- URL da imagem: ${servico.imgServico}');
    print('- JSON completo: ${servico.toJson()}');

    final String? id = servico.idServico;
    if (id == null) {
      print('Erro: ID do serviço é nulo');
      throw Exception('ID do serviço não pode ser nulo');
    }

    try {
      print('Chamando API Supabase para atualizar serviço...');
      final result = await supabase
          .from('servicos')
          .update(servico.toJson())
          .eq('id_servico', id);

      print('Atualização concluída na API');
      print('Resultado da atualização: $result');

      // Verifique se a atualização foi bem-sucedida
      final updatedService = await supabase
          .from('servicos')
          .select()
          .eq('id_servico', id)
          .single();

      print('Serviço após atualização:');
      print('- ID: ${updatedService['id_servico']}');
      print('- Nome: ${updatedService['nome']}');
      print('- URL da imagem: ${updatedService['img_servico']}');
      print('>>> EDIÇÃO DE SERVIÇO CONCLUÍDA <<<');
    } catch (e) {
      print('ERRO AO EDITAR SERVIÇO: $e');
      print('>>> EDIÇÃO DE SERVIÇO FALHOU <<<');
      throw Exception('Erro ao editar serviço: $e');
    }
  }

  Future<void> removerServico(String idServico) async {
    try {
      await supabase.from('servicos').delete().eq('id_servico', idServico);
      return; // Success
    } catch (e) {
      print('Erro ao remover serviço: $e');
      throw Exception('Erro ao remover serviço: $e');
    }
  }

  Future<List<Servico>> obterServicosPorPrestador(String idPrestador) async {
    final data = await supabase.from('servicos').select().eq('id_prestador', idPrestador);

    if (data is! List) throw Exception('Erro ao buscar serviços do prestador');

    return data.map((json) => Servico.fromJson(json)).toList();
  }

  Future<void> removerImagem(String imageUrl) async {
    try {
      final fileName = imageUrl.split('/').last;
      await supabase.storage.from('servicos').remove([fileName]);
      print('Imagem removida com sucesso: $fileName');
    } catch (e) {
      print('Erro ao remover imagem: $e');
      // Apenas registre o erro, mas não interrompa o fluxo
    }
  }

  // Add this new method to the existing ServicoService class
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final response = await supabase
          .from('usuarios')  // Assuming you have a 'perfis' table for user profiles
          .select()
          .eq('id_usuario', userId)
          .single();

      return response;
    } catch (e) {
      print('Erro ao buscar detalhes do usuário: $e');
      throw Exception('Não foi possível carregar os detalhes do usuário');
    }
  }
}

