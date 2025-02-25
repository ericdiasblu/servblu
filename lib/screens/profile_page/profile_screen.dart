import 'package:flutter/material.dart';
import 'package:servblu/auth/auth_service.dart';
import 'package:servblu/models/notificacao/notificacao.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<ProfileScreen> {
  final authService = AuthService();

  void logout() async {
    await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = authService.getCurrentUserEmail();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Test"),
        actions: [IconButton(onPressed: logout, icon: Icon(Icons.logout))],
      ),
      body: Center(
        child: Column(
          children: [
            Text(currentEmail.toString()),
            ElevatedButton(
                onPressed: () {
                  NotiService().showNotification(
                    title: "Title",
                    body: "Body",
                  );
                },
                child: const Text("Enviar Notificação"))
          ],
        ),
      ),
    );
  }
}
