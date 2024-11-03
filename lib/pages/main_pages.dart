import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:salespro/auth/auth_page.dart';
import 'package:salespro/pages/home_page.dart';

class MainPages extends StatelessWidget {
  MainPages({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // if (snapshot.hasData) {
          //   return HomePage();
          // } else {
          //   return AuthPage();
          // }

          if (snapshot.data == null) {
            return const AuthPage();
          } else {
            return const HomePage();
          }
        },
      ),
    );
  }
}
