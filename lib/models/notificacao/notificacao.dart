/*
enviarNotificacao(Notificacao notificacao)
Descrição: Cria e envia uma notificação para um usuário (sobre agendamentos,
pagamentos, feedback, etc.).

listarNotificacoes(int idUsuario)
Descrição: Retorna a lista de notificações associadas a um usuário.

marcarComoLida(int idNotificacao)
Descrição: Atualiza o status da notificação para indicar que ela já foi visualizada.
*/

import 'package:supabase_flutter/supabase_flutter.dart';

Future sendNotification({
  required String toUserId,
  required String title,
  required String body,
  Map? data,
}) async {
  final supabase = Supabase.instance.client;

  // Verificar se o usuário está autenticado
  final currentUser = supabase.auth.currentUser;
  if (currentUser == null) {
    throw Exception('Usuário não está autenticado');
  }

  // Obter o token de acesso da sessão atual
  final session = supabase.auth.currentSession;
  if (session == null || session.accessToken.isEmpty) {
    throw Exception('Token de acesso não disponível');
  }

  try {
    // Verificar se a sessão está válida antes de fazer a requisição
    if (session.expiresAt != null) {
      // Converter o timestamp para DateTime
      final expiresAtDateTime = DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);

      // Verificar se o token expirou
      if (DateTime.now().isAfter(expiresAtDateTime)) {
        // Token expirado, tentar renovar
        print('Token expirado, tentando renovar a sessão...');
        await supabase.auth.refreshSession();

        // Verificar se a renovação foi bem-sucedida
        final newSession = supabase.auth.currentSession;
        if (newSession == null || newSession.accessToken.isEmpty) {
          throw Exception('Não foi possível renovar a sessão');
        }
      }
    }


  final response = await supabase.functions.invoke(
      'send-notification',
      body: {
        'to_user_id': toUserId,
        'title': title,
        'body': body,
        'data': data ?? {},
      },
      // Usar o token atual após potencial renovação
      headers: {
        'Authorization': 'Bearer ${supabase.auth.currentSession!.accessToken}',
      },
    );

    if (response.status != 200) {
      throw Exception('Erro ao enviar notificação: ${response.data}');
    }

    print('Notificação enviada com sucesso: ${response.data}');
    return response.data;
  } catch (e) {
    print('Erro ao enviar notificação: $e');
    rethrow;
  }
}