import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          width: double.infinity,  // Ocupa toda a largura
          height: double.infinity, // Ocupa toda a altura
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0,
              colors: [
                Color(0xFFFF4500),
                Color(0xFF84442E),
                Color(0xFF3A2E2E),
              ],
              stops: [0.0, 0.2, 0.7],
            ),
          ),
        child: Column(
          children: [
            Image.asset('assets/images/OrangeScoutLogo-cutout.png'),
            TextField(

            )
          ],
        )
      )
    );
  }
}
