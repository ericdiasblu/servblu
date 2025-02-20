import 'package:flutter/material.dart';
import 'package:servblu/models/build_button.dart';
import 'package:servblu/models/input_field.dart';
import 'package:servblu/screens/email_validate_screen.dart';
import 'signup_screen.dart'; // Importe a tela de cadastro

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
              InputField(icon: Icons.email, hintText: "Email"),
              InputField(icon: Icons.lock, hintText: "Senha", margin: EdgeInsets.only(bottom: 0)),

              // Link "Esqueceu sua senha?" à direita
              Row(
                mainAxisAlignment: MainAxisAlignment.end, // Alinha à direita
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => EmailValidateScreen()));
                    },
                    child: const Text(
                      "Esqueceu sua senha?",
                      style: TextStyle(
                        color: Color(0xFF017DFE),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              // Botão de login
              BuildButton(textButton: "Entrar"),

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
                    MaterialPageRoute(builder: (context) => const SignUpScreen()), // Mude para a tela de cadastro
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
              const SizedBox(height: 0), // Remova ou ajuste o SizedBox se necessário
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
