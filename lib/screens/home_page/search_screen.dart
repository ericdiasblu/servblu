import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../models/servicos/servico.dart';
import '../../router/routes.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
  final Uuid _uuid = Uuid();

  // List to store all services from Supabase
  List<Servico> _allServices = [];
  List<Servico> _filteredServices = [];

  // Categorias disponíveis
  List<String> _categories = [];
  String? _selectedCategory;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
    _searchController.addListener(_filterServices);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Método para buscar todos os serviços do Supabase
  Future<void> _fetchServices() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Buscar todos os serviços
      final response = await supabase
          .from('servicos')
          .select()
          .order('nome', ascending: true);

      // Converter a resposta para uma lista de Servico
      final List<Servico> services = response
          .map<Servico>((json) => Servico.fromJson(json))
          .toList();

      // Extrair categorias únicas
      final categories = services
          .map((service) => service.categoria)
          .toSet()
          .toList();

      setState(() {
        _allServices = services;
        _filteredServices = List.from(_allServices);
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar serviços: $e')),
      );
    }
  }

  // Método para filtrar os serviços
  void _filterServices() {
    final String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredServices = _allServices.where((service) {
        // Verificar se o nome do serviço corresponde à consulta
        final bool matchesQuery = service.nome.toLowerCase().contains(query);

        // Verificar se o serviço corresponde à categoria selecionada
        final bool matchesCategory = _selectedCategory == null ||
            service.categoria == _selectedCategory;

        return matchesQuery && matchesCategory;
      }).toList();
    });
  }

  // Método para exibir o diálogo de filtro por categorias
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Filtrar por categoria"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Opção para mostrar todas as categorias
                ListTile(
                  title: const Text("Todas as categorias"),
                  leading: Radio<String?>(
                    value: null,
                    groupValue: _selectedCategory,
                    onChanged: (value) {
                      Navigator.pop(context);
                      setState(() {
                        _selectedCategory = value;
                        _filterServices();
                      });
                    },
                  ),
                ),
                // Opções para cada categoria disponível
                ..._categories.map((category) => ListTile(
                  title: Text(category),
                  leading: Radio<String?>(
                    value: category,
                    groupValue: _selectedCategory,
                    onChanged: (value) {
                      Navigator.pop(context);
                      setState(() {
                        _selectedCategory = value;
                        _filterServices();
                      });
                    },
                  ),
                )).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * 0.33; // 1/3 da tela

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho azul fixo
            Container(
              height: headerHeight,
              color: const Color(0xFF017DFE),
              child: Column(
                children: [
                  // Título e botão de voltar
                  Padding(
                    padding: const EdgeInsets.only(top: 30, left: 20, right: 20),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios),
                          color: Colors.white,
                          onPressed: () {
                            GoRouter.of(context).go(Routes.homePage);
                          },
                        ),
                        const SizedBox(width: 85),
                        const Text(
                          "Busca",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 30,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Campo de busca e filtro
                  Padding(
                    padding: const EdgeInsets.only(left: 30, right: 30),
                    child: Row(
                      children: [
                        // TextField expandido para busca
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.search),
                              hintText: "Procure por serviço",
                              hintStyle: const TextStyle(
                                  color: Colors.black, fontSize: 15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 7),
                              // Botão para limpar a pesquisa
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                                  : null,
                            ),
                            style: const TextStyle(
                                color: Colors.black, fontSize: 15),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Botão de filtro
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _showFilterDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 2,
                              padding: const EdgeInsets.all(10),
                            ),
                            child: const Icon(
                              Icons.filter_alt,
                              size: 30,
                              color: Color(0xFF017DFE),
                            ),
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
                    // Título "Resultados" com contador
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 20, right: 20, top: 10, bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Resultados:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            "${_filteredServices.length} encontrados",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Indicador de filtro ativo (se houver)
                    if (_selectedCategory != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            const Text(
                              "Filtro: ",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Chip(
                              label: Text(_selectedCategory!),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  _selectedCategory = null;
                                  _filterServices();
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                    // Loading indicator or No results message
                    if (_isLoading)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_filteredServices.isEmpty)
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
                              const SizedBox(height: 8),
                              const Text(
                                "Tente mudar os termos da busca ou filtros",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
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
                          itemCount: _filteredServices.length,
                          itemBuilder: (context, index) {
                            final service = _filteredServices[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: InkWell(
                                onTap: () {
                                  // Navegação para a página de detalhes do serviço

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
                                            "Preço: R\$ ${service.preco?.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                "4.1",
                                                style: const TextStyle(
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
      ),
    );
  }
}