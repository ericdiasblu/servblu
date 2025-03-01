import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/notificacao/notificacao.dart';
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
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final supabase = Supabase.instance.client;

                // Tenta renovar a sessão antes de enviar a notificação
                await supabase.auth.refreshSession();
                final userId = supabase.auth.currentUser?.id;
                // Adicione este código antes de chamar sua função
                print("Status de autenticação: ${supabase.auth.currentUser != null}");
                print("Token: ${supabase.auth.currentSession?.accessToken?.substring(0, 15)}...");

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
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Usuário não autenticado!')),
                  );
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
