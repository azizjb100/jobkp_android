import 'package:flutter/material.dart';
import 'package:jobkp_flutter/pages/login_page.dart';
import 'package:jobkp_flutter/pages/menu_page.dart';
import 'package:jobkp_flutter/services/notification_service.dart';

final NotificationService notificationService = NotificationService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await notificationService.init();
    print("Notification Service Berhasil Diinisialisasi.");
  } catch (e) {
    print("GAGAL Inisialisasi Notifikasi: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JobKP Flutter',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.light(
          primary: Colors.blue[700]!,
          onPrimary: Colors.white,
          secondary: Colors.blueAccent,
          onSecondary: Colors.white,
          background: Colors.grey[100]!,
          onBackground: Colors.black,
          surface: Colors.white,
          onSurface: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue[700]!,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700]!,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      initialRoute: '/login',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());
          case '/menu':
            return MaterialPageRoute(builder: (_) => const MenuPage());
          default:
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                body: Center(
                  child: Text(
                      'Halaman tidak ditemukan untuk rute: ${settings.name}'),
                ),
              ),
            );
        }
      },
    );
  }
}
