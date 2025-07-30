import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicialização do Firebase para manipulação em segundo plano
  await Firebase.initializeApp();
  print("Mensagem recebida em segundo plano: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String _tokenKey = 'fcm_token'; // Chave constante para o token
  static bool _isInitialized = false;

  // Método para inicializar o serviço de notificações
  static Future<void> initialize() async {
    // Evitar inicialização múltipla
    if (_isInitialized) {
      print("NotificationService já inicializado");
      return;
    }

    try {
      // Configurar manipulador de mensagens em segundo plano
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Solicitar permissão
      await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Configurar canal de notificações locais (Android)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Canal usado para notificações importantes',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Inicializar plugin de notificações locais
      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
        onDidReceiveNotificationResponse: (NotificationResponse details) {
          print('Notificação tocada: ${details.payload}');
        },
      );

      // Configurar manipuladores de notificações em primeiro plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = notification?.android;

        if (notification != null && android != null) {
          _localNotifications.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: android.smallIcon,
              ),
            ),
            payload: message.data.toString(),
          );
        }
      });

      // Lidar com notificações quando o app é aberto através de uma notificação
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Notificação aberta: ${message.data}');
      });

      // Atualizar token quando for atualizado
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        await setupUserToken(newToken);
      });

      // Obter token atual e armazená-lo localmente, mas sem tentar salvá-lo
      // no Supabase ainda (isso será feito em saveLocalTokenAfterLogin)
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenLocally(token);
        print("Token inicial obtido e armazenado localmente: $token");
      }

      _isInitialized = true;
    } catch (e) {
      print("Erro ao inicializar NotificationService: $e");
      throw e;
    }
  }

  // Método centralizado para configurar o token do usuário
  static Future<void> setupUserToken([String? newToken]) async {
    try {
      // Obter o token FCM (novo ou atual)
      final fcmToken = newToken ?? await _firebaseMessaging.getToken();

      if (fcmToken == null) {
        print("Falha ao obter token FCM");
        return;
      }

      // Sempre salvar localmente o token atual
      await _saveTokenLocally(fcmToken);

      // Verificar se o usuário está autenticado antes de tentar salvar no Supabase
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Remover tokens anteriores
        await _removeExistingTokens(fcmToken);

        // Salvar novo token
        await _saveTokenToSupabase(fcmToken);

        print('FCM Token configurado para usuário autenticado: $fcmToken');
      } else {
        print("Usuário não autenticado. Token armazenado localmente: $fcmToken");
      }
    } catch (e) {
      print("Erro ao configurar token: $e");
    }
  }

  // Método para remover tokens existentes do usuário
  static Future<void> _removeExistingTokens(String currentToken) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        // Remover tokens antigos do mesmo dispositivo
        await _supabase
            .from('device_tokens')
            .delete()
            .eq('token', currentToken);

        // Remover outros tokens associados ao mesmo usuário e dispositivo
        await _supabase
            .from('device_tokens')
            .delete()
            .eq('user_id', user.id)
            .eq('device_type', _getDeviceType());

        print("Tokens antigos removidos com sucesso");
      } catch (e) {
        print("Erro ao remover tokens existentes: $e");
      }
    }
  }

  // Método para salvar o token no Supabase
  static Future<void> _saveTokenToSupabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('device_tokens').insert({
          'user_id': user.id,
          'token': token,
          'device_type': _getDeviceType(), // Detectar tipo de dispositivo
          'created_at': DateTime.now().toIso8601String(),
        });
        print("Token salvo no Supabase: $token");
      } catch (e) {
        print("Erro ao salvar token no Supabase: $e");
      }
    } else {
      print("Usuário não autenticado. Token não salvo no Supabase.");
    }
  }

  // Método para determinar o tipo de dispositivo
  static String _getDeviceType() {
    // TODO: Implementar detecção dinâmica de plataforma
    // Você pode usar pacotes como 'device_info_plus' para detecção precisa
    return 'android'; // ou 'ios'
  }

  // Método para salvar o token localmente (usando SharedPreferences)
  static Future<void> _saveTokenLocally(String? token) async {
    if (token != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      print("Token armazenado localmente: $token");
    }
  }

  // Método para obter o token armazenado localmente
  static Future<String?> getLocalToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Método para salvar o token local no Supabase após o login
  static Future<void> saveLocalTokenAfterLogin() async {
    try {
      // Verificar se o usuário está realmente autenticado
      final user = _supabase.auth.currentUser;
      if (user == null) {
        print("Tentativa de salvar token após login, mas usuário não está autenticado.");
        return;
      }

      // Com o usuário autenticado, obter o token atual (prefira um novo token em vez do armazenado)
      String? fcmToken;

      // Tente obter um novo token
      try {
        fcmToken = await _firebaseMessaging.getToken();
      } catch (e) {
        print("Erro ao obter novo token FCM: $e");
        // Fallback para o token armazenado localmente
        fcmToken = await getLocalToken();
      }

      if (fcmToken == null) {
        print("Não foi possível obter um token FCM válido para salvar após login");
        return;
      }

      // Garantir que o token seja atualizado localmente
      await _saveTokenLocally(fcmToken);

      // Remova tokens existentes deste usuário
      await _removeExistingTokens(fcmToken);

      // Salve o token no Supabase
      await _saveTokenToSupabase(fcmToken);

      print("Token salvo no Supabase após login: $fcmToken");
    } catch (e) {
      print("Erro ao salvar token após login: $e");
    }
  }

  // Método para remover todos os tokens do usuário atual durante o logout
  static Future<void> removeUserTokens() async {
    try {
      // Obter o token atual
      final currentToken = await getLocalToken();

      // Remover o token do SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      print("Token removido localmente durante logout");

      // Remover token do Supabase se o usuário estiver autenticado e tiver token
      final user = _supabase.auth.currentUser;
      if (user != null && currentToken != null) {
        // Remover apenas o token atual do dispositivo
        await _supabase
            .from('device_tokens')
            .delete()
            .eq('token', currentToken);

        print("Token removido do Supabase durante logout");
      }
    } catch (e) {
      print("Erro ao remover token durante logout: $e");
    }
  }
}