import 'package:flutter/material.dart';
import 'package:servblu/models/build_button.dart';
import 'package:servblu/models/input_field.dart';
import 'package:servblu/screens/login_signup/login_screen.dart';
import '../../auth/auth_service.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    final authService = AuthService();

    // Controllers
    final _nameController = TextEditingController(); // Controlador para o nome
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    final _phoneController = TextEditingController(); // Controlador para o telefone

    // Botão de cadastro
    void signUp() async {
      final name = _nameController.text;
      final email = _emailController.text;
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;
      final phone = _phoneController.text;

      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("As senhas não coincidem")));
        return;
      }

      try {
        // Cadastro do usuário
        final response = await authService.signUpWithEmailPassword(email, password);

        // Verifica se o cadastro foi bem-sucedido
        if (response.user != null) {
          // Atualiza os detalhes do usuário
          await authService.updateUserDetails(name, phone);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Cadastro realizado com sucesso!")));

          // Volta para a tela de login após o cadastro
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Falha ao cadastrar usuário.")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: ${e.toString()}")));
      }
    }


    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 37),
          child: ListView(
            children: [
              SizedBox(height: screenHeight * 0.1),
              const Text(
                "Criar uma conta",
                style: TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const Text(
                "Inscreva-se para começar",
                style: TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Campos de entrada
              InputField(icon: Icons.person, hintText: "Nome", controller: _nameController),
              InputField(icon: Icons.email, hintText: "Email", controller: _emailController),
              InputField(icon: Icons.lock, hintText: "Senha", controller: _passwordController),
              InputField(icon: Icons.lock, hintText: "Confirmar senha", controller: _confirmPasswordController),
              InputField(icon: Icons.phone, hintText: "Telefone", controller: _phoneController),

              const SizedBox(height: 20),

              // Botão de inscrição
              BuildButton(textButton: "Inscrever-se", onPressed: signUp),

              const SizedBox(height: 40),

              // Linha divisória
              Row(
                children: [
                  const Expanded(child: Divider(color: Colors.black, thickness: 1)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "Cadastre-se com",
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

              const SizedBox(height: 70),

              // Link para login
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LoginScreen(),
                    ),
                  );
                },
                child: const Center(
                  child: Text(
                    "Já possui uma conta? Entrar",
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
