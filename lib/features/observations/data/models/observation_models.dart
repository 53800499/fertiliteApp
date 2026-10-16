import 'package:equatable/equatable.dart';

/// Types de glaire cervicale
class GlaireType {
  static const String sec = 'sec';
  static const String collant = 'collant';
  static const String cremeux = 'cremeux';
  static const String filantBlancOeuf = 'filant_blanc_oeuf';
  static const String aqueux = 'aqueux';

  static String getLabel(String type) {
    switch (type) {
      case sec:
        return 'Sèche / Aucune';
      case collant:
        return 'Collante / Épaisse';
      case cremeux:
        return 'Crémeuse / Blanche';
      case filantBlancOeuf:
        return "Filante (Blanc d'œuf)";
      case aqueux:
        return 'Aqueuse / Fluide';
      default:
        return type;
    }
  }

  static String getDescription(String type) {
    switch (type) {
      case sec:
        return 'Sensation de sécheresse, peu ou pas de sécrétion visible.';
      case collant:
        return 'Texture épaisse et collante, se brise rapidement.';
      case cremeux:
        return 'Aspect lotion ou crème blanche, sensation humide.';
      case filantBlancOeuf:
        return "Transparente, très étirable entre les doigts (> 2 cm), fertilité maximale.";
      case aqueux:
        return 'Très liquide, sensation très mouillée, pic de fertilité imminent.';
      default:
        return '';
    }
  }

  static bool isFertile(String type) =>
      type == filantBlancOeuf || type == aqueux;
}

/// Résultat du test d'ovulation LH
class LhResult {
  static const String negatif = 'negatif';
  static const String faible = 'faible';
  static const String positif = 'positif';
  static const String pic = 'pic';

  static String getLabel(String res) {
    switch (res) {
      case negatif:
        return 'Négatif';
      case faible:
        return 'Ligne faible';
      case positif:
        return 'Positif';
      case pic:
        return 'Pic de LH';
      default:
        return res;
    }
  }

  static bool isPeak(String res) => res == positif || res == pic;
}

/// Modèle Température Basale (UC-16)
class TemperatureBasaleModel extends Equatable {
  final String? id;
  final String date;
  final double temperatureCelsius;
  final String? heurePrise;
  final bool estPerturbee;
  final String? facteurPerturbateur;
  final String? notes;
  final String? idClientLocal;

  const TemperatureBasaleModel({
    this.id,
    required this.date,
    required this.temperatureCelsius,
    this.heurePrise,
    this.estPerturbee = false,
    this.facteurPerturbateur,
    this.notes,
    this.idClientLocal,
  });

