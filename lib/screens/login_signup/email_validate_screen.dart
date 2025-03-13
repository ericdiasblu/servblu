import 'package:flutter/material.dart';
import 'package:servblu/auth/auth_service.dart';
import 'package:servblu/widgets/build_button.dart';
import 'package:servblu/widgets/input_field.dart';

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

    setState(() {
      _isLoading = true;
    });

    try {
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
          "Informe seu email para receber um link de redefinição de senha",
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
            ? const CircularProgressIndicator(
          color: Color(0xFF017DFE),
        )
            : BuildButton(
          textButton: "Enviar link de recuperação",
          onPressed: resetPassword,
        ),

        const SizedBox(height: 40),

        // Imagem ilustrativa para a página

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
          "Verifique sua caixa de entrada e siga as instruções para redefinir sua senha.",
          style: TextStyle(
            color: Color(0xFF000000),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 30),

        BuildButton(
          textButton: "Voltar para o login",
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        const SizedBox(height: 40),

        // Imagem ilustrativa para a página
        Image.asset(
          'assets/forgot_password_image.png',
          height: 250,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}