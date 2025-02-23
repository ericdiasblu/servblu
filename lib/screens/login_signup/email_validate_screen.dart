import 'package:flutter/material.dart';
import 'package:servblu/models/build_button.dart';
import 'package:servblu/models/input_field.dart';
import 'package:servblu/screens/login_signup/forgot_password_screen.dart';

class EmailValidateScreen extends StatelessWidget {
  const EmailValidateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

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
                  margin: const EdgeInsets.only(top: 124, bottom: 26, left: 38, right: 171),
                  width: double.infinity,
                  child: const Text(
                    "Insira o email da sua conta",
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
                        obscureText: false,
                        icon: Icons.email,
                        hintText: "Email",
                        controller: emailController,
                      ),
                      const SizedBox(height: 10),
                      BuildButton(
                        textButton: "Valide seu Email",
                        onPressed: () {
                          // Lógica para validar o email
                          print("Botão 'Valide seu Email' pressionado!");
                        },
                        screenRoute: () => ForgotPasswordScreen(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                _buildImage(),
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

  Widget _buildImage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 38, left: 8, right: 8),
      height: 376,
      width: double.infinity,
      child: const Image(
        image: AssetImage("assets/forgot_password_image.png"),
      ),
    );
  }
}
