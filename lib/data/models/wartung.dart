/// Bekannte Wartungstypen mit Anzeigename und Icon-Zuordnung.
enum WartungTyp {
  oelwechsel('Ölwechsel'),
  oelstand('Ölstand geprüft'),
  reifenwechsel('Reifenwechsel'),
  reifendruck('Reifendruck geprüft'),
  service('Service / Inspektion'),
  reparatur('Reparatur'),
  pickerl('§57a Begutachtung (Pickerl)'),
  batterie('Batterie'),
  sonstiges('Sonstiges');

  final String anzeigeName;
  const WartungTyp(this.anzeigeName);

  static WartungTyp vonName(String name) {
    return WartungTyp.values.firstWhere(
      (t) => t.name == name,
      orElse: () => WartungTyp.sonstiges,
    );
  }
}

class Wartung {
  final String id;
  final String vehicleId;
  final WartungTyp typ;
  final DateTime datum;
  final double? kilometerstand;
  final String? notiz;

  const Wartung({
    required this.id,
    required this.vehicleId,
    required this.typ,
    required this.datum,
    this.kilometerstand,
    this.notiz,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'typ': typ.name,
      'datum': datum.toIso8601String(),
      'kilometerstand': kilometerstand,
      'notiz': notiz,
    };
  }

  factory Wartung.fromMap(Map<String, dynamic> map) {
    return Wartung(
      id: map['id'] as String,
      vehicleId: map['vehicle_id'] as String,
      typ: WartungTyp.vonName(map['typ'] as String),
      datum: DateTime.parse(map['datum'] as String),
      kilometerstand: (map['kilometerstand'] as num?)?.toDouble(),
      notiz: map['notiz'] as String?,
    );
  }
}
