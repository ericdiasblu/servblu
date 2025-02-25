import 'package:flutter/material.dart';
import 'package:servblu/widgets/build_button.dart';
import 'package:servblu/screens/login_signup/login_screen.dart';
import '../../auth/auth_service.dart';
import '../../widgets/input_dropdown_field.dart';
import '../../widgets/input_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers
  final TextEditingController _nameController = TextEditingController(); // Controlador para o nome
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController(); // Controlador para o telefone
  final TextEditingController _addressController = TextEditingController();

  @override
  void dispose() {
    // Descartar os controladores quando o widget for removido da árvore
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    final authService = AuthService();

    // Botão de cadastro
    void signUp() async {
      final name = _nameController.text;
      final email = _emailController.text;
      final password = _passwordController.text;
      final confirmPassword = _confirmPasswordController.text;
      final phone = _phoneController.text;
      final address = _addressController.text;

      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("As senhas não coincidem")),
        );
        return;
      }

      try {
        // Realiza o cadastro (cria o registro na tabela de auth)
        final response = await authService.signUpWithEmailPassword(email, password, name, phone, address);

        // Se o cadastro foi realizado com sucesso, response.user conterá o usuário
        if (response.user != null) {
          // Atualiza os detalhes do usuário na tabela 'usuarios'
          // Note que passamos null para newPassword, pois não precisamos atualizar a senha
          await authService.updateUserDetails(
            response.user!.id,
            response.user!.email ?? email,
            name,
            phone,
            address,
            null,
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cadastro realizado com sucesso!")),
          );

          // Volta para a tela de login
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Falha ao cadastrar usuário.")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: ${e.toString()}")),
        );
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
              InputField(icon: Icons.person, hintText: "Nome", controller: _nameController, obscureText: false),
              InputField(icon: Icons.email, hintText: "Email", controller: _emailController, obscureText: false),
              InputField(icon: Icons.lock, hintText: "Senha", controller: _passwordController, obscureText: true),
              InputField(icon: Icons.lock, hintText: "Confirmar senha", controller: _confirmPasswordController, obscureText: true),
              InputField(icon: Icons.phone, hintText: "Telefone", controller: _phoneController, obscureText: false),
              BuildDropdownField(icon: Icons.home,hintText: "Bairro",controller: _addressController,),
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
