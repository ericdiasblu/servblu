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

  // Método para inicializar o serviço de notificações
  static Future<void> initialize() async {
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

      // Configurar token inicial
      await setupUserToken();

      // Atualizar token quando for atualizado
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        await setupUserToken(newToken);
      });
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

      // Verificar se o usuário está autenticado
      final user = _supabase.auth.currentUser;
      if (user != null && fcmToken != null) {
        // Remover tokens anteriores
        await _removeExistingUserTokens(user.id);

        // Salvar novo token
        await _saveTokenToSupabase(fcmToken);
        print('FCM Token configurado para usuário autenticado: $fcmToken');
      } else if (fcmToken != null) {
        // Armazenar o token temporariamente se o usuário não estiver autenticado
        await _saveTokenLocally(fcmToken);
        print("Usuário não autenticado. Token armazenado localmente: $fcmToken");
      }
    } catch (e) {
      print("Erro ao configurar token: $e");
    }
  }

  // Método para remover tokens existentes do usuário
  static Future<void> _removeExistingUserTokens(String userId) async {
    try {
      await _supabase
          .from('device_tokens')
          .delete()
          .eq('user_id', userId);
      print("Tokens anteriores do usuário removidos");
    } catch (e) {
      print("Erro ao remover tokens anteriores: $e");
    }
  }

  // Método para salvar o token no Supabase
  static Future<void> _saveTokenToSupabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('device_tokens').insert({
        'user_id': user.id,
        'token': token,
        'device_type': _getDeviceType(), // Detectar tipo de dispositivo
        'created_at': DateTime.now().toIso8601String(),
      });
      print("Token salvo no Supabase: $token");
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
      await prefs.setString('fcm_token', token);
      print("Token armazenado localmente: $token");
    }
  }

  // Método para salvar o token local no Supabase após o login
  static Future<void> saveLocalTokenAfterLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      // Verificar se o usuário está autenticado
      final user = _supabase.auth.currentUser;
      if (user != null) {
        try {
          // Remover tokens anteriores do usuário
          await _removeExistingUserTokens(user.id);

          // Salvar novo token
          await _saveTokenToSupabase(token);

          // Remove o token local após salvar no Supabase
          await prefs.remove('token');

          print("Token local salvo no Supabase após login.");
        } catch (e) {
          print("Erro ao salvar token local após login: $e");
        }
      } else {
        print("Usuário não autenticado. Não foi possível salvar o token.");
      }
    }
  }

  // Método para remover o token ao fazer logout
  static Future<void> removeTokenOnLogout() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      // Remove todos os tokens do usuário
      await _removeExistingUserTokens(user.id);
      print("Todos os tokens do usuário removidos após logout.");
    }
  }
}