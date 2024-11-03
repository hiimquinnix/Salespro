import 'package:flutter/material.dart';
import 'package:salespro/login.dart';
import 'package:salespro/register_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLoginPage = true;
  // para saan pala to bat may toggle ka? nakita ko sa yt na auth ah so meaning sa unang page papapiliin mo kung sign in orregister? opo kasi need siya may reg acc ah okay bat di nalng natin gawin is login page na agad? tas pag walang acc pa may button dun sa baba na regiyser? hhm ganon na po actually yung design niya ah okay okayy so ang problem is dapat di na babalik once na logo ut na? opo para direct logout sa firebase
  void toggleScreens() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(showRegisterPage: toggleScreens);
    } else {
      return RegisterPage(showLoginPage: toggleScreens);
    }
  }
}
