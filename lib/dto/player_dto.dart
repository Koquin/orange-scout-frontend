// lib/dto/player_dto.dart
// Certifique-se que este arquivo existe e está atualizado conforme nossas refatorações anteriores

class PlayerDTO {
  final int? idPlayer;
  final String playerName;
  final String jerseyNumber;
  final int? teamId;
  final String? teamName;

  PlayerDTO({
    this.idPlayer,
    required this.playerName,
    required this.jerseyNumber,
    this.teamId,
    this.teamName,
  });

  factory PlayerDTO.fromJson(Map<String, dynamic> json) {
    return PlayerDTO(
      idPlayer: json['id_player'],
      playerName: json['playerName'],
      jerseyNumber: json['jerseyNumber'],
      teamId: json['teamId'],
      teamName: json['teamName'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id_player': idPlayer,
    'playerName': playerName,
    'jerseyNumber': jerseyNumber,
    'teamId': teamId,
    'teamName': teamName,
  };

  // ***** AQUI ESTÁ O MÉTODO copyWith QUE VOCÊ PRECISA ADICIONAR *****
  PlayerDTO copyWith({
    int? idPlayer,
    String? playerName,
    String? jerseyNumber,
    int? teamId,
    String? teamName,
  }) {
    return PlayerDTO(
      idPlayer: idPlayer ?? this.idPlayer,
      playerName: playerName ?? this.playerName,
      jerseyNumber: jerseyNumber ?? this.jerseyNumber,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
    );
  }
// *******************************************************************
}