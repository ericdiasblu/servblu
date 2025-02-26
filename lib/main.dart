import 'package:flutter/material.dart';
import 'package:servblu/models/notificacao/notificacao.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:servblu/router/router.dart'; // Importa o router atualizado
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializa notificações
  NotiService().initNotifications();

  // Inicializa o Supabase
  await Supabase.initialize(
    url: "https://lrwbtpghgmshdtqotsyj.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxyd2J0cGdoZ21zaGR0cW90c3lqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5NTk1OTIsImV4cCI6MjA1NTUzNTU5Mn0.Z53Q-wnvj2ABiASl_FH0tddCdN7dVFqWCeYALruqsC8",
  );

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
