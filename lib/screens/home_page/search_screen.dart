import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/routes.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Controlador para o campo de texto da busca
  final TextEditingController _searchController = TextEditingController();

  // Lista de dados fictícios para os serviços (original)
  final List<Map<String, dynamic>> _allServices = [
    {
      "image": "", // Substitua por 'assets/seu_arquivo.png' ou URL da imagem
      "name": "Serviço 1",
      "category": "Categoria A",
      "price": "R\$ 50,00",
      "rating": 4.3,
    },
    {
      "image": "",
      "name": "Serviço 2",
      "category": "Categoria B",
      "price": "R\$ 70,00",
      "rating": 4.5,
    },
    {
      "image": "",
      "name": "Serviço 3",
      "category": "Categoria C",
      "price": "R\$ 90,00",
      "rating": 4.0,
    },
    {
      "image": "",
      "name": "Serviço 4",
      "category": "Categoria A",
      "price": "R\$ 120,00",
      "rating": 4.8,
    },
    {
      "image": "",
      "name": "Serviço 5",
      "category": "Categoria B",
      "price": "R\$ 60,00",
      "rating": 4.1,
    },
    {
      "image": "",
      "name": "Serviço 6",
      "category": "Categoria C",
      "price": "R\$ 85,00",
      "rating": 4.4,
    },
    {
      "image": "",
      "name": "Serviço 7",
      "category": "Categoria A",
      "price": "R\$ 95,00",
      "rating": 4.2,
    },
    {
      "image": "",
      "name": "Serviço 8",
      "category": "Categoria B",
      "price": "R\$ 110,00",
      "rating": 4.7,
    },
  ];

  // Lista filtrada que será exibida - inicializada diretamente sem 'late'
  List<Map<String, dynamic>> _filteredServices = [];

  // Categoria selecionada para filtro (null significa todas)
  String? _selectedCategory;

  // Lista de todas as categorias disponíveis
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    // Inicializa a lista filtrada com todos os serviços
    _filteredServices = List.from(_allServices);

    // Extrair categorias únicas
    _categories = _allServices
        .map((service) => service["category"] as String)
        .toSet()
        .toList();

    // Adicionar listener para o campo de busca
    _searchController.addListener(_filterServices);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Método para filtrar os serviços com base APENAS no nome do serviço e categoria selecionada
  void _filterServices() {
    final String query = _searchController.text.toLowerCase();

    setState(() {
      _filteredServices = _allServices.where((service) {
        // Agora verificamos APENAS se o nome do serviço corresponde à consulta de busca
        final bool matchesQuery = service["name"].toString().toLowerCase().contains(query);

        // Verificar se o serviço corresponde à categoria selecionada (se houver)
        final bool matchesCategory = _selectedCategory == null ||
            service["category"] == _selectedCategory;

        // O serviço precisa corresponder tanto ao nome quanto à categoria
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
                        const SizedBox(width: 80),
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
                              hintText: "Procure por serviço",  // Alterado o hint para indicar que a busca é só por nome
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

                    // Mensagem quando não há resultados
                    if (_filteredServices.isEmpty)
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
                                  // Implemente isso baseado na sua estrutura de rotas
                                  // Por exemplo: GoRouter.of(context).go('${Routes.serviceDetails}/${index}');
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
                                        image: service["image"] != ""
                                            ? DecorationImage(
                                          image: AssetImage(service["image"]),
                                          fit: BoxFit.cover,
                                        )
                                            : null,
                                      ),
                                      child: service["image"] == ""
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
                                            service["name"],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            service["category"],
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Preço: ${service["price"]}",
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                "${service["rating"]}",
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