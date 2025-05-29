import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import 'package:OrangeScoutFE/controller/authController.dart';
import 'package:OrangeScoutFE/view/registerScreen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
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

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all fields')),
        );
      }
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

    setState(() {
      _isLoading = true;
    });

    final LoginResult result = await _authController.loginUser(email, password);

    if (mounted) {
      if (result.success) {
        Navigator.pushReplacementNamed(context, '/main');

        FirebaseAnalytics.instance.logEvent(
          name: 'login_attempt',
          parameters: {
            'status': 'success',
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'Unknown login error')),
        );
        FirebaseAnalytics.instance.logEvent(
          name: 'login_attempt',
          parameters: {
            'status': 'failed',
            'reason': result.errorMessage ?? 'unknown_reason',
          },
        );
      }
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

    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;
    final contentHeight = screenHeight - keyboardSpace;

    return Scaffold(
      body: Container(
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.only(bottom: keyboardSpace),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: contentHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: screenHeight * 0.1),
                    child: Image.asset(
                      'assets/images/OrangeScoutLogo.png',
                      width: MediaQuery.of(context).size.width * 0.6,
                      height: MediaQuery.of(context).size.width * 0.6 * (250 / 410),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 50,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF57C00).withOpacity(0.7),
                        hintText: "Email",
                        hintStyle: const TextStyle(color: Color(0xFFFFCC80)),
                        labelText: "Email Address",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.email, color: Color(0xFFFFCC80)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  SizedBox(
                    height: 50,
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: TextField(
                      controller: _passwordController,
                      style: const TextStyle(color: Colors.white),
                      obscureText: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF57C00).withOpacity(0.7),
                        hintText: "Password",
                        hintStyle: const TextStyle(color: Color(0xFFFFCC80)),
                        labelText: "Password",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock, color: Color(0xFFFFCC80)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  customButton(
                    text: "Login",
                    onPressed: _isLoading ? () {} : _login,
                  ),
                  const SizedBox(height: 25),
                  GestureDetector(
                    onTap: () {
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
                        color: Colors.blueAccent,
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
