import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'package:servblu/auth/auth_service.dart';
import 'package:servblu/screens/login_signup/reset_password_screen.dart';
import 'package:servblu/widgets/build_button.dart';
import 'package:servblu/widgets/input_field.dart';

import '../../widgets/tool_loading.dart';

class EmailValidateScreen extends StatefulWidget {
  const EmailValidateScreen({Key? key}) : super(key: key);

  @override
  State<EmailValidateScreen> createState() => _EmailValidateScreenState();
}

class _EmailValidateScreenState extends State<EmailValidateScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> resetPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, informe seu email.")),
      );
      return;
    }
    // Validação do email usando email_validator
    if (!EmailValidator.validate(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Formato de email inválido.")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Chama o método que solicita o envio do token de recuperação.
      // Lembre-se de que no Supabase você deve configurar o template para mostrar o token ({{ .Token }})
      await _authService.resetPassword(email);

      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro ao solicitar redefinição de senha: $e"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recuperar Senha"),
        backgroundColor: const Color(0xFFF5F5F5),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 37),
        child: _emailSent ? _buildSuccessContent() : _buildFormContent(),
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.1),
        const Text(
          "Esqueceu sua senha?",
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        const Text(
          // Alterado para informar que será enviado um token
          "Informe seu email para receber seu token de recuperação.",
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        InputField(
          obscureText: false,
          icon: Icons.email,
          hintText: "Email",
          controller: _emailController,
        ),
        const SizedBox(height: 30),
        _isLoading
            ? ToolLoadingIndicator(color: Colors.blue, size: 45)
            : BuildButton(
          textButton: "Enviar token de recuperação",
          onPressed: resetPassword,
        ),
        const SizedBox(height: 40),
        // Aqui você pode adicionar uma imagem ilustrativa ou outros widgets
      ],
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.1),
        const Icon(
          Icons.mark_email_read,
          size: 80,
          color: Color(0xFF017DFE),
        ),
        const SizedBox(height: 30),
        const Text(
          "Email enviado!",
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 15),
        const Text(
          "Verifique sua caixa de entrada (e a pasta de spam) para obter seu token de recuperação.",
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),
        BuildButton(
          textButton: "Redefinir Senha",
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ResetPasswordScreen()));
          },
        ),
        const SizedBox(height: 40),
        Image.asset(
          'assets/forgot_password_image.png',
          height: 250,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}
