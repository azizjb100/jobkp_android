import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // [PERBAIKAN 1]
    // Ganti 'ic_launcher' menjadi 'ic_notification'.
    // Ini adalah nama file baru yang baru saja Anda buat di folder 'drawable'.
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification'); // <-- DIUBAH DI SINI

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(initializationSettings);

    // Minta Izin Notifikasi (Untuk Android 13+)
    final bool? result = await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    print("Izin Notifikasi Diberikan: $result");
  }

  Future<void> showNotification(int id, String title, String body) async {
    // [PERBAIKAN 2]
    // Tentukan 'smallIcon' di sini juga menggunakan nama baru
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'jobkp_channel_id',
      'JobKP Notifications',
      channelDescription: 'Notifikasi untuk status pekerjaan JobKP',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'ic_notification', // <-- TAMBAHKAN/UBAH BARIS INI
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    print("Mencoba menampilkan notifikasi: $title");
    await _notificationsPlugin.show(id, title, body, notificationDetails);
    print("Perintah showNotification selesai.");
  }
}
