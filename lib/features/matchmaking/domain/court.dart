class Court {
  const Court({required this.id, required this.name, this.distanceKm});
  final String id, name;
  final double? distanceKm;
  factory Court.fromJson(Map<String, dynamic> json) => Court(
    id: json['id'].toString(),
    name: json['name'] as String,
    distanceKm: (json['distance_km'] as num?)?.toDouble(),
  );
}
