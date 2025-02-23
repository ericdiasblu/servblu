/*
enviarNotificacao(Notificacao notificacao)
Descrição: Cria e envia uma notificação para um usuário (sobre agendamentos,
pagamentos, feedback, etc.).

listarNotificacoes(int idUsuario)
Descrição: Retorna a lista de notificações associadas a um usuário.

marcarComoLida(int idNotificacao)
Descrição: Atualiza o status da notificação para indicar que ela já foi visualizada.
*/

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotiService {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // INITIALIZE
  Future<void> initNotifications() async {
    if (_isInitialized) return;

    // Android
    const initSettingsAndroid =
    AndroidInitializationSettings("@mipmap/ic_launcher");

    // iOS
    const initSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Init settings
    const initSettings = InitializationSettings(
      android: initSettingsAndroid,
      iOS: initSettingsIOS,
    );

    // Initialize the plugin
    await notificationsPlugin.initialize(initSettings);
    _isInitialized = true; // Marcar como inicializado
  }

  // NOTIFICATION DETAIL SETUP
  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        "daily_channel_id",
        'Daily Notifications',
        channelDescription: 'Daily Notification Channel',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
  }

  // SHOW NOTIFICATION
  Future<void> showNotification({
    int id = 0,
    String? title,
    String? body,
  }) async {
    await notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails(), // Use a função para obter os detalhes
    );
  }
}
