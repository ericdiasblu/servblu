import 'package:flutter/material.dart';
import 'package:servblu/models/build_button.dart';
import 'package:servblu/models/input_field.dart';
import 'package:servblu/screens/login_screen.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      resizeToAvoidBottomInset: true,
      // Evita o problema de overflow ao abrir o teclado
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 37),
          child: ListView(
            // Permite rolagem automática se necessário
            children: [
              SizedBox(height: screenHeight * 0.1), // Espaço no topo
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
              InputField(icon: Icons.person, hintText: "Nome"),
              InputField(icon: Icons.email, hintText: "Email"),
              InputField(icon: Icons.lock, hintText: "Senha"),
              InputField(icon: Icons.phone, hintText: "Telefone"),

              const SizedBox(height: 20),

              // Botão de inscrição
              BuildButton(textButton: "Inscrever-se"),

              const SizedBox(height: 40),

              // Linha divisória
              Row(
                children: [
                  const Expanded(
                      child: Divider(color: Colors.black, thickness: 1)),
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
                  const Expanded(
                      child: Divider(color: Colors.black, thickness: 1)),
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

              SizedBox(height: screenHeight * 0.05), // Espaço no final
            ],
          ),
        ),
      ),
    );
  }
}
