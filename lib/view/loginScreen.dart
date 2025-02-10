import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'registerScreen.dart'; // Importa a tela de registro

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final Uri url = Uri.parse('http://localhost:8080/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String token = responseData['token'];

        // Armazena o token no SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);

        // Redireciona para a tela principal
        Navigator.pushReplacementNamed(context, '/main');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid credentials')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to the server')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Widget customButton({required String text, required VoidCallback onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFFF9800),
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 5,
      ),
      child: _isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/OrangeScoutLogo-cutout.png'),
              SizedBox(height: 40), // Reduzido para aproximar a imagem dos campos
              SizedBox(
                height: 40, // Define a altura do campo
                width: 500,
                child: TextField(
                  controller: _emailController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFF57C00),
                    hintText: "Email",
                    hintStyle: TextStyle(color: Color(0xFFFFCC80)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  ),
                ),
              ),
              SizedBox(height: 10), // Espaço entre os campos
              SizedBox(
                height: 40, // Define a altura do campo
                width: 500,
                child: TextField(
                  controller: _passwordController,
                  style: TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFF57C00),
                    hintText: "Password",
                    hintStyle: TextStyle(color: Color(0xFFFFCC80)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  ),
                ),
              ),

              SizedBox(height: 20),
              customButton(
                text: "Login",
                onPressed: _isLoading ? () {} : _login,
              ),
              SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: Text(
                  "I don't have an account",
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
