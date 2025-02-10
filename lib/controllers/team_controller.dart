import '../models/team.dart';

class TeamController {
  List<Team> teams = [];

  void addTeam(Team team) {
    teams.add(team);
  }

  void editTeam(int id, String newName) {
    teams.firstWhere((team) => team.id == id).name = newName;
  }

  void deleteTeam(int id) {
    teams.removeWhere((team) => team.id == id);
  }
}