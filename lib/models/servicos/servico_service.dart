import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servblu/models/servicos/servico.dart';
import 'package:uuid/uuid.dart';
import 'dart:io'; // Adicionar esta linha
import 'package:path/path.dart' as path; // Adicionar esta linha

class ServicoService {
  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();

  Future<String?> uploadImagem(File imagem) async {
    try {
      // Verificar se o usuário está autenticado
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não está logado');
      }

      // Verificar se o arquivo existe
      if (!imagem.existsSync()) {
        throw Exception('Arquivo de imagem não existe: ${imagem.path}');
      }

      // Usar apenas o nome do arquivo com extensão
      final String fileExtension = path.extension(imagem.path);
      final String fileName = '${_uuid.v4()}$fileExtension';

      print('Iniciando upload da imagem: $fileName');
      print('Tamanho do arquivo: ${(await imagem.length()) / 1024} KB');

      // Verificar se o bucket 'servicos' existe antes de fazer upload
      try {
        // Tenta obter informações do bucket para verificar se ele existe
        await supabase.storage.getBucket('servicos');
      } catch (e) {
        // Se o bucket não existe, tenta criar
        try {
          await supabase.storage.createBucket('servicos',
              const BucketOptions(public: true));
          print('Bucket servicos criado com sucesso');
        } catch (e) {
          print('Erro ao criar bucket: $e');
          // Continua mesmo se não puder criar
        }
      }

      // Upload da imagem para o Supabase Storage
      await supabase.storage.from('servicos').upload(
        fileName, // Simplifique o caminho
        imagem,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      print('Upload concluído com sucesso para: $fileName');

      // Obter a URL pública da imagem
      final String imageUrl = supabase.storage.from('servicos').getPublicUrl(fileName);
      print('URL pública gerada: $imageUrl');

      return imageUrl;
    } catch (e) {
      print('ERRO DETALHADO ao fazer upload da imagem: $e');
      // Se possível, exibir a stack trace para mais detalhes
      StackTrace? stackTrace = StackTrace.current;
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