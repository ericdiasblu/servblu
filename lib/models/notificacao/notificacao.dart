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
  final token = supabase.auth.currentSession?.accessToken;
  if (token == null) {
    throw Exception('Token de acesso não disponível');
  }

  try {
    final response = await supabase.functions.invoke(
      'send-notification',
      body: {
        'to_user_id': toUserId,
        'title': title,
        'body': body,
        'data': data ?? {},
      },
      // Adicionar cabeçalho de autorização explicitamente
      headers: {
        'Authorization': 'Bearer $token',
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
