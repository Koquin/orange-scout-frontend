import 'package:OrangeScoutFE/dto/player_dto.dart';
import 'package:OrangeScoutFE/dto/stats_dto.dart';
import 'package:OrangeScoutFE/dto/team_dto.dart';

import 'location_dto.dart';

class MatchDTO {
  final int? idMatch;
  final String gameMode;
  final String matchDate; // Using String for ISO 8601 date, can convert to DateTime as needed
  final int teamOneScore;
  final int teamTwoScore;
  final TeamDTO teamOne; // Assumes TeamDTO is defined
  final TeamDTO teamTwo; // Assumes TeamDTO is defined
  final List<StatsDTO> stats; // Assumes StatsDTO is defined
  final LocationDTO? location; // Assumes LocationDTO is defined
  final bool finished;
  final List<PlayerDTO> startersTeam1; // Assumes PlayerDTO is defined
  final List<PlayerDTO> startersTeam2; // Assumes PlayerDTO is defined
  final int? appUserId; // Only for response DTO, not for request

  MatchDTO({
    this.idMatch, required this.gameMode, required this.matchDate,
    required this.teamOneScore, required this.teamTwoScore,
    required this.teamOne, required this.teamTwo,
    required this.stats, this.location, required this.finished,
    required this.startersTeam1, required this.startersTeam2,
    this.appUserId
  });

  factory MatchDTO.fromJson(Map<String, dynamic> json) {
    return MatchDTO(
      idMatch: json['idMatch'],
      gameMode: json['gameMode'],
      matchDate: json['matchDate'],
      teamOneScore: json['teamOneScore'],
      teamTwoScore: json['teamTwoScore'],
      teamOne: TeamDTO.fromJson(json['teamOne']),
      teamTwo: TeamDTO.fromJson(json['teamTwo']),
      stats: (json['stats'] as List).map((i) => StatsDTO.fromJson(i)).toList(),
      location: json['location'] != null ? LocationDTO.fromJson(json['location']) : null,
      finished: json['finished'],
      startersTeam1: (json['startersTeam1'] as List).map((i) => PlayerDTO.fromJson(i)).toList(),
      startersTeam2: (json['startersTeam2'] as List).map((i) => PlayerDTO.fromJson(i)).toList(),
      appUserId: json['appUserId'],
    );
  }

  Map<String, dynamic> toJson() => {
        'idMatch': idMatch,
        'gameMode': gameMode,
        'matchDate': matchDate,
        'teamOneScore': teamOneScore,
        'teamTwoScore': teamTwoScore,
        'teamOne': teamOne.toJson(),
        'teamTwo': teamTwo.toJson(),
        'stats': stats.map((s) => s.toJson()).toList(),
        'location': location?.toJson(),
        'finished': finished,
        'startersTeam1': startersTeam1.map((p) => p.toJson()).toList(),
        'startersTeam2': startersTeam2.map((p) => p.toJson()).toList(),
      };
}