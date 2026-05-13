import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'data/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Sign in anonymously
  await AuthService().signInAnonymously();

  // Initialize push notifications
  await NotificationService().init();
  await NotificationService().subscribeToTopic('ghana_posts');

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(const AdepaApp());
}

class AdepaApp extends StatelessWidget {
  const AdepaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adepa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AdepaColors.bg,
        colorScheme: const ColorScheme.dark(
          primary: AdepaColors.ghGold,
          secondary: AdepaColors.ghGreen,
          surface: AdepaColors.bg2,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
