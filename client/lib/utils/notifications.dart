import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  final AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  // TODO darwin setup may require tweaking - https://pub.dev/packages/flutter_local_notifications#-ios-setup
  final DarwinInitializationSettings initializationSettingsDarwin =
      DarwinInitializationSettings();

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsDarwin,
    macOS: initializationSettingsDarwin,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<bool> requestNotificationPermissions() async {
  final status = await Permission.notification.request();
  return status.isGranted;
}
