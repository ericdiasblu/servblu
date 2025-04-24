import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:servblu/auth/auth_service.dart';
import 'package:servblu/models/servicos/servico.dart';
import 'package:servblu/screens/pagamento/saque_screen.dart';
import 'package:servblu/services/servico_service.dart';
import 'package:servblu/widgets/build_services_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:servblu/screens/service_page/service_screen.dart';
import 'package:servblu/utils/navigation_helper.dart';
import '../../services/notification_service.dart';
import 'package:servblu/router/router.dart';
import 'package:servblu/router/routes.dart';

import '../../widgets/tool_loading.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final authService = AuthService();
  final supabase = Supabase.instance.client;
  final ServicoService _servicoService = ServicoService();

  String? nomeUsuario,
      telefoneUsuario,
      enderecoUsuario,
      saldoUsuario,
      fotoPerfil;
  bool isLoading = false;
  bool isLoadingServicos = true;
  List<Servico> servicosUsuario = [];

  @override
  void initState() {
    super.initState();
    carregarDadosUsuario();
    carregarServicosUsuario();
  }

  Future<void> carregarDadosUsuario() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final response = await supabase
          .from('usuarios')
          .select('nome, telefone, endereco, saldo, foto_perfil')
          .eq('id_usuario', user.id)
          .maybeSingle();

      setState(() {
        nomeUsuario = response?['nome'] ?? 'Usuário';
        telefoneUsuario = response?['telefone'] ?? 'Telefone não disponível';
        enderecoUsuario = response?['endereco'] ?? 'Endereço inválido';
        fotoPerfil = response?['foto_perfil'];

        // Formata o saldo para duas casas decimais, por exemplo
        if (response?['saldo'] != null) {
          final saldo = response!['saldo'];
          saldoUsuario = NumberFormat("#,##0.00", "pt_BR").format(saldo);
        } else {
          saldoUsuario = "Saldo indisponível";
        }
      });
    }
  }

  Future<void> carregarServicosUsuario() async {
    setState(() {
      isLoadingServicos = true;
    });

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final servicos =
            await _servicoService.obterServicosPorPrestador(user.id);

        setState(() {
          servicosUsuario = servicos;
          isLoadingServicos = false;
        });
      }
    } catch (e) {
      print('Erro ao carregar serviços: $e');
      setState(() {
        isLoadingServicos = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao carregar serviços: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      isLoading = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final String fileExtension = path.extension(image.path);
      final String fileName =
          '${user.id}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      final String filePath = 'fotos/$fileName';

      // Upload da imagem para o bucket do Supabase
      final File file = File(image.path);
      await supabase.storage.from('bucket1').upload(
            filePath,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Obter o URL público da imagem
      final String imageUrl =
          supabase.storage.from('bucket1').getPublicUrl(filePath);

      // Atualizar o perfil do usuário no banco de dados
      await supabase
          .from('usuarios')
          .update({'foto_perfil': imageUrl}).eq('id_usuario', user.id);

      // Atualizar a UI
      setState(() {
        fotoPerfil = imageUrl;
        isLoading = false;
      });

      // Mostrar mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil atualizada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      setState(() {
        isLoading = false;
      });

      // Mostrar erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar foto: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void navegarParaDetalheServico(String idServico) {
    // Find the service
    final servico = servicosUsuario.firstWhere(
      (s) => s.idServico == idServico,
    );

    if (servico != null) {
      NavigationHelper.navigateToServiceDetails(context, servico)
          .then((wasDeleted) {
        if (wasDeleted == true) {
          carregarServicosUsuario();
        }
      });
    }
  }

  Widget _buildServicosSection() {
    if (isLoadingServicos) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: ToolLoadingIndicator(color: Colors.blue, size: 45),
        ),
      );
    }

    if (servicosUsuario.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Center(
          child: Column(
            children: [
              const Text(
                "Você ainda não tem serviços cadastrados",
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  // Navegar para tela de cadastro de serviço
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ServicoTestScreen(),
                    ),
                  ).then((_) {
                    // Recarregar serviços quando voltar
                    carregarServicosUsuario();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF017DFE),
                ),
                child: const Text(
                  "Cadastrar Serviço",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const SizedBox(width: 20),
            // Exibir serviços do banco de dados
            ...servicosUsuario.map((servico) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: BuildServicesProfile.fromServico(
                  servico,
                  onServiceDeleted: () {
                    // This is the callback for when a service is deleted
                    carregarServicosUsuario();
                  },
                ),
              );
            }).toList(),
            // Botão de adicionar novo serviço

            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentEmail = authService.getCurrentUserEmail();

    return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: RefreshIndicator(
          // Add this RefreshIndicator
          onRefresh: () async {
            await carregarServicosUsuario();
            await carregarDadosUsuario();
          },
          child: SingleChildScrollView(
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
                      Positioned(
                        left: 10,
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WithdrawalScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.money, color: Colors.white),
                        ),
                      ),
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
                            await _logout();
                          },
                          icon: const Icon(Icons.logout, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _pickAndUploadImage,
                      child: Container(
                        margin: const EdgeInsets.only(left: 20),
                        width: 111,
                        height: 111,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.black),
                          image: fotoPerfil != null
                              ? DecorationImage(
                                  image: NetworkImage(fotoPerfil!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (isLoading)
                              const ToolLoadingIndicator(
                                  color: Colors.blue, size: 45)
                            else if (fotoPerfil == null)
                              const Icon(
                                Icons.person,
                                size: 80,
                              ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF017DFE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          nomeUsuario == null
                              ? const ToolLoadingIndicator(
                                  color: Colors.blue, size: 45)
                              : Text(
                                  nomeUsuario!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                          telefoneUsuario == null
                              ? const ToolLoadingIndicator(
                                  color: Colors.blue, size: 45)
                              : Text(
                                  telefoneUsuario!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w300),
                                ),
                          Text(
                            currentEmail ?? "Email não disponível",
                            style: const TextStyle(fontWeight: FontWeight.w300),
                          ),
                          saldoUsuario == null
                              ? const ToolLoadingIndicator(
                                  color: Colors.blue, size: 45)
                              : Text(
                                  "Saldo: ${saldoUsuario!}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w300),
                                ),
                          GestureDetector(
                            onTap: () {
                              context.go(Routes.disponibilidadePage);
                            },
                            child: const Text(
                              "Editar Disponibilidade",
                              style: TextStyle(
                                color: Color(0xFF017DFE),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              context.go(Routes.editarPerfil);
                            },
                            child: const Text(
                              "Editar Perfil",
                              style: TextStyle(
                                color: Color(0xFF017DFE),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              child: enderecoUsuario == null
                                  ? const ToolLoadingIndicator(
                                      color: Colors.blue, size: 45)
                                  : Text(
                                      '$enderecoUsuario',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 70),
                const Padding(
                  padding: EdgeInsets.only(left: 30, bottom: 10),
                  child: Text(
                    "Serviços",
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                  ),
                ),
                _buildServicosSection(),
                const SizedBox(height: 40),
                const Padding(
                  padding: EdgeInsets.only(left: 30),
                  child: Text(
                    "Avaliações",
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30, bottom: 30, top: 10),
                  child: Row(
                    children: List.generate(
                      5,
                      (index) => const Icon(
                        Icons.star,
                        color: Color(0xFFFFB703),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 400,
                )
              ],
            ),
          ),
        ));
  }

  Future<void> _logout() async {
    try {
      // Remove o token do Supabase e localmente
      await NotificationService.removeUserTokens();

      // Faz logout do usuário
      await supabase.auth.signOut();

      // Navega para a tela de login
      GoRouter.of(context).go('/enter');
    } catch (e) {
      print("Erro ao fazer logout: $e");
      // Ainda tenta navegar para a tela de login mesmo se houver erro
      GoRouter.of(context).go('/enter');
    }
  }
}
