class StatsDTO {
  final int? statsId;
  final int? matchId;
  final int? playerId;
  final String? playerJersey;
  final String? teamName;
  final int threePointers;
  final int twoPointers;
  final int onePointers;
  final int missedThreePointers;
  final int missedTwoPointers;
  final int missedOnePointers;
  final int steals;
  final int turnovers;
  final int blocks;
  final int assists;
  final int offensiveRebounds;
  final int defensiveRebounds;
  final int fouls;

  StatsDTO({
    this.statsId, this.matchId, required this.playerId,
    this.playerJersey, this.teamName,
    required this.threePointers, required this.twoPointers, required this.onePointers,
    required this.missedThreePointers, required this.missedTwoPointers, required this.missedOnePointers,
    required this.steals, required this.turnovers, required this.blocks, required this.assists,
    required this.offensiveRebounds, required this.defensiveRebounds, required this.fouls
  });

  factory StatsDTO.fromJson(Map<String, dynamic> json) {
    return StatsDTO(
      statsId: json['statsId'],
      matchId: json['matchId'],
      playerId: json['playerId'],
      playerJersey: json['playerJersey'],
      teamName: json['teamName'],
      threePointers: json['threePointers'],
      twoPointers: json['twoPointers'],
      onePointers: json['onePointers'],
      missedThreePointers: json['missedThreePointers'],
      missedTwoPointers: json['missedTwoPointers'],
      missedOnePointers: json['missedOnePointers'],
      steals: json['steals'],
      turnovers: json['turnovers'],
      blocks: json['blocks'],
      assists: json['assists'],
      offensiveRebounds: json['offensiveRebounds'],
      defensiveRebounds: json['defensiveRebounds'],
      fouls: json['fouls'],
    );
  }

  Map<String, dynamic> toJson() => {
    'statsId': statsId, 'matchId': matchId, 'playerId': playerId,
    'playerJersey': playerJersey, 'teamName': teamName,
    'threePointers': threePointers, 'twoPointers': twoPointers, 'onePointers': onePointers,
    'missedThreePointers': missedThreePointers, 'missedTwoPointers': missedTwoPointers, 'missedOnePointers': missedOnePointers,
    'steals': steals, 'turnovers': turnovers, 'blocks': blocks, 'assists': assists,
    'offensiveRebounds': offensiveRebounds, 'defensiveRebounds': defensiveRebounds, 'fouls': fouls,
  };

  StatsDTO copyWith({
    int? statsId, int? matchId, int? playerId,
    String? playerJersey, String? teamName,
    int? threePointers, int? twoPointers, int? onePointers,
    int? missedThreePointers, int? missedTwoPointers, int? missedOnePointers,
    int? steals, int? turnovers, int? blocks, int? assists,
    int? offensiveRebounds, int? defensiveRebounds, int? fouls,
  }) {
    return StatsDTO(
      statsId: statsId ?? this.statsId,
      matchId: matchId ?? this.matchId,
      playerId: playerId ?? this.playerId,
      playerJersey: playerJersey ?? this.playerJersey,
      teamName: teamName ?? this.teamName,
      threePointers: threePointers ?? this.threePointers,
      twoPointers: twoPointers ?? this.twoPointers,
      onePointers: onePointers ?? this.onePointers,
      missedThreePointers: missedThreePointers ?? this.missedThreePointers,
      missedTwoPointers: missedTwoPointers ?? this.missedTwoPointers,
      missedOnePointers: missedOnePointers ?? this.missedOnePointers,
      steals: steals ?? this.steals,
      turnovers: turnovers ?? this.turnovers,
      blocks: blocks ?? this.blocks,
      assists: assists ?? this.assists,
      offensiveRebounds: offensiveRebounds ?? this.offensiveRebounds,
      defensiveRebounds: defensiveRebounds ?? this.defensiveRebounds,
      fouls: fouls ?? this.fouls,
    );
  }
}