import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class VerificationScreen extends StatefulWidget {
  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final TextEditingController _codeController = TextEditingController();

  Future<void> validateCode() async {
    final response = await http.post(
      Uri.parse('http://localhost:8080/user/validate'),
      body: {'code': _codeController.text},
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Code validated!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid code!')),
      );
    }
  }

  Future<void> sendVerificationCode() async {
    await http.post(Uri.parse('http://localhost:8080/user/sendValidationCode'));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Code sent!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/images/OrangeScoutLogo-cutout-cutout.png'), // Ajuste para sua imagem
              SizedBox(
                height: 40,
              ),
              SizedBox(
                height: 40,
                width: 500,
                child: TextField(
                  controller: _codeController,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFF57C00),
                    hintText: "Validation code",
                    hintStyle: TextStyle(color: Color(0xFFFFCC80)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 15),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: validateCode,
                child: Text('Validate'),
              ),
              SizedBox(height: 15),
              TextButton(
                onPressed: sendVerificationCode,
                child: Text('Send verification code', style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
