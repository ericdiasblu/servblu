import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servblu/auth/auth_service.dart';
import 'package:servblu/widgets/build_services_profile.dart';
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                        : Text(telefoneUsuario!,style: TextStyle(fontWeight: FontWeight.w300),),
                    Text(currentEmail ?? "Email não disponível",style: TextStyle(fontWeight: FontWeight.w300),),
                    SizedBox(
                      height: 10,
                    ),
                    Stack(
                      children: [
                        Opacity(
                          opacity: 0.05,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5), // Espaçamento interno
                          ),
                        ),
                        Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5), // Ajusta ao texto
                          child: enderecoUsuario == null
                              ? const CircularProgressIndicator()
                              : Text(
                                  '$enderecoUsuario',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                        ),
                      ],
                    )
                  ],
                )
              ],
            ),
            const SizedBox(height: 70),
            Padding(
                padding: EdgeInsets.only(left: 30),
                child: Text(
                  "Serviços",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                )),
            SizedBox(
              height: 110,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                    ),
                    BuildServicesProfile(
                      nomeServico: "Aula Gramática",
                      descServico:
                          "Some short description of this type of report.",
                      corContainer: Colors.purple,
                      corTexto: Color(0xFF403572),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    BuildServicesProfile(
                      nomeServico: "Aula Gramática",
                      descServico:
                          "Some short description of this type of report.",
                      corContainer: Colors.yellow,
                      corTexto: Color(0xFFF77f00),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    BuildServicesProfile(
                      nomeServico: "Aula Gramática",
                      descServico:
                          "Some short description of this type of report.",
                      corContainer: Colors.red,
                      corTexto: Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 40,
            ),
            Padding(
                padding: EdgeInsets.only(left: 30),
                child: Text(
                  "Avaliações",
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                )),
            Padding(
              padding: const EdgeInsets.only(left: 30, bottom: 30, top: 10),
              child: Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    color: Color(0xFFFFB703),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 110,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    SizedBox(
                      width: 30,
                    ),
                    BuildServicesProfile(
                      nomeServico: "Vitor Rodrigues",
                      descServico: "Atendimento muito bom!",
                      corContainer: Colors.green,
                      corTexto: Color(0xFF479696),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    BuildServicesProfile(
                      nomeServico: "Vitor Rodrigues",
                      descServico: "Atendimento muito bom!",
                      corContainer: Colors.orange,
                      corTexto: Colors.orange,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    BuildServicesProfile(
                      nomeServico: "Vitor Rodrigues",
                      descServico: "Atendimento muito bom!",
                      corContainer: Colors.pink,
                      corTexto: Colors.pink,
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    BuildServicesProfile(
                      nomeServico: "Vitor Rodrigues",
                      descServico: "Atendimento muito bom!",
                      corContainer: Colors.red,
                      corTexto: Colors.red,
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