  factory TemperatureBasaleModel.fromJson(Map<String, dynamic> json) {
    String rawDate = (json['date'] as String? ?? '').trim();
    if (rawDate.length >= 10) rawDate = rawDate.substring(0, 10);
    return TemperatureBasaleModel(
      id: json['id'] as String?,
      date: rawDate,
      temperatureCelsius: (json['temperatureCelsius'] is num)
          ? (json['temperatureCelsius'] as num).toDouble()
          : double.tryParse(json['temperatureCelsius']?.toString() ?? '36.5') ?? 36.5,
      heurePrise: (json['heurePrise'] ?? json['heure_prise']) as String?,
      estPerturbee: (json['estPerturbee'] ?? json['est_perturbee']) as bool? ?? false,
      facteurPerturbateur: (json['facteurPerturbateur'] ?? json['facteur_perturbateur']) as String?,
      notes: json['notes'] as String?,
      idClientLocal: (json['idClientLocal'] ?? json['id_client_local']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'date': date,
        'temperatureCelsius': temperatureCelsius,
        if (heurePrise != null) 'heurePrise': heurePrise,
        'estPerturbee': estPerturbee,
        if (facteurPerturbateur != null) 'facteurPerturbateur': facteurPerturbateur,
        if (notes != null) 'notes': notes,
        if (idClientLocal != null) 'idClientLocal': idClientLocal,
      };

  String get formattedTemp => '${temperatureCelsius.toStringAsFixed(2)} °C';

  @override
  List<Object?> get props => [
        id,
        date,
        temperatureCelsius,
        heurePrise,
        estPerturbee,
        facteurPerturbateur,
        notes,
      ];
}

/// Modèle Glaire Cervicale (UC-17)
class GlaireCervicaleModel extends Equatable {
  final String? id;
  final String date;
  final String typeGlaire;
  final String? quantite;
  final String? sensation;
  final String? notes;
  final String? idClientLocal;

  const GlaireCervicaleModel({
    this.id,
    required this.date,
    required this.typeGlaire,
    this.quantite,
    this.sensation,
    this.notes,
    this.idClientLocal,
  });

  factory GlaireCervicaleModel.fromJson(Map<String, dynamic> json) {
    String rawDate = (json['date'] as String? ?? '').trim();
    if (rawDate.length >= 10) rawDate = rawDate.substring(0, 10);
    return GlaireCervicaleModel(
      id: json['id'] as String?,
      date: rawDate,
      typeGlaire: (json['typeGlaire'] ?? json['type_glaire']) as String? ?? 'cremeux',
      quantite: json['quantite'] as String?,
      sensation: json['sensation'] as String?,
      notes: json['notes'] as String?,
      idClientLocal: (json['idClientLocal'] ?? json['id_client_local']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'date': date,
        'typeGlaire': typeGlaire,
        if (quantite != null) 'quantite': quantite,
        if (sensation != null) 'sensation': sensation,
        if (notes != null) 'notes': notes,
        if (idClientLocal != null) 'idClientLocal': idClientLocal,
      };

  String get label => GlaireType.getLabel(typeGlaire);
  bool get isFertile => GlaireType.isFertile(typeGlaire);

  @override
  List<Object?> get props => [id, date, typeGlaire, quantite, sensation, notes];
}

/// Modèle Test d'Ovulation (UC-18)
class TestOvulationModel extends Equatable {
  final String? id;
  final String date;
  final String? heureTest;
  final String resultat;
  final double? valeurMUiMl;
  final String? notes;
  final String? idClientLocal;

  const TestOvulationModel({
    this.id,
    required this.date,
    this.heureTest,
    required this.resultat,
    this.valeurMUiMl,
    this.notes,
    this.idClientLocal,
  });

  factory TestOvulationModel.fromJson(Map<String, dynamic> json) {
    String rawDate = (json['date'] as String? ?? '').trim();
    if (rawDate.length >= 10) rawDate = rawDate.substring(0, 10);
    return TestOvulationModel(
      id: json['id'] as String?,
      date: rawDate,
      heureTest: (json['heureTest'] ?? json['heure_test']) as String?,
      resultat: (json['resultat'] ?? json['result']) as String? ?? 'negatif',
      valeurMUiMl: json['valeurMUiMl'] != null
          ? ((json['valeurMUiMl'] is num)
              ? (json['valeurMUiMl'] as num).toDouble()
              : double.tryParse(json['valeurMUiMl'].toString()))
          : (json['valeur_mui_ml'] != null
              ? ((json['valeur_mui_ml'] is num)
                  ? (json['valeur_mui_ml'] as num).toDouble()
                  : double.tryParse(json['valeur_mui_ml'].toString()))
              : null),
      notes: json['notes'] as String?,
      idClientLocal: (json['idClientLocal'] ?? json['id_client_local']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'date': date,
        if (heureTest != null) 'heureTest': heureTest,
        'resultat': resultat,
        if (valeurMUiMl != null) 'valeurMUiMl': valeurMUiMl,
        if (notes != null) 'notes': notes,
        if (idClientLocal != null) 'idClientLocal': idClientLocal,
      };

  String get label => LhResult.getLabel(resultat);
  bool get isPeak => LhResult.isPeak(resultat);

  @override
  List<Object?> get props => [id, date, heureTest, resultat, valeurMUiMl, notes];
}

/// Catalogue Type de Symptôme
class TypeSymptomeModel extends Equatable {
  final String id;
  final String code;
  final String nom;
  final String categorie;
  final String? icone;
  final int ordreAffichage;

  const TypeSymptomeModel({
    required this.id,
    required this.code,
    required this.nom,
    required this.categorie,
    this.icone,
    this.ordreAffichage = 0,
  });

  factory TypeSymptomeModel.fromJson(Map<String, dynamic> json) {
    return TypeSymptomeModel(
      id: json['id'] as String,
      code: json['code'] as String,
      nom: json['nom'] as String,
      categorie: json['categorie'] as String,
      icone: json['icone'] as String?,
      ordreAffichage: (json['ordreAffichage'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'nom': nom,
        'categorie': categorie,
        'icone': icone,
        'ordreAffichage': ordreAffichage,
      };

  String get categorieLabel {
    switch (categorie) {
      case 'physique':
        return 'Sensation physique';
      case 'emotionnel':
        return 'Humeur & Énergie';
      case 'digestif':
        return 'Digestif';
      case 'cutane':
        return 'Peau & Teint';
      default:
        return 'Autre';
    }
  }

  @override
  List<Object?> get props => [id, code, nom, categorie, icone, ordreAffichage];
}

/// Observation d'un symptôme (UC-19)
class ObservationSymptomeModel extends Equatable {
  final String? id;
  final String date;
  final String typeSymptomeId;
  final TypeSymptomeModel? typeSymptome;
  final int intensite; // 1 à 5
  final String? notes;

  const ObservationSymptomeModel({
    this.id,
    required this.date,
    required this.typeSymptomeId,
    this.typeSymptome,
    required this.intensite,
    this.notes,
  });

  factory ObservationSymptomeModel.fromJson(Map<String, dynamic> json) {
    String rawDate = (json['date'] as String? ?? '').trim();
    if (rawDate.length >= 10) rawDate = rawDate.substring(0, 10);
    return ObservationSymptomeModel(
      id: json['id'] as String?,
      date: rawDate,
      typeSymptomeId: (json['typeSymptomeId'] ?? json['type_symptome_id'] ?? json['typeSymptome']?['id']) as String? ?? '',
      typeSymptome: json['typeSymptome'] != null
          ? TypeSymptomeModel.fromJson(json['typeSymptome'] as Map<String, dynamic>)
          : null,
      intensite: (json['intensite'] is num)
          ? (json['intensite'] as num).toInt()
          : (int.tryParse(json['intensite']?.toString() ?? '1') ?? 1),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'date': date,
        'typeSymptomeId': typeSymptomeId,
        'intensite': intensite,
        if (notes != null) 'notes': notes,
      };

  String get displayName => typeSymptome?.nom ?? 'Symptôme';

  @override
  List<Object?> get props => [id, date, typeSymptomeId, typeSymptome, intensite, notes];
}

/// Détail agrégé de toutes les observations d'un jour (UC-12)
class DayObservationsModel extends Equatable {
  final String date;
  final TemperatureBasaleModel? temperature;
  final GlaireCervicaleModel? glaire;
  final List<TestOvulationModel> testsLh;
  final List<ObservationSymptomeModel> symptomes;

  const DayObservationsModel({
    required this.date,
    this.temperature,
    this.glaire,
    this.testsLh = const [],
    this.symptomes = const [],
  });

  factory DayObservationsModel.fromJson(Map<String, dynamic> json) {
    String rawDate = (json['date'] as String? ?? '').trim();
    if (rawDate.length >= 10) rawDate = rawDate.substring(0, 10);
    return DayObservationsModel(
      date: rawDate,
      temperature: json['temperature'] != null
          ? TemperatureBasaleModel.fromJson(json['temperature'] as Map<String, dynamic>)
          : null,
      glaire: json['glaire'] != null
          ? GlaireCervicaleModel.fromJson(json['glaire'] as Map<String, dynamic>)
          : null,
      testsLh: ((json['testsLh'] ?? json['tests_lh']) as List<dynamic>?)
              ?.map((e) => TestOvulationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      symptomes: (json['symptomes'] as List<dynamic>?)
              ?.map((e) => ObservationSymptomeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  bool get hasObservations =>
      temperature != null ||
      glaire != null ||
      testsLh.isNotEmpty ||
      symptomes.isNotEmpty;

  @override
  List<Object?> get props => [date, temperature, glaire, testsLh, symptomes];
}

/// DTO de soumission journalière globale
class SaveDayObservationRequest {
  final String date;
  final TemperatureBasaleModel? temperature;
  final GlaireCervicaleModel? glaire;
  final TestOvulationModel? testLh;
  final List<ObservationSymptomeModel>? symptomes;

  const SaveDayObservationRequest({
    required this.date,
    this.temperature,
    this.glaire,
    this.testLh,
    this.symptomes,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      if (temperature != null) 'temperature': {...temperature!.toJson(), 'date': date},
      if (glaire != null) 'glaire': {...glaire!.toJson(), 'date': date},
      if (testLh != null) 'testLh': {...testLh!.toJson(), 'date': date},
      if (symptomes != null && symptomes!.isNotEmpty)
        'symptomes': symptomes!
            .map((s) => {
                  'code': s.typeSymptome?.code ?? s.typeSymptomeId,
                  'intensite': s.intensite,
                  if (s.notes != null) 'notes': s.notes,
                })
            .toList(),
    };
  }
}
