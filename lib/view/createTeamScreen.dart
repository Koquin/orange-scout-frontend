import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../util/token_utils.dart';

class CreateTeamScreen extends StatefulWidget {

  @override
  _CreateTeamScreenState createState() => _CreateTeamScreenState();

  final int? teamId;

  const CreateTeamScreen({
    super.key,
    required this.teamId,
  });
}

class _CreateTeamScreenState extends State<CreateTeamScreen> {
  //Base url
  String? baseUrl = dotenv.env['API_BASE_URL'];

  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController();
  final _abbreviationController = TextEditingController();

  String? logoPath;
  File? selectedImage;
  final String fallbackImage = 'assets/images/TeamShieldIcon-cutout.png';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        logoPath = pickedFile.path;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final teamName = _teamNameController.text.trim();
    final abbreviation = _abbreviationController.text.trim();

    if (logoPath == null || logoPath!.isEmpty) {
      logoPath = fallbackImage;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No valid image found, using default.")),
      );
    }

    String? token = await loadToken();

    final teamData = {
      "id": widget.teamId,
      "teamName": teamName,
      "abbreviation": abbreviation,
      "logoPath": logoPath,
    };

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/team"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(teamData),
      );

      if (response.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating team: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unknown error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFFFF4500),
              Color(0xFF84442E),
              Colors.black,
            ],
            stops: [0.0, 0.5, 0.9],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _teamNameController,
                        decoration: InputDecoration(
                          labelText: "Team Name",
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.orange),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        maxLength: 30,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Team name is required";
                          }
                          if (value.trim().length > 30) {
                            return "Limit is 30 characters";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _abbreviationController,
                        decoration: InputDecoration(
                          labelText: "Abbreviation",
                          labelStyle: const TextStyle(color: Colors.white),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.orange),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        maxLength: 3,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return "Abbreviation is required";
                          }
                          if (value.trim().length > 3) {
                            return "Limit is 3 characters";
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white70),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: selectedImage != null
                        ? Image.file(selectedImage!, fit: BoxFit.cover)
                        : Image.asset(fallbackImage, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Finish"),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white54),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: IconButton(
                        onPressed: _pickImage,
                        icon: Image.asset('assets/images/UploadImageIcon.png', width: 40, height: 40),
                        tooltip: "Pick shield image",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
