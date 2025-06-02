class LocationDTO {
  final int? id; // int para Flutter, Long para Java
  final double latitude;
  final double longitude;
  final String venueName; // PADRONIZAÇÃO: venueName

  LocationDTO(
      {this.id, required this.latitude, required this.longitude, required this.venueName});

  factory LocationDTO.fromJson(Map<String, dynamic> json) {
    return LocationDTO(
      id: json['id'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      venueName: json['venueName'],
    );
  }

  Map<String, dynamic> toJson() {
    // If using json_serializable, this would be: return _$LocationDTOToJson(this);
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'venueName': venueName,
    };
  }

}