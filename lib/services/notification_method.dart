import 'package:supabase_flutter/supabase_flutter.dart';

Future sendNotification({
  required String toUserId,
  required String title,
  required String body,
  Map? data,
}) async {
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase.functions.invoke(
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

    print('Notificação enviada com sucesso: ${response.data}');
  } catch (e) {
    print('Erro ao enviar notificação: $e');
    rethrow;
  }
}