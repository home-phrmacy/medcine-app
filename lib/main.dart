import 'package:flutter/material.dart';
import 'package:phrm_app/main_nav_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();

  await Supabase.initialize(
    url: 'https://hwnkztyzbdzbxmryeciv.supabase.co',
    anonKey: 'sb_publishable_8knxRVtX66tiq19fZIgjIw_4CvYLXNJ',
  );

  runApp(const HomePharmacyApp());
}

class HomePharmacyApp extends StatelessWidget {
  const HomePharmacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home Pharmacy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF9F1ED),
        fontFamily: 'SF Pro Display',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE57373),
          primary: const Color(0xFFE57373),
        ),
      ),
      home: const MainNavScreen(),
    );
  }
}
