import 'package:flutter/material.dart';
import 'package:servblu/screens/login_signup/enter_screen.dart';
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
  final _resetTokenController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> resetPassword() async {
    final resetToken = _resetTokenController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (resetToken.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
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
      // Verifica o token de recuperação (OTP) para autenticar o usuário temporariamente
      final recovery = await Supabase.instance.client.auth.verifyOTP(
        email: email,
        token: resetToken,
        type: OtpType.recovery,
      );
      print(recovery);

      // Atualiza a senha do usuário
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
        Navigator.push(context, MaterialPageRoute(builder: (context) => EnterScreen()));
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
    _resetTokenController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              "Redefinir Senha",
              style: TextStyle(
                color: Color(0xFF000000),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            const Text(
              "Informe o token recebido, seu email e crie uma nova senha",
              style: TextStyle(
                color: Color(0xFF000000),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Campo para informar o token de recuperação
            InputField(
              obscureText: false,
              icon: Icons.token,
              hintText: "Token de recuperação",
              controller: _resetTokenController,
            ),
            const SizedBox(height: 20),

            // Campo para informar o email
            InputField(
              obscureText: false,
              icon: Icons.email,
              hintText: "Email",
              controller: _emailController,
            ),
            const SizedBox(height: 20),

            // Campo para nova senha
            InputField(
              obscureText: true,
              icon: Icons.lock,
              hintText: "Nova senha",
              controller: _passwordController,
            ),
            const SizedBox(height: 20),

            // Campo para confirmar nova senha
            InputField(
              obscureText: true,
              icon: Icons.lock_outline,
              hintText: "Confirmar nova senha",
              controller: _confirmPasswordController,
            ),
            const SizedBox(height: 30),

            _isLoading
                ? const CircularProgressIndicator(color: Color(0xFF017DFE))
                : BuildButton(
              textButton: "Redefinir senha",
              onPressed: resetPassword,
            ),
          ],
        ),
      ),
    );
  }
}
