import 'package:flutter/material.dart';
import 'package:servblu/auth/auth_service.dart';
import 'package:servblu/models/build_button.dart';
import 'package:servblu/models/input_field.dart';
import 'package:servblu/screens/login_signup/email_validate_screen.dart';
import '../home_page/home_struture.dart';
import 'signup_screen.dart';


class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void login(BuildContext context) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, preencha todos os campos.")),
      );
      return;
    }

    try {
      await authService.signInWithEmailPassword(email, password);
      // Navegue para a tela principal ou outra tela após o login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()), // Tela principal
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erro ao fazer login: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 37),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            const Text(
              "Bem vindo de volta!",
              style: TextStyle(
                color: Color(0xFF000000),
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const Text(
              "Entre na sua conta",
              style: TextStyle(
                color: Color(0xFF000000),
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Campos de entrada
            InputField(
              obscureText: false,
              icon: Icons.email,
              hintText: "Email",
              controller: _emailController,
            ),
            InputField(
              obscureText: true,
              icon: Icons.lock,
              hintText: "Senha",
              controller: _passwordController,
            ),

            // Link "Esqueceu sua senha?" à direita
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmailValidateScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Esqueceu sua senha?",
                  style: TextStyle(
                    color: Color(0xFF017DFE),
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            // Botão de login
            BuildButton(
              textButton: "Entrar",
              onPressed: () => login(context),
            ),

            const SizedBox(height: 40),

            // Linha divisória
            Row(
              children: [
                const Expanded(child: Divider(color: Colors.black, thickness: 1)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "Entre com",
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 13,
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Colors.black, thickness: 1)),
              ],
            ),

            const SizedBox(height: 20),

            // Ícone do Google
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Center(
                child: Image(
                  image: AssetImage('assets/google_icon.png'),
                  width: 24,
                  height: 24,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Link para cadastro
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SignUpScreen(),
                  ),
                );
              },
              child: const Center(
                child: Text(
                  "Não possui uma conta? Cadastra-se",
                  style: TextStyle(
                    color: Color(0xFF000000),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Imagem
            const SizedBox(height: 0),
            Image(
              image: AssetImage('assets/login.png'),
              height: 330,
            ),
          ],
        ),
      ),
    );
  }
}
