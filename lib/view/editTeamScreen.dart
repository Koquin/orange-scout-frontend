import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:OrangeScoutFE/view/createTeamScreen.dart';
import 'package:OrangeScoutFE/controller/playerController.dart';
import 'package:OrangeScoutFE/controller/teamController.dart';
import 'package:firebase_analytics/firebase_analytics.dart';


class EditTeamScreen extends StatefulWidget {
  final int teamId;

  const EditTeamScreen({super.key, required this.teamId});

  @override
  State<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends State<EditTeamScreen> {
  List<Map<String, dynamic>> players = [];
  bool isLoading = true;

  final PlayerController _playerController = PlayerController();
  final TeamController _teamController = TeamController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FirebaseAnalytics.instance.logScreenView(
        screenName: 'EditTeamPlayersScreen',
        screenClass: 'EditTeamScreenState',
        parameters: {'team_id': widget.teamId},
      );
    });
    _fetchPlayers();
  }

  Future<void> _pickImage() async {
    FirebaseAnalytics.instance.logEvent(name: 'pick_image_button_tapped');
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
      });
      FirebaseAnalytics.instance.logEvent(name: 'image_picked_successfully');
    } else {
      FirebaseAnalytics.instance.logEvent(name: 'image_pick_canceled');
    }
  }

  Future<void> _fetchPlayers() async {
    setState(() => isLoading = true);
    List<dynamic> fetchedPlayers = await _playerController.fetchPlayersByTeamId(widget.teamId);

    setState(() {
      players = fetchedPlayers.map((p) => Map<String, dynamic>.from(p)).toList();
      isLoading = false;
    });

    if (fetchedPlayers.isEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No players found for this team. Add some!')),
      );
    }
  }

  void addNewPlayerRow() {
    setState(() {
      players.add({'playerName': '', 'jerseyNumber': '', 'isNew': true});
    });
    FirebaseAnalytics.instance.logEvent(name: 'add_new_player_row');
  }

  Future<void> confirmNewPlayer(int index, String name, String number) async {
    if (name.isEmpty || number.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill both boxes")),
        );
      }
      FirebaseAnalytics.instance.logEvent(name: 'add_player_failed', parameters: {'reason': 'empty_fields'});
      return;
    }

    setState(() => isLoading = true);
    final PlayerOperationResult result = await _playerController.addPlayer(
      playerName: name,
      jerseyNumber: number,
      teamId: widget.teamId,
    );

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Player added successfully!")),
        );
        await _fetchPlayers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'Unknown error adding player')),
        );
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> deletePlayer(int index) async {
    final id = players[index]['id_player'];
    if (id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Player ID not found.')),
        );
      }
      FirebaseAnalytics.instance.logEvent(name: 'delete_player_failed', parameters: {'reason': 'player_id_null'});
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete Player'),
        content: const Text('Are you sure you want to delete this player?'),
        actions: [
          TextButton(
            onPressed: () {
              FirebaseAnalytics.instance.logEvent(name: 'delete_player_canceled');
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              FirebaseAnalytics.instance.logEvent(name: 'delete_player_confirmed');
              Navigator.of(context).pop(true);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == null || !confirm) return;

    setState(() => isLoading = true);
    final PlayerOperationResult result = await _playerController.deletePlayer(id);

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Player deleted successfully!")),
        );
        await _fetchPlayers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'Unknown error deleting player')),
        );
      }
    }
    setState(() => isLoading = false);
  }

  Future<void> editPlayer(int index) async {
    final player = players[index];
    final id = player['id_player'];

    if (id == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Player ID not found for editing.')),
        );
      }
      FirebaseAnalytics.instance.logEvent(name: 'edit_player_failed', parameters: {'reason': 'player_id_null'});
      return;
    }

    setState(() => isLoading = true);
    final PlayerOperationResult result = await _playerController.editPlayer(
      playerId: id,
      playerName: player['playerName'],
      jerseyNumber: player['jerseyNumber'],
    );

    if (mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Player updated successfully!")),
        );
        await _fetchPlayers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.errorMessage ?? 'Unknown error updating player')),
        );
      }
    }
    setState(() => isLoading = false);
  }

  void showEditDialog(int index) {
    FirebaseAnalytics.instance.logEvent(name: 'edit_player_dialog_opened', parameters: {'player_id': players[index]['id_player']});
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
              onPressed: () {
                FirebaseAnalytics.instance.logEvent(name: 'edit_player_dialog_canceled');
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Save", style: TextStyle(color: Colors.green)),
              onPressed: () {
                FirebaseAnalytics.instance.logEvent(name: 'edit_player_dialog_saved');
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

  Future<void> _deleteTeam() async {
    FirebaseAnalytics.instance.logEvent(name: 'delete_team_button_tapped');
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete this team? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                FirebaseAnalytics.instance.logEvent(name: 'delete_team_canceled');
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                FirebaseAnalytics.instance.logEvent(name: 'delete_team_confirmed');
                Navigator.of(context).pop(true);
              },
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

    final bool success = await _teamController.deleteTeam(widget.teamId);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team deleted successfully!')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete team.')),
        );
      }
    }
    setState(() {
      isLoading = false;
    });
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
                  FirebaseAnalytics.instance.logEvent(name: 'add_new_player_confirm_button_tapped');
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
            FirebaseAnalytics.instance.logEvent(name: 'player_popup_menu_selected', parameters: {'action': value});
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
          onPressed: () {
            FirebaseAnalytics.instance.logEvent(name: 'new_player_button_tapped');
            addNewPlayerRow();
          },
          child: const Text("New player", style: TextStyle(color: Colors.orange)),
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF4500),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            FirebaseAnalytics.instance.logEvent(name: 'edit_team_players_back_button_tapped', parameters: {'team_id': widget.teamId});
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white, size: 28),
            tooltip: 'Edit Team Details',
            onPressed: isLoading ? null : () async {
              FirebaseAnalytics.instance.logEvent(name: 'edit_team_details_button_tapped', parameters: {'team_id': widget.teamId});
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateTeamScreen(teamId: widget.teamId),
                ),
              );
              if (result == true) {
                _fetchPlayers();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Team details refreshed!")),
                  );
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white, size: 28),
            tooltip: 'Delete Team',
            onPressed: isLoading ? null : _deleteTeam,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF84442E),
              Color(0xFF3A2E2E),
            ],
            stops: [0.0, 0.7],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
