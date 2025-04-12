import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/notificacao/notificacao.dart';

class NotificacaoRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Método para enviar notificação e salvar no banco
  /* Future<Notificacao> enviarNotificacao({
    required String toUserId,
    required String title,
    required String body,
    String tipoNotificacao = 'geral',
    Map? data,
  }) async {
    try {
      // Primeiro, enviar a notificação via cloud function
      final response = await Supabase.instance.client.functions.invoke(
        'send-notification',
        body: {
          'to_user_id': toUserId,
          'title': title,
          'body': body,
          'data': data ?? {},
        },
      );

      if (response.status != 200) {
        throw Exception('Erro ao enviar notificação: ${response.data}');
      }

      // Criar objeto de notificação para salvar no banco
      final notificacao = Notificacao(
        idUsuario: toUserId,
        mensagem: body,
        dataEnvio: DateTime.now(),
        tipoNotificacao: tipoNotificacao,
      );

      // Salvar no banco de dados
      final result = await _supabase
          .from('notificacoes')
          .insert(notificacao.toJson())
          .select()
          .single();

      return Notificacao.fromJson(result);
    } catch (e) {
      print('Erro ao enviar e salvar notificação: $e');
      rethrow;
    }
  }*/

  // Método para listar notificações de um usuário
  Future<List<Notificacao>> listarNotificacoes(String userId) async {
    final res = await _supabase
        .from('notificacoes')
        .select()
        .eq('id_usuario', userId)
        .order('data_envio', ascending: false);
    return (res as List)
        .map((m) => Notificacao.fromMap(m))
        .toList();
  }

  Future<void> saveNotificacao(Notificacao n) async {
    await _supabase.from('notificacoes').insert(n.toMap());
  }

  Future<void> excluirNotificacaoes(int id) async {
    await _supabase
        .from('notificacoes')
        .delete()
        .eq('id', id);
  }

  Future<void> excluirNotificacao(int idNotificacao) async {
    try {
      // Log before deletion attempt
      print('Attempting to delete notification with ID: $idNotificacao');

      // Verify if the notification exists before deletion
      final existingNotification = await _supabase
          .from('notificacoes')
          .select()
          .eq('id', idNotificacao)
          .single();

      print('Existing notification found: $existingNotification');

      // Perform deletion
      final deleteResponse = await _supabase
          .from('notificacoes')
          .delete()
          .eq('id', idNotificacao)
          .select();

      print('Delete response: $deleteResponse');

      // Additional verification
      final checkDelete = await _supabase
          .from('notificacoes')
          .select()
          .eq('id', idNotificacao)
          .maybeSingle();

      print('Check after deletion (should be null): $checkDelete');

    } catch (e, stackTrace) {
      // Comprehensive error logging
      print('Erro ao excluir notificação: $e');
      print('Detalhes do erro: ${e.runtimeType}');
      print('Stacktrace: $stackTrace');

      // If it's a Supabase error, log more details
      if (e is PostgrestException) {
        print('Supabase Error Details:');
        print('Message: ${e.message}');
        print('Details: ${e.details}');
        print('Hint: ${e.hint}');
      }

      rethrow;
    }
  }
}

