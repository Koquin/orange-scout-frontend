import 'package:flutter/material.dart';
import '../controllers/team_controller.dart';
import '../models/team.dart';

class AddTeamScreen extends StatelessWidget {
  final TeamController controller;
  final TextEditingController nameController = TextEditingController();

  AddTeamScreen({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Adicionar Time')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Nome do Time'),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                controller.addTeam(Team(name: nameController.text));
                Navigator.pop(context);
              },
              child: Text('Adicionar'),
            )
          ],
        ),
      ),
    );
  }
}