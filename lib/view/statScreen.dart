import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:OrangeScoutFE/util/token_utils.dart';

class StatsScreen extends StatefulWidget {
  final int matchId;

  const StatsScreen({super.key, required this.matchId});

  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  //Base url:
  String? baseUrl = dotenv.env['API_BASE_URL'];

  //Other variables
  List<dynamic> stats = [];
  bool isLoading = true;
  Map<String, List<dynamic>> teamsStats = {};
  String? selectedTeamFilter;
  List<String> availableTeams = [];
  String? matchLocation;

  @override
  void initState() {
    super.initState();
    fetchStats();
  }

  Future<void> fetchStats() async {
    String? token = await loadToken();

    try {
      final statsResponse = await http.get(
        Uri.parse('$baseUrl/stats/${widget.matchId}'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (statsResponse.statusCode == 200) {
        var statsData = jsonDecode(statsResponse.body);

        if (statsData is Map<String, dynamic> && statsData.containsKey('stats')) {
          statsData = statsData['stats'];
        }

        Map<String, List<dynamic>> teamStats = {};
        for (var stat in statsData) {
          if (stat is Map<String, dynamic> && stat.containsKey('teamName')) {
            String team = stat['teamName'];
            teamStats.putIfAbsent(team, () => []).add(stat);
          }
        }
        final locationResponse = await http.get(
          Uri.parse('$baseUrl/match/${widget.matchId}'),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        );

        String? locationName;
        if (locationResponse.statusCode == 200) {
          var locationData = jsonDecode(locationResponse.body);
          if (locationData['location']['id'] != null) {
            locationName = locationData['location']['placeName'];
          }
        }
        setState(() {
          stats = statsData;
          teamsStats = teamStats;
          availableTeams = teamStats.keys.toList();
          isLoading = false;
          matchLocation = locationName;
        });
      } else {
        throw Exception('Error loading data.');
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  void applyFilter(String? filter) {
    setState(() {
      selectedTeamFilter = filter == "All Teams" ? null : filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    Map<String, List<dynamic>> filteredStats = selectedTeamFilter != null
        ? {selectedTeamFilter!: teamsStats[selectedTeamFilter!] ?? []}
        : teamsStats;

    return Scaffold(
      appBar: AppBar(
        title: Text(matchLocation != null ? '$matchLocation' : '', style: TextStyle(fontSize: 20),),
        backgroundColor: Color.fromARGB(255, 202, 66, 56),
        leading: IconButton(
          icon: Image.asset('assets/images/arrow_left.png', width: 50, height: 50),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          if (availableTeams.isNotEmpty)
            PopupMenuButton<String>(
              icon: Image.asset('assets/images/filterIcon.png', width: 50, height: 50),
              onSelected: applyFilter,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: "All Teams",
                  child: Text("All Teams"),
                ),
                ...availableTeams.map((team) =>
                    PopupMenuItem(value: team, child: Text(team))),
              ],
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        children: filteredStats.keys.map((team) {
          var players = filteredStats[team] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  team,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('PLAYER')),
                    DataColumn(label: Text('3PT')),
                    DataColumn(label: Text('2PT')),
                    DataColumn(label: Text('1PT')),
                    DataColumn(label: Text('STEAL')),
                    DataColumn(label: Text('TURNOVER')),
                    DataColumn(label: Text('BLOCK')),
                    DataColumn(label: Text('ASSIST')),
                    DataColumn(label: Text('OFF REB')),
                    DataColumn(label: Text('DEF REB')),
                    DataColumn(label: Text('FOUL')),
                  ],
                  rows: players.map((playerStats) {
                    int threeMade = playerStats['three_pointer'];
                    int threeMissed = playerStats['missed_three_pointer'];
                    int twoMade = playerStats['two_pointer'];
                    int twoMissed = playerStats['missed_two_pointer'];
                    int oneMade = playerStats['one_pointer'];
                    int oneMissed = playerStats['missed_one_pointer'];

                    return DataRow(
                      cells: [
                        DataCell(Text(playerStats['playerJersey'].toString())),
                        DataCell(Text('$threeMade/${threeMade + threeMissed}')), // 3PT
                        DataCell(Text('$twoMade/${twoMade + twoMissed}')),       // 2PT
                        DataCell(Text('$oneMade/${oneMade + oneMissed}')),       // 1PT
                        DataCell(Text(playerStats['steal'].toString())),
                        DataCell(Text(playerStats['turnover'].toString())),
                        DataCell(Text(playerStats['block'].toString())),
                        DataCell(Text(playerStats['assist'].toString())),
                        DataCell(Text(playerStats['offensive_rebound'].toString())),
                        DataCell(Text(playerStats['defensive_rebound'].toString())),
                        DataCell(Text(playerStats['foul'].toString())),
                      ],
                    );
                  }).toList(),
                )
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
