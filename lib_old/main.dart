import 'package:flutter/material.dart';
import 'package:kemik_app/pages/loading/auth_loading_page.dart';
import 'api/api_client.dart';
import 'pages/HomePage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ApiClient.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212), // slightly lighter black
          foregroundColor: Colors.white,      // text + icons
        ),

        colorScheme: ColorScheme.dark(
          background: Colors.black,
          primary: Colors.white,
        ),
      ),
      home: const AuthCheckPage()
    );
  }
}