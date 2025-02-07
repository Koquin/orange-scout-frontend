import 'package:flutter/material.dart';

class MatchDetailView extends StatelessWidget {
  final Map<String, dynamic> match;

  MatchDetailView({required this.match});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${match['team1']} vs ${match['team2']}')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${match['score']}'),
            // vou criar os detalhes do jogo
        ),
      ),
    );
  }
}
