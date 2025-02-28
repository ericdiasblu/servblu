import 'package:flutter/material.dart';
import 'package:servblu/models/notificacao/notificacao.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:servblu/router/router.dart'; // Importa o router atualizado
import 'firebase_options.dart';
import 'services/notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase
  FirebaseApp? app;
  try {
    app = Firebase.app();
    print("Firebase já inicializado, usando a instância existente");
  } catch (e) {
    try {
      app = await Firebase.initializeApp();
      print("Firebase inicializado com sucesso");
    } catch (e) {
      print("Erro ao inicializar Firebase: $e");
    }
  }

  // Inicializa o Supabase
  await Supabase.initialize(
    url: "https://lrwbtpghgmshdtqotsyj.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxyd2J0cGdoZ21zaGR0cW90c3lqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5NTk1OTIsImV4cCI6MjA1NTUzNTU5Mn0.Z53Q-wnvj2ABiASl_FH0tddCdN7dVFqWCeYALruqsC8",
  );

  // Inicializar NotificationService sem reinicializar o Firebase
  if (app != null) {
    try {
      await NotificationService.initializeWithoutFirebase();
      print("Serviço de notificações inicializado");
    } catch (e) {
      print("Erro ao inicializar serviço de notificações: $e");
    }
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLoggedIn, // Observa mudanças no login
      builder: (context, loggedIn, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router, // Usa o GoRouter atualizado
        );
      },
    );
  }
}
