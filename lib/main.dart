// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sip_demo/screens/home_screen.dart';
import 'package:flutter_sip_demo/screens/login_screen.dart';
import 'package:flutter_sip_demo/providers/auth_provider.dart';
import 'package:flutter_sip_demo/providers/sip_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SipProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase SIP App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return authProvider.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}
