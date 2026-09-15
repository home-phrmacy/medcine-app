import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'main_nav_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'services/notification_service.dart';

// متغير عام للتحكم باللغة من أي مكان (افتراضياً إنجليزي)
final ValueNotifier<Locale> appLocaleNotifier = ValueNotifier(const Locale('en'));

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await NotificationService().init();

  await Supabase.initialize(
    url: 'https://hwnkztyzbdzbxmryeciv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh3bmt6dHl6YmR6YnhtcnllY2l2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg4NzcyNzAsImV4cCI6MjEwNDQ1MzI3MH0.MTTXIqtGfcSuFiI4oJ6HYYHckcuVsf_cmQt6loW-aKc',
  );

  runApp(const HomePharmacyApp());
}

class HomePharmacyApp extends StatelessWidget {
  const HomePharmacyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocaleNotifier,
      builder: (context, currentLocale, child) {
        return MaterialApp(
          title: 'Home Pharmacy',
          debugShowCheckedModeBanner: false,
          locale: currentLocale,
          supportedLocales: const [
            Locale('en'),
            Locale('ar'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFF9F1ED),
            fontFamily: 'SF Pro Display',
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE57373),
              primary: const Color(0xFFE57373),
            ),
          ),
          home: const AuthScreen(),
        );
      },
    );
  }
}
