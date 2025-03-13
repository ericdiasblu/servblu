import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:servblu/router/router.dart';
import 'package:servblu/auth/auth_service.dart';
import 'firebase_options.dart';
import 'services/notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase inicializado com sucesso");
    }
  } catch (e) {
    print("Erro ao inicializar Firebase: $e");
  }

  // Inicializa o Supabase
  await Supabase.initialize(
    url: "https://lrwbtpghgmshdtqotsyj.supabase.co",
    anonKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxyd2J0cGdoZ21zaGR0cW90c3lqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzk5NTk1OTIsImV4cCI6MjA1NTUzNTU5Mn0.Z53Q-wnvj2ABiASl_FH0tddCdN7dVFqWCeYALruqsC8",
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      detectSessionInUri: true,
    ),
  );


  // Inicializar o estado de autenticação
  final authService = AuthService();
  authService.initAuthState();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isLoggedIn,
      builder: (context, loggedIn, child) {
        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
        );
      },
    );
  }
}