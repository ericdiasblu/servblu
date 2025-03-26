import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:servblu/widgets/image_slider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../router/routes.dart';
import '../../widgets/build_categories.dart';
import '../../router/router.dart';
import '../login_signup/enter_screen.dart';
import '../login_signup/login_screen.dart';
import '../../services/notification_service.dart';
import 'package:servblu/models/servicos/servico.dart';
import '../../router/routes.dart';
import '../../utils/navigation_helper.dart';

import '../../models/servicos/servico.dart';

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  final supabase = Supabase.instance.client;

  List<Servico> _bestOffers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _setupNotifications();
    _fetchBestOffers();
    supabase.auth.onAuthStateChange.listen((event) {
      final session = supabase.auth.currentSession;

      if (session == null) {
        // Se a sessão expirar, redireciona para a tela de login
        context.go(Routes.enterPage);
      }
    });
  }


  Future<void> _setupNotifications() async {
    try {
      // Apenas inicializa o serviço, sem tentar salvar o token
      await NotificationService.initialize();

      // Verificamos se o usuário já está autenticado (caso de retorno ao app)
      // e não durante o primeiro login, que é tratado pelo LoginScreen
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Verifica se precisamos atualizar o token no Supabase
        final localToken = await NotificationService.getLocalToken();
        if (localToken != null) {
          // Salva o token no Supabase
          await NotificationService.saveLocalTokenAfterLogin();
        }
      }
    } catch (e) {
      print("Error setting up notifications: $e");
    }
  }

  Future<void> _fetchBestOffers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch services, you can modify the query as needed
      final response = await supabase
          .from('servicos')
          .select()
          .order('preco', ascending: true) // Example: order by lowest price
          .limit(4); // Limit to 4 services

      // Convert response to Servico objects
      final List<Servico> offers = response
          .map<Servico>((json) => Servico.fromJson(json))
          .toList();

      setState(() {
        _bestOffers = offers;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching best offers: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF3F3F3),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildListCategories(),
              SizedBox(height: 30,),
              ImageSlider(
                  imagePaths: [
                    'assets/home_image.jpg',
                    'assets/second_image.png',
                    'assets/offer_image.png'
              ]),
              SizedBox(height: 30,),
              _buildBestOffersTitle(),
              _buildBestOffers(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        color: const Color(0xFF017DFE),
      ),
      padding: const EdgeInsets.only(top: 37, bottom: 40),
      margin: const EdgeInsets.only(bottom: 38),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 26, left: 26),
            child: Row(
              children: [
                Text(
                  "ServBlu",
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.home_repair_service, color: Colors.white, size: 30),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 20, right: 10),
            width: 370,
            child: TextField(
              onTap: () {
                GoRouter.of(context).go(Routes.searchPage);
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
                prefixIcon: const Icon(Icons.search),
                hintText: "Procure por serviço",
                hintStyle:
                    const TextStyle(color: Color(0xFF000000), fontSize: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 7),
              ),
              style: const TextStyle(color: Color(0xFF000000), fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestOffersTitle() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11, left: 31),
      child: const Text(
        "Melhores ofertas",
        style: TextStyle(
          color: Color(0xFF000000),
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBestOffers() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2, left: 19),
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: (_bestOffers.length > 3 ? 3 : _bestOffers.length) + 1, // +1 para o botão
          itemBuilder: (context, index) {
            if (index < 3 && index < _bestOffers.length) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _buildOfferCard(_bestOffers[index]),
              );
            } else {
              // Último item: Botão "Ver Mais"
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: SizedBox(
                  width: 120, // Espaço do botão (mesmo tamanho dos cards)
                  height: 200, // Mantém a altura do espaço igual à da lista
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Centraliza na vertical
                    children: [
                      SizedBox(
                        width: 110, // Largura um pouco maior para caber o texto
                        height: 36, // Ajuste fino na altura
                        child: ElevatedButton(
                          onPressed: () {
                            context.go(Routes.serviceListPage, extra: "Serviços");
                          },
                          style: ElevatedButton.styleFrom(

                            backgroundColor: const Color(0xFF017DFE),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8), // Margin interna
                          ),
                          child: const Text(
                            "Ver Mais",
                            style: TextStyle(color: Colors.white, fontSize: 13), // Fonte menor
                            overflow: TextOverflow.ellipsis, // Garante que não quebre
                          ),
                        ),
                      ),
                      const SizedBox(height: 6), // Pequena margem inferior para alinhamento
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }



  Widget _buildOfferCard(Servico offer) {
    return GestureDetector(
      onTap: () {
        NavigationHelper.navigateToServiceDetails(context, offer);
      },
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 209,
              height: 130,
              child: offer.imgServico != null && offer.imgServico!.isNotEmpty
                  ? Image.network(
                offer.imgServico!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.image_not_supported, size: 50);
                },
              )
                  : Container(
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 50, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              offer.nome,
              style: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Center(
            child: Text(
              offer.descricao ?? "Sem descrição",
              style: const TextStyle(
                color: Color(0xFF000000),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildImage() {
    return Column(
      children: [
        SizedBox(height: 30),
        Image.asset(
          'assets/home_image.jpg',
          fit: BoxFit.cover,
          width: 415,
          height: 197,
        ),
        SizedBox(height: 30),
      ],
    );
  }

  Widget _buildListCategories() {
    return Container(
      color: const Color(0xFFF3F3F3),
      height: 110,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(width: 20),
            BuildCategories(textCategory: 'Escritório', icon: Icons.work),
            SizedBox(width: 20),
            BuildCategories(
                textCategory: 'Eletricista', icon: Icons.electric_bolt_rounded),
            SizedBox(width: 20),
            BuildCategories(textCategory: 'Tecnologia', icon: Icons.computer),
            SizedBox(width: 20),
            BuildCategories(textCategory: 'Manutenção', icon: Icons.build),
            SizedBox(width: 20),
            BuildCategories(
                textCategory: 'Higienização',
                icon: Icons.cleaning_services_rounded),
            SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
