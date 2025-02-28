import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/notification_method.dart';
import '../../services/notification_service.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Notificações Push')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                NotificationService.subscribeToTopic('novidades');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Inscrito em novidades')),
                );
              },
              child: Text('Inscrever em Novidades'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final supabase = Supabase.instance.client;
                final userId = supabase.auth.currentUser?.id;

                if (userId != null) {
                  try {
                    await sendNotification(
                      toUserId: userId, // Enviando para o próprio usuário como teste
                      title: 'Teste de Notificação',
                      body: 'Esta é uma notificação de teste!',
                      data: {'type': 'test', 'redirectTo': 'home'},
                    );

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Notificação enviada!')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                }
              },
              child: Text('Enviar Notificação de Teste'),
            ),
          ],
        ),
      ),
    );
  }
}