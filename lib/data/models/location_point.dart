class LocationPoint {
  final int? id;
  final String tripId;
  final DateTime timestamp;
  final double lat;
  final double lng;
  final double? speed;
  final double? accuracy;

  const LocationPoint({
    this.id,
    required this.tripId,
    required this.timestamp,
    required this.lat,
    required this.lng,
    this.speed,
    this.accuracy,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'trip_id': tripId,
      'timestamp': timestamp.toIso8601String(),
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'accuracy': accuracy,
    };
  }

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      id: map['id'] as int?,
      tripId: map['trip_id'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
    );
  }
}
