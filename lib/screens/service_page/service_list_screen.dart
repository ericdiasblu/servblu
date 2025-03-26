import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/servicos/servico.dart';
import '../../router/routes.dart';
import '../../utils/navigation_helper.dart';

class ServiceListScreen extends StatefulWidget {
  final String title;
  final String? category;

  const ServiceListScreen({
    super.key,
    required this.title,
    this.category
  });

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  List<Servico> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Start with a base select query
      var query = supabase.from('servicos').select();

      // If a category is specified, add filter
      if (widget.category != null) {
        query = query.eq('categoria', widget.category!);
      }

      // Add ordering

      // Execute the query and await the response
      final response = await query;

      // Convert response to Servico objects
      final List<Servico> services = (response as List)
          .map<Servico>((json) => Servico.fromJson(json))
          .toList();

      setState(() {
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching services: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar serviços: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * 0.15; // 1/3 da tela

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
          children: [
            // Cabeçalho azul fixo
            Container(
              height: headerHeight,
              color: const Color(0xFF017DFE),
              child: Column(
                children: [
                  // Título e botão de voltar
                  Padding(
                    padding: const EdgeInsets.only(top: 45, left: 20, right: 20),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Back button positioned on the left
                        Positioned(
                          left: 0,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            color: Colors.white,
                            onPressed: () {
                              GoRouter.of(context).go(Routes.homePage);
                            },
                          ),
                        ),

                        // Centered title
                        Center(
                          child: Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 30,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),
                  Container(
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(45),
                        topRight: Radius.circular(45),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Conteúdo scrollável com lista de serviços
            Expanded(
              child: Container(
                color: Colors.white,
                child: Column(
                  children: [
                    // Loading indicator or No results message
                    if (_isLoading)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_services.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.search_off,
                                size: 50,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "Nenhum serviço encontrado",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                    // Lista scrollável
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _services.length,
                          itemBuilder: (context, index) {
                            final service = _services[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: InkWell(
                                onTap: () {
                                  NavigationHelper.navigateToServiceDetails(context, service);
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Imagem do serviço
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.grey[300],
                                        image: service.imgServico != null && service.imgServico!.isNotEmpty
                                            ? DecorationImage(
                                          image: NetworkImage(service.imgServico!),
                                          fit: BoxFit.cover,
                                        )
                                            : null,
                                      ),
                                      child: service.imgServico == null || service.imgServico!.isEmpty
                                          ? const Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Colors.grey,
                                      )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    // Informações do serviço
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            service.nome,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            service.categoria,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Preço: R\$ ${service.preco?.toStringAsFixed(2) ?? 'N/A'}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Text(
                                                "4.1",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.black,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 16,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Ícone de seta para a direita
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),

    );
  }
}