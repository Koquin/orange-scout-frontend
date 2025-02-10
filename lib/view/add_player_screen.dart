import 'package:flutter/material.dart';

class AddPlayerScreen extends StatefulWidget {
  @override
  _AddPlayerScreenState createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final TextEditingController numberController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  List<Map<String, String>> players = [
    {'number': '15', 'name': 'Player 1'},
    {'number': '32', 'name': 'Player 2'},
    {'number': '74', 'name': 'Player 3'},
    {'number': '99', 'name': 'Player 4'},
    {'number': '3', 'name': 'Player 5'},
  ];

  void addPlayer() {
    if (numberController.text.isNotEmpty && nameController.text.isNotEmpty) {
      setState(() {
        players.add({
          'number': numberController.text,
          'name': nameController.text,
        });
        numberController.clear();
        nameController.clear();
      });
    }
  }

  void deletePlayer(int index) {
    setState(() {
      players.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Add Player'),
        backgroundColor: Colors.orange,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    "${players[index]['number']} - ${players[index]['name']}",
                    style: TextStyle(color: Colors.white),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red),
                        onPressed: () => deletePlayer(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: numberController,
                    decoration: InputDecoration(
                      hintText: 'Number',
                      hintStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'Player Name',
                      hintStyle: TextStyle(color: Colors.white),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(),
                    ),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.check, color: Colors.green),
                  onPressed: addPlayer,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.grey[900],
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.arrow_back), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: ''),
        ],
      ),
    );
  }
}
