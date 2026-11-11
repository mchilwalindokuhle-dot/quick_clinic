import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const QuickClinicApp(),
    ),
  );
}

class QuickClinicApp extends StatelessWidget {
  const QuickClinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'QuickClinic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
