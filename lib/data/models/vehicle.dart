class Vehicle {
  final String id;
  final String name;
  final String kennzeichen;
  final int baujahr;
  final double? jahresLimitKm;
  final bool aktiv;
  final String? fotoPath;
  final bool trackingPausiert;
  final DateTime erstelltAm;
  final DateTime aktualisiertAm;

  const Vehicle({
    required this.id,
    required this.name,
    required this.kennzeichen,
    required this.baujahr,
    this.jahresLimitKm,
    this.aktiv = false,
    this.fotoPath,
    this.trackingPausiert = false,
    required this.erstelltAm,
    required this.aktualisiertAm,
  });

  Vehicle copyWith({
    String? name,
    String? kennzeichen,
    int? baujahr,
    double? jahresLimitKm,
    bool? clearJahresLimit,
    bool? aktiv,
    String? fotoPath,
    bool? clearFoto,
    bool? trackingPausiert,
    DateTime? aktualisiertAm,
  }) {
    return Vehicle(
      id: id,
      name: name ?? this.name,
      kennzeichen: kennzeichen ?? this.kennzeichen,
      baujahr: baujahr ?? this.baujahr,
      jahresLimitKm: clearJahresLimit == true
          ? null
          : (jahresLimitKm ?? this.jahresLimitKm),
      aktiv: aktiv ?? this.aktiv,
      fotoPath: clearFoto == true ? null : (fotoPath ?? this.fotoPath),
      trackingPausiert: trackingPausiert ?? this.trackingPausiert,
      erstelltAm: erstelltAm,
      aktualisiertAm: aktualisiertAm ?? this.aktualisiertAm,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'kennzeichen': kennzeichen,
      'baujahr': baujahr,
      'jahres_limit_km': jahresLimitKm,
      'aktiv': aktiv ? 1 : 0,
      'foto_path': fotoPath,
      'tracking_pausiert': trackingPausiert ? 1 : 0,
      'erstellt_am': erstelltAm.toIso8601String(),
      'aktualisiert_am': aktualisiertAm.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as String,
      name: map['name'] as String,
      kennzeichen: map['kennzeichen'] as String,
      baujahr: map['baujahr'] as int,
      jahresLimitKm: map['jahres_limit_km'] as double?,
      aktiv: (map['aktiv'] as int) == 1,
      fotoPath: map['foto_path'] as String?,
      trackingPausiert: (map['tracking_pausiert'] as int) == 1,
      erstelltAm: DateTime.parse(map['erstellt_am'] as String),
      aktualisiertAm: DateTime.parse(map['aktualisiert_am'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Vehicle && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
