class Trip {
  final String id;
  final String vehicleId;
  final DateTime startTimestamp;
  final DateTime? endTimestamp;
  final double distanceKm;
  final bool manuellErfasst;
  final String? startOrt;
  final String? endOrt;
  final String? notiz;

  const Trip({
    required this.id,
    required this.vehicleId,
    required this.startTimestamp,
    this.endTimestamp,
    this.distanceKm = 0.0,
    this.manuellErfasst = false,
    this.startOrt,
    this.endOrt,
    this.notiz,
  });

  Trip copyWith({
    DateTime? startTimestamp,
    DateTime? endTimestamp,
    double? distanceKm,
    bool? manuellErfasst,
    String? startOrt,
    String? endOrt,
    String? notiz,
    bool? clearNotiz,
  }) {
    return Trip(
      id: id,
      vehicleId: vehicleId,
      startTimestamp: startTimestamp ?? this.startTimestamp,
      endTimestamp: endTimestamp ?? this.endTimestamp,
      distanceKm: distanceKm ?? this.distanceKm,
      manuellErfasst: manuellErfasst ?? this.manuellErfasst,
      startOrt: startOrt ?? this.startOrt,
      endOrt: endOrt ?? this.endOrt,
      notiz: clearNotiz == true ? null : (notiz ?? this.notiz),
    );
  }

  Duration? get dauer {
    if (endTimestamp == null) return null;
    return endTimestamp!.difference(startTimestamp);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'start_timestamp': startTimestamp.toIso8601String(),
      'end_timestamp': endTimestamp?.toIso8601String(),
      'distance_km': distanceKm,
      'manuell_erfasst': manuellErfasst ? 1 : 0,
      'start_ort': startOrt,
      'end_ort': endOrt,
      'notiz': notiz,
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      startTimestamp: DateTime.parse(map['start_timestamp'] as String),
      endTimestamp: map['end_timestamp'] != null
          ? DateTime.parse(map['end_timestamp'] as String)
          : null,
      distanceKm: (map['distance_km'] as num).toDouble(),
      manuellErfasst: (map['manuell_erfasst'] as int) == 1,
      startOrt: map['start_ort'] as String?,
      endOrt: map['end_ort'] as String?,
      notiz: map['notiz'] as String?,
    );
  }
}
