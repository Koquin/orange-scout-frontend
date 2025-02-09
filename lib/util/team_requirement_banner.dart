import 'package:flutter/material.dart';

class TeamRequirementBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.orange,
      padding: EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'You need at least two teams to start.',
            style: TextStyle(color: Colors.white),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/createTeam');
            },
            child: Text('Creat team', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
