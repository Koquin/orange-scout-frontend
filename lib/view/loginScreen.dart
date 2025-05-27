import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:OrangeScoutFE/util/token_utils.dart';
import 'registerScreen.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String? baseUrl = dotenv.env['API_BASE_URL'];

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Log de visualização de tela quando o usuário ENTRA nesta tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalytics.instance.logScreenView(
        screenName: 'LoginScreen',
        screenClass: 'LoginScreenState',
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    setState(() {
      _isLoading = true;
    });

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      setState(() {
        _isLoading = false;
      });
      // Log de tentativa de login falha (campos vazios)
      FirebaseAnalytics.instance.logEvent(
        name: 'login_attempt',
        parameters: {
          'status': 'failed',
          'reason': 'empty_fields',
          'email_provided': email.isNotEmpty,
          'password_provided': password.isNotEmpty,
        },
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/auth/login"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        String? token = responseData['token'];
        if (token == null || token.isEmpty) {
          throw Exception("Token not found in response");
        }
        saveToken(token);
        Navigator.pushReplacementNamed(context, '/main');

        // Log de login bem-sucedido
        FirebaseAnalytics.instance.logEvent(
          name: 'login_attempt',
          parameters: {
            'status': 'success',
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials')),
        );
        // Log de tentativa de login falha (credenciais inválidas)
        FirebaseAnalytics.instance.logEvent(
          name: 'login_attempt',
          parameters: {
            'status': 'failed',
            'reason': 'invalid_credentials',
            'http_status_code': response.statusCode,
          },
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error connecting to the server: ${e.toString()}')),
      );
      // Log de tentativa de login falha (erro de conexão)
      FirebaseAnalytics.instance.logEvent(
        name: 'login_attempt',
        parameters: {
          'status': 'failed',
          'reason': 'connection_error',
          'error_details': e.toString(),
        },
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
        backgroundColor: const Color(0xFFFF9800),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 5,
      ),
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.white)
          : Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return Scaffold(
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
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
              Image.asset('assets/images/OrangeScoutLogo.png'),
              const SizedBox(height: 40),
              SizedBox(
                height: 40,
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF57C00),
                    hintText: "Email",
                    hintStyle: const TextStyle(color: Color(0xFFFFCC80)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                width: MediaQuery.of(context).size.width * 0.8,
                child: TextField(
                  controller: _passwordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF57C00),
                    hintText: "Password",
                    hintStyle: const TextStyle(color: Color(0xFFFFCC80)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              customButton(
                text: "Login",
                onPressed: _isLoading ? () {} : _login,
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  // Log de clique no link para registro
                  FirebaseAnalytics.instance.logEvent(
                    name: 'navigate_to_register_clicked',
                  );
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: const Text(
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
