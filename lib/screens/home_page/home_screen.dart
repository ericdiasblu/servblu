import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/build_categories.dart';
import '../../router/router.dart';
import '../login_signup/enter_screen.dart';
import '../login_signup/login_screen.dart';
import '../../services/notification_service.dart';

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    // Inicializa notificações
    _initializeNotifications();

    // Inicializa Firebase Messaging
    _initializeFirebaseMessaging();

    // Registra o token do FCM após o login
    _registerUserToken();

    // Salva o token local no Supabase após o login
    _saveLocalTokenAfterLogin();
  }

  Future<void> _initializeNotifications() async {
    try {
      await NotificationService.initialize();
      print("Serviço de notificações inicializado");
    } catch (e) {
      print("Erro ao inicializar serviço de notificações: $e");
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    // Solicita permissão para notificações
    await FirebaseMessaging.instance.requestPermission();

    // Escuta mudanças no token do FCM
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("Novo token FCM: $newToken");
      await _registerUserToken(token: newToken);
    });
  }

  Future<void> _registerUserToken({String? token}) async {
    final userId = supabase.auth.currentUser?.id;

    if (userId != null) {
      try {
        // Obtém o token do FCM se não for fornecido
        final fcmToken = token ?? await FirebaseMessaging.instance.getToken();

        if (fcmToken != null) {
          // Verifica se o token já está registrado
          final existingToken = await supabase
              .from('device_tokens')
              .select('fcm_token')
              .eq('user_id', userId)
              .eq('fcm_token', fcmToken)
              .maybeSingle();

          if (existingToken == null) {
            // Registra o token no Supabase
            await supabase.from('device_tokens').upsert({
              'user_id': userId,
              'fcm_token': fcmToken,
            });

            print("Token registrado com sucesso: $fcmToken");
          } else {
            print("Token já registrado: $fcmToken");
          }
        }
      } catch (e) {
        print("Erro ao registrar token: $e");
      }
    }
  }

  Future<void> _saveLocalTokenAfterLogin() async {
    try {
      await NotificationService.saveLocalTokenAfterLogin();
      print("Token local salvo no Supabase após login.");
    } catch (e) {
      print("Erro ao salvar token local no Supabase: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFFF5F5F5),
        width: double.infinity,
        height: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildListCategories(),
              _buildImage(),
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
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
                prefixIcon: const Icon(Icons.search),
                hintText: "Procure por serviço",
                hintStyle: const TextStyle(color: Color(0xFF000000), fontSize: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 7),
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
    final List<Map<String, String>> offers = [
      {
        "image":
        "https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/39a08fa2-c5d2-4dce-b74d-4d63cc19293a",
        "name": "Oferta 1",
        "description": "Descrição da oferta 1"
      },
      {
        "image":
        "https://figma-alpha-api.s3.us-west-2.amazonaws.com/images/922884b4-ce18-4414-8962-0b8784a19f99",
        "name": "Oferta 2",
        "description": "Descrição da oferta 2"
      },
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 2, left: 19),
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: offers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _buildOfferCard(offers[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOfferCard(Map<String, String> offer) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 209,
            height: 130,
            child: Image.network(
              offer["image"]!,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Center(
          child: Text(
            offer["name"]!,
            style: const TextStyle(
              color: Color(0xFF000000),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Center(
          child: Text(
            offer["description"]!,
            style: const TextStyle(
              color: Color(0xFF000000),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
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
      color: Colors.white,
      height: 110,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(width: 20),
            BuildCategories(textCategory: 'Escritório', icon: Icons.work),
            SizedBox(width: 20),
            BuildCategories(textCategory: 'Eletricista', icon: Icons.electric_bolt_rounded),
            SizedBox(width: 20),
            BuildCategories(textCategory: 'Tecnologia', icon: Icons.computer),
            SizedBox(width: 20),
            BuildCategories(textCategory: 'Manutenção', icon: Icons.build),
            SizedBox(width: 20),
            BuildCategories(textCategory: 'Higienização', icon: Icons.cleaning_services_rounded),
            SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}