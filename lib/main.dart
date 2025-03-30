import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'features/auth/screens/login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LokaTrack',
      theme: ThemeData(
        primaryColor: const Color(0xFF306424),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF306424),
          primary: const Color(0xFF306424),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
