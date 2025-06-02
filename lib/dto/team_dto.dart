class TeamDTO {
  final int? id;
  final String teamName;
  final String? logoPath;
  final String abbreviation;
  final int? userId; // For response DTO

  TeamDTO({this.id, required this.teamName, this.logoPath, required this.abbreviation, this.userId});

  factory TeamDTO.fromJson(Map<String, dynamic> json) {
    return TeamDTO(
      id: json['id'],
      teamName: json['teamName'],
      logoPath: json['logoPath'],
      abbreviation: json['abbreviation'],
      userId: json['userId'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'teamName': teamName,
        'logoPath': logoPath,
        'abbreviation': abbreviation,
        'userId': userId, // Only include if sending for creation/update by admin or specific use-case
      };
}