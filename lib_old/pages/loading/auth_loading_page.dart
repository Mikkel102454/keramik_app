import 'package:flutter/material.dart';

import '../../network/account.dart';
import '../HomePage.dart';
import '../todo/login_page.dart';

class AuthCheckPage extends StatelessWidget {
  const AuthCheckPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: fetchUserMe(),
      builder: (context, snapshot) {

        // While waiting for response
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If error happened
        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text(
                'Connection error',
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }

        if (snapshot.data == true) {
          return const HomePage();
        }

        return const LoginPage();
      },
    );
  }
}