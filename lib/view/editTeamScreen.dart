import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../util/token_utils.dart';
import 'createTeamScreen.dart';

class EditTeamScreen extends StatefulWidget {
  final int teamId;

  const EditTeamScreen({super.key, required this.teamId});

  @override
  State<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends State<EditTeamScreen> {
  //Base url
  String? baseUrl = dotenv.env['API_BASE_URL'];

  List<Map<String, dynamic>> players = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPlayers();
  }

  Future<void> fetchPlayers() async {
    setState(() => isLoading = true);
    try {
      String? token = await loadToken();
      final response = await http.get(
        Uri.parse("$baseUrl/player/team-players/${widget.teamId}"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> playerList = json.decode(response.body);
        players = playerList.map((p) => Map<String, dynamic>.from(p)).toList();
      }
    } catch (e) {
      print("Error fetching players: $e");
    }
    setState(() => isLoading = false);
  }

  void addNewPlayerRow() {
    setState(() {
      players.add({'playerName': '', 'jerseyNumber': '', 'isNew': true});
    });
  }

  Future<void> confirmNewPlayer(int index, String name, String number) async {
    String? token = await loadToken();
    if (name.isEmpty || number.isEmpty) return;

    try {
      final response = await http.post(
        Uri.parse("$baseUrl/player/${widget.teamId}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: json.encode({
          'playerName': name,
          'jerseyNumber': number,
          'team': {'id': widget.teamId},
        }),
      );
      print("Requisição: ${response.body}");
      if (response.statusCode == 201) {
        await fetchPlayers();
      }
    } catch (e) {
      print("Error adding player: $e");
    }
  }

  Future<void> deletePlayer(int index) async {
    final id = players[index]['id_player'];
    try {
      String? token = await loadToken();
      final response = await http.delete(
        Uri.parse("$baseUrl/player/$id"),
        headers: {
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        await fetchPlayers();
      }
    } catch (e) {
      print("Error deleting player: $e");
    }
  }

  Future<void> editPlayer(int index) async {
    String? token = await loadToken();
    final player = players[index];
    print("Player: ${player}");
    try {
      final response = await http.put(
        Uri.parse("$baseUrl/player/${player['id_player']}"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: json.encode({
          'playerName': player['playerName'],
          'jerseyNumber': player['jerseyNumber'],
        }),
      );
      print("Requisição: ${response.body}");
      if (response.statusCode == 200) {
        await fetchPlayers();
      }
    } catch (e) {
      print("Error editing player: $e");
    }
  }

  void showEditDialog(int index) {
    final player = players[index];
    final TextEditingController nameController = TextEditingController(text: player['playerName']);
    final TextEditingController numberController = TextEditingController(text: player['jerseyNumber'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text("Edit Player", style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Number"),
                style: const TextStyle(color: Colors.white),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Cancel", style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Save", style: TextStyle(color: Colors.green)),
              onPressed: () {
                setState(() {
                  players[index]['playerName'] = nameController.text;
                  players[index]['jerseyNumber'] = numberController.text;
                });
                Navigator.of(context).pop();
                editPlayer(index);
              },
            ),
          ],
        );
      },
    );
  }

  Widget buildPlayerRow(Map<String, dynamic> player, int index) {
    if (player['isNew'] == true) {
      TextEditingController nameController = TextEditingController(text: player['playerName']);
      TextEditingController numberController = TextEditingController(text: player['jerseyNumber']);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.6)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          title: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: numberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: "Nº",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: "Name",
                    hintStyle: TextStyle(color: Colors.white54),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () {
                  if (!(nameController.text.isEmpty || numberController.text.isEmpty)) {
                    confirmNewPlayer(index, nameController.text, numberController.text);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please fill both boxes"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: SizedBox(
          height: 30,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "${player['jerseyNumber']}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Text(
                  "${player['playerName']}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              showEditDialog(index);
            } else if (value == 'delete') {
              deletePlayer(index);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text("Edit Player")),
            const PopupMenuItem(value: 'delete', child: Text("Delete Player")),
          ],
          icon: const Icon(Icons.more_vert, color: Colors.white),
        ),
      ),
    );
  }

  Widget buildNewPlayerButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: TextButton(
          onPressed: addNewPlayerRow,
          child: const Text("New player", style: TextStyle(color: Colors.orange)),
        ),
      ),
    );
  }

  Future<void> _deleteTeam() async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this team? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == null || !confirmDelete) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    String? token = await loadToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Token not found.')),
        );
      }
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/team/${widget.teamId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (mounted) {
        if (response.statusCode == 204) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Team deleted successfully!')),
          );
          Navigator.pop(context, true);
        } else {
          String errorMessage = 'Failed to delete team: ${response.statusCode}';
          if (response.body.isNotEmpty) {
            print('Server response: ${response.body}');
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection error: $e')),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Row( // <-- This Row is necessary to put two IconButtons side-by-side
                mainAxisSize: MainAxisSize.min, // Keep the row compact
                children: [
                  // Existing Edit Team button
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white, size: 28),
                    tooltip: 'Edit Team',
                    onPressed: isLoading ? null : () { // Disable if loading
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CreateTeamScreen(teamId: widget.teamId),
                        ),
                      );
                    },
                  ),
                  // New Delete Team button
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white, size: 28),
                    tooltip: 'Delete Team',
                    onPressed: isLoading ? null : _deleteTeam, // Disable if loading
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: players.length + 1,
                itemBuilder: (context, index) {
                  if (index < players.length) {
                    return buildPlayerRow(players[index], index);
                  } else {
                    return buildNewPlayerButton();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
