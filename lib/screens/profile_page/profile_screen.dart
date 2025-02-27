import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servblu/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final authService = AuthService();
  final supabase = Supabase.instance.client;
  String? nomeUsuario, telefoneUsuario, enderecoUsuario;

  @override
  void initState() {
    super.initState();
    carregarDadosUsuario();
  }

  Future<void> carregarDadosUsuario() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('usuarios')
          .select('nome, telefone, endereco')
          .eq('id_usuario', user.id)
          .maybeSingle();

      setState(() {
        nomeUsuario = response?['nome'] ?? 'Usuário';
        telefoneUsuario = response?['telefone'] ?? 'Telefone não disponível';
        enderecoUsuario = response?['endereco'] ?? 'Endereco inválido';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = authService.getCurrentUserEmail();

    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF017DFE),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              width: double.infinity,
              height: 100,
              padding: const EdgeInsets.only(top: 37, bottom: 40),
              margin: const EdgeInsets.only(bottom: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    "Perfil",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  Positioned(
                    right: 10,
                    child: IconButton(
                      onPressed: () async {
                        await supabase.auth.signOut();
                        GoRouter.of(context).go('/enter');
                      },
                      icon: const Icon(Icons.logout, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 20),
                  width: 111,
                  height: 111,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.black),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 80,
                  ),
                ),
                const SizedBox(width: 50),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    nomeUsuario == null
                        ? const CircularProgressIndicator()
                        : Text(
                            nomeUsuario!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                    telefoneUsuario == null
                        ? const CircularProgressIndicator()
                        : Text(telefoneUsuario!),
                    Text(currentEmail ?? "Email não disponível"),
                    Stack(
                      children: [
                        Opacity(
                          opacity: 0.05,
                          child: Container(
                            width: 70,
                            height: 25,
                            color: Colors.green,
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          width: 70,
                          height: 25,
                          child: enderecoUsuario == null
                              ? const CircularProgressIndicator()
                              : Text(
                            '$enderecoUsuario',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        )
                      ],
                    ),
                  ],
                )
              ],
            ),
            const SizedBox(height: 70),
            const Text("Serviços"),
            SizedBox(
              height: 110,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Opacity(
                          opacity: 0.05,
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.green,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8.0),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Aula Básica",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              Text("Descrição da aula básica."),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
