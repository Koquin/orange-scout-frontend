import '../models/player.dart';

class PlayerController {
  List<Player> players = [];

  void addPlayer(Player player) {
    players.add(player);
  }

  void deletePlayer(int id) {
    players.removeWhere((player) => player.id == id);
  }
}