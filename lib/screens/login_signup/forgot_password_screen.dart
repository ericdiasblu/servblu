import 'package:flutter/material.dart';
import 'package:servblu/widgets/build_button.dart';
import 'package:servblu/screens/login_signup/login_screen.dart';

import '../../widgets/input_field.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints.expand(),
          color: const Color(0xFFFFFFFF),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 105, bottom: 45, left: 42, right: 74),
                  width: double.infinity,
                  child: const Text(
                    "Insira a nova senha para sua conta",
                    style: TextStyle(
                      color: Color(0xFF000000),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildDivider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 36),
                  child: Column(
                    children: [
                      InputField(
                        obscureText: true,
                        icon: Icons.lock,
                        hintText: "Nova Senha",
                        controller: newPasswordController,
                      ),
                      InputField(
                        obscureText: true,
                        icon: Icons.lock,
                        hintText: "Confirme a Nova Senha",
                        controller: confirmPasswordController,
                      ),
                      const SizedBox(height: 20),
                      BuildButton(
                        textButton: "Atualize sua senha",
                        onPressed: () {
                          // Lógica para atualizar a senha
                          print("Botão 'Atualize sua senha' pressionado!");
                        },
                        screenRoute: () => LoginScreen(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return IntrinsicHeight(
      child: Container(
        margin: const EdgeInsets.only(bottom: 25, left: 40, right: 267),
        width: double.infinity,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                color: const Color(0xFF017DFE),
                height: 3,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              color: const Color(0xFF017DFE),
              width: 13,
              height: 3,
            ),
          ],
        ),
      ),
    );
  }
}
