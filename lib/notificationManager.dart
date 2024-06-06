import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'main.dart';

class NotificationManager {
// Initialize and show notification
  static Future<void> showNotification() async {
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      '1',
      'Price Changes',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    var platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);
    await MyHomePage.flutterLocalNotificationsPlugin.show(
      0,
      'Price Changed!',
      'Check your items for updated prices.',
      platformChannelSpecifics,
      payload: 'Price Change',
    );
  }
}