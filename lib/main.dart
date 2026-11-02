import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_config.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? problem;
  if (AppConfig.firebaseOptions.apiKey.startsWith('PASTE')) {
    problem = 'Firebase is not set up yet.\n\n'
        'Open lib/firebase_config.dart and paste your Firebase values '
        '(see README.md, Part A).';
  } else {
    try {
      await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    } catch (e) {
      problem = 'Could not start Firebase:\n\n$e';
    }
  }
  runApp(problem == null ? const KareHelpDeskApp() : SetupProblemApp(problem));
}

class SetupProblemApp extends StatelessWidget {
  final String message;
  const SetupProblemApp(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}

class KareHelpDeskApp extends StatelessWidget {
  const KareHelpDeskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KARE Help Desk',
      debugShowCheckedModeBanner: false,
      theme: kareTheme(),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snap.data == null ? const LoginScreen() : const HomeScreen();
        },
      ),
    );
  }
}
