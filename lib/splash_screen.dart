import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servblu/router/routes.dart';
import 'package:servblu/router/router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.65, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.65, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    // Verificar sessão do usuário
    _checkUserSession();
  }

  Future<void> _checkUserSession() async {
    // Aguarda um pouco para mostrar a splash screen
    await Future.delayed(const Duration(milliseconds: 2000));

    // Verifica se o usuário já tem uma sessão ativa
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null && !session.isExpired) {
      // Se tem uma sessão válida, define como logado e vai para home
      setLoggedIn(true);
      if (mounted) {
        context.go(Routes.homePage);
      }
    } else {
      // Se não tem sessão ou está expirada, vai para tela de login
      if (mounted) {
        context.go(Routes.enterPage);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: child,
                );
              },
              child: Text(
                "ServBlu",
                style: TextStyle(
                  color: Color(0xFF017DFE),
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            SizedBox(height: 20),

            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: child,
                );
              },
              child: SizedBox(
                width: 200,
                child: LinearProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF017DFE)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}