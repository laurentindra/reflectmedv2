import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/network/resilient_http_overrides.dart';
import 'core/theme/app_theme.dart';
import 'screens/main_navigation_scaffold.dart';
import 'screens/onboarding_welcome_screen.dart';
import 'screens/login_auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = ResilientHttpOverrides();
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {}
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ReflectMedApp());
}

class ReflectMedApp extends StatelessWidget {
  const ReflectMedApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReflectMed AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (context) => const MainNavigationScaffold(),
        '/onboarding': (context) => const OnboardingWelcomeScreen(),
        '/login': (context) => const LoginAuthScreen(),
      },
    );
  }
}
