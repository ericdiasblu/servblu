import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Para armazenar o token temporariamente

// Esta função será chamada em segundo plano quando uma notificação chegar
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
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

      // Obter token FCM
      final fcmToken = await _firebaseMessaging.getToken();

      // Salvar token no Supabase se o usuário estiver autenticado
      final user = _supabase.auth.currentUser;
      if (user != null && fcmToken != null) {
        await _saveTokenToSupabase(fcmToken);
        print('FCM Token: $fcmToken');
      } else {
        // Armazenar o token temporariamente se o usuário não estiver autenticado
        await _saveTokenLocally(fcmToken);
        print("Usuário não autenticado. Token armazenado localmente.");
      }

      // Atualizar token quando for atualizado
      _firebaseMessaging.onTokenRefresh.listen((newToken) async {
        final user = _supabase.auth.currentUser;
        if (user != null) {
          await _saveTokenToSupabase(newToken);
          print("Token FCM atualizado: $newToken");
        } else {
          // Armazenar o novo token temporariamente
          await _saveTokenLocally(newToken);
          print("Usuário não autenticado. Token atualizado armazenado localmente.");
        }
      });
    } catch (e) {
      print("Erro ao inicializar NotificationService: $e");
      throw e;
    }
  }

  // Método para salvar o token no Supabase
  static Future<void> _saveTokenToSupabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      // Presumindo que você tem uma tabela 'device_tokens' no Supabase
      await _supabase.from('device_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'device_type': 'android', // ou 'ios', você pode detectar isso programaticamente
        'created_at': DateTime.now().toIso8601String(),
      });
      print("Token salvo no Supabase: $token");
    } else {
      print("Usuário não autenticado. Token não salvo no Supabase.");
    }
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
    final token = prefs.getString('fcm_token');

    if (token != null) {
      await _saveTokenToSupabase(token);
      await prefs.remove('fcm_token'); // Remove o token local após salvar no Supabase
      print("Token local salvo no Supabase após login.");
    }
  }

  // Método para remover o token ao fazer logout
  static Future<void> removeTokenOnLogout() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _supabase
            .from('device_tokens')
            .delete()
            .match({'user_id': user.id, 'token': token});
        print("Token removido do Supabase após logout.");
      }
    }
  }
}