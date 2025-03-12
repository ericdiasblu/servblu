import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servblu/widgets/build_button.dart';
import 'package:servblu/widgets/input_field.dart';
import 'package:servblu/router/router.dart';
import 'package:servblu/router/routes.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> resetPassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, preencha todos os campos.")),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("As senhas não coincidem.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Atualiza a senha usando o Supabase
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Senha atualizada com sucesso!"),
            backgroundColor: Colors.green,
          ),
        );

        // Redireciona para a tela de login
        setLoggedIn(false);
        GoRouter.of(context).go(Routes.enterPage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao redefinir a senha: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Redefinir Senha"),
        backgroundColor: const Color(0xFFF5F5F5),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 37),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            const Text(
              "Nova senha",
              style: TextStyle(
                color: Color(0xFF000000),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            const Text(
              "Crie uma nova senha para sua conta",
              style: TextStyle(
                color: Color(0xFF000000),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            InputField(
              obscureText: true,
              icon: Icons.lock,
              hintText: "Nova senha",
              controller: _passwordController,
            ),
            InputField(
              obscureText: true,
              icon: Icons.lock_outline,
              hintText: "Confirmar nova senha",
              controller: _confirmPasswordController,
            ),

            const SizedBox(height: 30),

            _isLoading
                ? const CircularProgressIndicator(
              color: Color(0xFF017DFE),
            )
                : BuildButton(
              textButton: "Redefinir senha",
              onPressed: resetPassword,
            ),

            const SizedBox(height: 40),

            // Imagem ilustrativa para a página
            Image.asset(
              'assets/reset_password.png',
              height: 250,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}