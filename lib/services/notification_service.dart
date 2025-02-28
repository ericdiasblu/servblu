import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Esta função será chamada em segundo plano quando uma notificação chegar
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Não inicialize o Firebase aqui novamente
  print("Mensagem recebida em segundo plano: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static final SupabaseClient _supabase = Supabase.instance.client;

  // Este método não tenta inicializar o Firebase
  static Future<void> initializeWithoutFirebase() async {
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
        // Aqui você pode lidar com as ações quando o usuário toca na notificação
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
      // Aqui você pode navegar para uma tela específica com base nos dados da notificação
    });

    // Obter token FCM
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');

    // Salvar token no Supabase para uso posterior
    if (fcmToken != null) {
      await _saveTokenToSupabase(fcmToken);
    }

    // Atualizar token quando for atualizado
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToSupabase);
  }

  // Mantemos o método original para compatibilidade
  static Future<void> initialize() async {
    try {
      Firebase.app();
      print("Firebase já inicializado");
    } catch (e) {
      await Firebase.initializeApp();
      print("Firebase inicializado");
    }

    // Reusa o método que não inicializa o Firebase
    await initializeWithoutFirebase();
  }

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
    }
  }

  // Método para se inscrever em tópicos específicos
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Método para cancelar inscrição em tópicos
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }
}