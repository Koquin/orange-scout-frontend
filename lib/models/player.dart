class Player {
  int? id;
  String name;
  int teamId;

  Player({this.id, required this.name, required this.teamId});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'teamId': teamId};
  }
}
