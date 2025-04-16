import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:go_router/go_router.dart';
import 'package:servblu/router/routes.dart';
import 'package:servblu/widgets/build_button.dart';
import 'package:servblu/widgets/build_header.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/input_dropdown_field.dart';
import '../../widgets/input_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final MaskedTextController _phoneController = MaskedTextController(mask: '(00) 00000-0000');
  final TextEditingController _addressController = TextEditingController();

  final _supabase = Supabase.instance.client;
  bool _isLoading = true;

  BuildContext? _context; // Armazenar a referência do contexto

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _context = context; // Armazenar o contexto
  }

  @override
  void dispose() {
    // Descartar os controladores quando o widget for removido da árvore
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Carregar dados do usuário
  Future<void> _loadUserData() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('usuarios')
          .select()
          .eq('id_usuario', userId)
          .single();

      if (response != null) {
        setState(() {
          _nameController.text = response['nome'] ?? '';
          _emailController.text = response['email'] ?? '';
          _phoneController.text = response['telefone'] ?? '';
          _addressController.text = response['endereco'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(content: Text("Erro ao carregar dados: ${e.toString()}")),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Atualizar perfil do usuário
  Future<void> _updateProfile() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final phone = _phoneController.text;
    final address = _addressController.text;

    if (name.isEmpty || email.isEmpty || phone.isEmpty || address.isEmpty) {
      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(content: Text("Preencha todos os campos")),
        );
      }
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final userId = _supabase.auth.currentUser!.id;

      // Atualizar informações na tabela 'usuarios'
      await _supabase
          .from('usuarios')
          .update({
        'nome': name,
        'email': email,
        'telefone': phone,
        'endereco': address,
      })
          .eq('id_usuario', userId);

      // Se o email foi alterado, atualizar também na autenticação
      if (email != _supabase.auth.currentUser!.email) {
        await _supabase.auth.updateUser(
          UserAttributes(
            email: email,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          const SnackBar(content: Text("Perfil atualizado com sucesso!")),
        );
        // Use GoRouter to navigate back to profile page
        context.go(Routes.profilePage);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (_context != null) {
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(content: Text("Erro ao atualizar perfil: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
          children: [
            // Use BuildHeader with GoRouter navigation
            BuildHeader(
              title: 'Editar Perfil',
              backPage: true,
              onBack: () {
                // Use GoRouter to navigate back to profile page
                context.go(Routes.profilePage);
              },
              refresh: false,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 37),
                child: ListView(
                  children: [
                    SizedBox(height: screenHeight * 0.05),
                    const Text(
                      "Edite seus dados",
                      style: TextStyle(
                        color: Color(0xFF000000),
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),

                    // Campos de entrada
                    InputField(
                      icon: Icons.person,
                      hintText: "Nome",
                      controller: _nameController,
                      obscureText: false,
                    ),
                    InputField(
                      icon: Icons.email,
                      hintText: "Email",
                      controller: _emailController,
                      obscureText: false,
                    ),
                    InputField(
                      icon: Icons.phone,
                      hintText: "Telefone",
                      controller: _phoneController,
                      obscureText: false,
                      maskedController: _phoneController,
                    ),
                    BuildDropdownField(
                      icon: Icons.home,
                      hintText: "Bairro",
                      controller: _addressController,
                      selectedOption: _addressController.text.isNotEmpty ? _addressController.text : null,
                    ),
                    const SizedBox(height: 20),

                    // Botão de salvar alterações
                    BuildButton(
                      textButton: "Salvar Alterações",
                      onPressed: _updateProfile,
                    ),

                    SizedBox(height: screenHeight * 0.05),
                  ],
                ),
              ),
            ),
          ],
        ),

    );
  }
}