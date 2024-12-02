import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:salespro/pages/items.dart';
import 'package:salespro/login.dart';
import 'package:salespro/pages/items_page.dart';
import 'package:salespro/pages/main_pages.dart';
import 'package:flutter/material.dart';
import 'package:salespro/pages/home_page.dart';
import 'package:salespro/pages/receipts_page.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase based on the platform (web or non-web)
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAsDeWrBwoRggxkNhluCAeOwxEkuFFw1aI",
        authDomain: "salespro-9a9f4.firebaseapp.com",
        projectId: "salespro-9a9f4",
        storageBucket: "salespro-9a9f4.appspot.com",
        messagingSenderId: "295840565054",
        appId: "1:295840565054:web:e67d4981d3253909a1ce6f",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  runApp(
    ChangeNotifierProvider(
      create: (ctx) => CartProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainPages(),
      routes: {
        // Routes for navigation
        '/login': (context) => LoginPage(
              showRegisterPage: () {},
            ),
        '/salespage': (context) =>  const HomePage(),
        '/receiptpage': (context) => const ReceiptsPage(
              receipts: [],
            ),
        '/itemspage': (context) => const ItemsPage(),
        '/items': (context) => Items(
              updateCategories: (List<String> newCategories) {},
            ),
      },
    );
  }
}