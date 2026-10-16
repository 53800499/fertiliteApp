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

/// Type de rapport intime (UC-24)
class TypeRapport {
  static const String protege = 'protege';
  static const String nonProtege = 'non_protege';

  static String getLabel(String type) {
    switch (type) {
      case protege:
        return 'Protégé (préservatif, etc.)';
      case nonProtege:
        return 'Non protégé';
      default:
        return type;
    }
  }

  static bool isProtege(String type) => type == protege;
}

/// Modèle Rapport Intime (UC-24 avec chiffrement applicatif AES-256)
class RapportSexuelModel extends Equatable {
  final String? id;
  final String date;
  final String typeRapport; // 'protege' | 'non_protege'
  final String? heure;
  final bool contraceptionUrgence;
  final String? notes; // Notes privées déchiffrées
  final String? idClientLocal;

  const RapportSexuelModel({
    this.id,
    required this.date,
    required this.typeRapport,
    this.heure,
    this.contraceptionUrgence = false,
    this.notes,
    this.idClientLocal,
  });

  factory RapportSexuelModel.fromJson(Map<String, dynamic> json) {
    String rawDate = (json['date'] as String? ?? '').trim();
    if (rawDate.length >= 10) rawDate = rawDate.substring(0, 10);
    return RapportSexuelModel(
      id: json['id'] as String?,
      date: rawDate,
      typeRapport: (json['typeRapport'] ?? json['type_rapport']) as String? ?? TypeRapport.nonProtege,
      heure: (json['heure'] as String?)?.trim(),
      contraceptionUrgence: (json['contraceptionUrgence'] ?? json['contraception_urgence']) as bool? ?? false,
      notes: json['notes'] as String?,
      idClientLocal: (json['idClientLocal'] ?? json['id_client_local']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'date': date,
        'typeRapport': typeRapport,
        if (heure != null && heure!.isNotEmpty) 'heure': heure,
        'contraceptionUrgence': contraceptionUrgence,
        if (notes != null) 'notes': notes,
        if (idClientLocal != null) 'idClientLocal': idClientLocal,
      };

  RapportSexuelModel copyWith({
    String? id,
    String? date,
    String? typeRapport,
    String? heure,
    bool? contraceptionUrgence,
    String? notes,
    String? idClientLocal,
  }) {
    return RapportSexuelModel(
      id: id ?? this.id,
      date: date ?? this.date,
      typeRapport: typeRapport ?? this.typeRapport,
      heure: heure ?? this.heure,
      contraceptionUrgence: contraceptionUrgence ?? this.contraceptionUrgence,
      notes: notes ?? this.notes,
      idClientLocal: idClientLocal ?? this.idClientLocal,
    );
  }

  @override
  List<Object?> get props => [
        id,
        date,
        typeRapport,
        heure,
        contraceptionUrgence,
        notes,
        idClientLocal,
      ];
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

/// Détail agrégé de toutes les observations d'un jour (UC-12 & UC-24)
class DayObservationsModel extends Equatable {
  final String date;
  final TemperatureBasaleModel? temperature;
  final GlaireCervicaleModel? glaire;
  final List<TestOvulationModel> testsLh;
  final List<ObservationSymptomeModel> symptomes;
  final RapportSexuelModel? rapport;
  final bool isPendingSync;

  const DayObservationsModel({
    required this.date,
    this.temperature,
    this.glaire,
    this.testsLh = const [],
    this.symptomes = const [],
    this.rapport,
    this.isPendingSync = false,
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
      rapport: json['rapport'] != null
          ? RapportSexuelModel.fromJson(json['rapport'] as Map<String, dynamic>)
          : null,
      isPendingSync: (json['isPendingSync'] ?? json['is_pending_sync']) as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        if (temperature != null) 'temperature': temperature!.toJson(),
        if (glaire != null) 'glaire': glaire!.toJson(),
        'testsLh': testsLh.map((t) => t.toJson()).toList(),
        'symptomes': symptomes.map((s) => s.toJson()).toList(),
        if (rapport != null) 'rapport': rapport!.toJson(),
        'isPendingSync': isPendingSync,
      };

  DayObservationsModel copyWith({
    String? date,
    TemperatureBasaleModel? temperature,
    GlaireCervicaleModel? glaire,
    List<TestOvulationModel>? testsLh,
    List<ObservationSymptomeModel>? symptomes,
    RapportSexuelModel? rapport,
    bool? isPendingSync,
    bool clearTemperature = false,
    bool clearGlaire = false,
    bool clearRapport = false,
  }) {
    return DayObservationsModel(
      date: date ?? this.date,
      temperature: clearTemperature ? null : (temperature ?? this.temperature),
      glaire: clearGlaire ? null : (glaire ?? this.glaire),
      testsLh: testsLh ?? this.testsLh,
      symptomes: symptomes ?? this.symptomes,
      rapport: clearRapport ? null : (rapport ?? this.rapport),
      isPendingSync: isPendingSync ?? this.isPendingSync,
    );
  }

  bool get hasObservations =>
      temperature != null ||
      glaire != null ||
      testsLh.isNotEmpty ||
      symptomes.isNotEmpty ||
      rapport != null;

  @override
  List<Object?> get props => [date, temperature, glaire, testsLh, symptomes, rapport, isPendingSync];
}

/// DTO de soumission journalière globale
class SaveDayObservationRequest {
  final String date;
  final TemperatureBasaleModel? temperature;
  final GlaireCervicaleModel? glaire;
  final TestOvulationModel? testLh;
  final List<ObservationSymptomeModel>? symptomes;
  final RapportSexuelModel? rapport;
  final String? idClientLocal;

  const SaveDayObservationRequest({
    required this.date,
    this.temperature,
    this.glaire,
    this.testLh,
    this.symptomes,
    this.rapport,
    this.idClientLocal,
  });

  factory SaveDayObservationRequest.fromJson(Map<String, dynamic> json) {
    return SaveDayObservationRequest(
      date: (json['date'] as String? ?? '').trim(),
      temperature: json['temperature'] != null
          ? TemperatureBasaleModel.fromJson(json['temperature'] as Map<String, dynamic>)
          : null,
      glaire: json['glaire'] != null
          ? GlaireCervicaleModel.fromJson(json['glaire'] as Map<String, dynamic>)
          : null,
      testLh: json['testLh'] != null
          ? TestOvulationModel.fromJson(json['testLh'] as Map<String, dynamic>)
          : null,
      symptomes: (json['symptomes'] as List<dynamic>?)
          ?.map((e) => ObservationSymptomeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      rapport: json['rapport'] != null
          ? RapportSexuelModel.fromJson(json['rapport'] as Map<String, dynamic>)
          : null,
      idClientLocal: json['idClientLocal'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      if (idClientLocal != null) 'idClientLocal': idClientLocal,
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
      if (rapport != null) 'rapport': {...rapport!.toJson(), 'date': date},
    };
  }
}

/// Type d'opération mise en file d'attente hors-ligne (Option C & UC-24)
enum ObservationSyncMutationType {
  saveDayObservation,
  deleteTemperature,
  deleteCervicalMucus,
  deleteLhTest,
  deleteSymptom,
  deleteIntercourse,
}

/// Élément de mutation persistant en attente de synchronisation
class QueuedObservationMutation extends Equatable {
  final String id;
  final ObservationSyncMutationType type;
  final String date;
  final SaveDayObservationRequest? request;
  final String? targetId;
  final DateTime clientTimestamp;
  final int retryCount;

  const QueuedObservationMutation({
    required this.id,
    required this.type,
    required this.date,
    this.request,
    this.targetId,
    required this.clientTimestamp,
    this.retryCount = 0,
  });

  factory QueuedObservationMutation.fromJson(Map<String, dynamic> json) {
    return QueuedObservationMutation(
      id: json['id'] as String,
      type: ObservationSyncMutationType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ObservationSyncMutationType.saveDayObservation,
      ),
      date: json['date'] as String,
      request: json['request'] != null
          ? SaveDayObservationRequest.fromJson(json['request'] as Map<String, dynamic>)
          : null,
      targetId: json['targetId'] as String?,
      clientTimestamp: DateTime.tryParse(json['clientTimestamp'] as String? ?? '') ?? DateTime.now(),
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'date': date,
        if (request != null) 'request': request!.toJson(),
        if (targetId != null) 'targetId': targetId,
        'clientTimestamp': clientTimestamp.toIso8601String(),
        'retryCount': retryCount,
      };

  QueuedObservationMutation copyWithIncrementedRetry() {
    return QueuedObservationMutation(
      id: id,
      type: type,
      date: date,
      request: request,
      targetId: targetId,
      clientTimestamp: clientTimestamp,
      retryCount: retryCount + 1,
    );
  }

  @override
  List<Object?> get props => [id, type, date, request, targetId, clientTimestamp, retryCount];
}

/// Rapport de synchronisation bidirectionnelle
class ObservationSyncReport extends Equatable {
  final int syncedCount;
  final int failedCount;
  final int remainingCount;
  final DateTime syncedAt;
  final String? message;

  const ObservationSyncReport({
    required this.syncedCount,
    required this.failedCount,
    required this.remainingCount,
    required this.syncedAt,
    this.message,
  });

  bool get hasRemaining => remainingCount > 0;
  bool get isFullSuccess => failedCount == 0 && remainingCount == 0;

  @override
  List<Object?> get props => [syncedCount, failedCount, remainingCount, syncedAt, message];
}

/// Point de données pour la courbe thermique continue (UC-16 DataViz)
class BbtPointModel extends Equatable {
  final String date;
  final int cycleDay;
  final double temperatureCelsius;
  final String? heurePrise;
  final bool estPerturbee;
  final String? facteurPerturbateur;
  final String? typeGlaire;
  final bool isAboveCoverline;
  final String phase; // 'follicular' | 'luteal' | 'potential_luteal'

  const BbtPointModel({
    required this.date,
    required this.cycleDay,
    required this.temperatureCelsius,
    this.heurePrise,
    this.estPerturbee = false,
    this.facteurPerturbateur,
    this.typeGlaire,
    this.isAboveCoverline = false,
    this.phase = 'follicular',
  });

  factory BbtPointModel.fromJson(Map<String, dynamic> json) {
    return BbtPointModel(
      date: (json['date'] as String? ?? '').trim(),
      cycleDay: ((json['cycleDay'] ?? json['cycle_day'] ?? 1) as num).toInt(),
      temperatureCelsius: (json['temperatureCelsius'] ?? json['temperature_celsius'] is num)
          ? (json['temperatureCelsius'] ?? json['temperature_celsius'] as num).toDouble()
          : double.tryParse(json['temperatureCelsius']?.toString() ?? '36.5') ?? 36.5,
      heurePrise: (json['heurePrise'] ?? json['heure_prise']) as String?,
      estPerturbee: (json['estPerturbee'] ?? json['est_perturbee']) as bool? ?? false,
      facteurPerturbateur: (json['facteurPerturbateur'] ?? json['facteur_perturbateur']) as String?,
      typeGlaire: (json['typeGlaire'] ?? json['type_glaire']) as String?,
      isAboveCoverline: (json['isAboveCoverline'] ?? json['is_above_coverline']) as bool? ?? false,
      phase: (json['phase'] as String?) ?? 'follicular',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'cycleDay': cycleDay,
        'temperatureCelsius': temperatureCelsius,
        if (heurePrise != null) 'heurePrise': heurePrise,
        'estPerturbee': estPerturbee,
        if (facteurPerturbateur != null) 'facteurPerturbateur': facteurPerturbateur,
        if (typeGlaire != null) 'typeGlaire': typeGlaire,
        'isAboveCoverline': isAboveCoverline,
        'phase': phase,
      };

  @override
  List<Object?> get props => [
        date,
        cycleDay,
        temperatureCelsius,
        heurePrise,
        estPerturbee,
        facteurPerturbateur,
        typeGlaire,
        isAboveCoverline,
        phase,
      ];
}

/// Modèle d'analyse thermique globale symptothermique (UC-16 DataViz)
class BbtAnalysisModel extends Equatable {
  final String status; // 'biphasic_confirmed' | 'follicular_phase' | 'potential_shift' | 'monophasic_suspected' | 'insufficient_data'
  final String message;
  final double? coverlineCelsius;
  final bool shiftDetected;
  final String? shiftDate;
  final double? shiftDeltaCelsius;
  final String? nadirDate;
  final double? nadirTemperatureCelsius;
  final double? follicularAvgCelsius;
  final double? lutealAvgCelsius;
  final int lutealPhaseDays;
  final List<BbtPointModel> points;

  const BbtAnalysisModel({
    required this.status,
    required this.message,
    this.coverlineCelsius,
    this.shiftDetected = false,
    this.shiftDate,
    this.shiftDeltaCelsius,
    this.nadirDate,
    this.nadirTemperatureCelsius,
    this.follicularAvgCelsius,
    this.lutealAvgCelsius,
    this.lutealPhaseDays = 0,
    required this.points,
  });

  String get statusBadgeLabel {
    switch (status) {
      case 'biphasic_confirmed':
        return 'Courbe biphasique confirmée';
      case 'potential_shift':
        return 'Décalage en confirmation';
      case 'follicular_phase':
        return 'Plateau folliculaire bas';
      case 'monophasic_suspected':
        return 'Courbe monophasique';
      default:
        return 'Mesures insuffisantes';
    }
  }

  factory BbtAnalysisModel.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString());
    }

    final pointsRaw = (json['points'] as List<dynamic>?) ?? [];

    return BbtAnalysisModel(
      status: (json['status'] as String?) ?? 'insufficient_data',
      message: (json['message'] as String?) ?? '',
      coverlineCelsius: parseDouble(json['coverlineCelsius'] ?? json['coverline_celsius']),
      shiftDetected: (json['shiftDetected'] ?? json['shift_detected']) as bool? ?? false,
      shiftDate: (json['shiftDate'] ?? json['shift_date']) as String?,
      shiftDeltaCelsius: parseDouble(json['shiftDeltaCelsius'] ?? json['shift_delta_celsius']),
      nadirDate: (json['nadirDate'] ?? json['nadir_date']) as String?,
      nadirTemperatureCelsius: parseDouble(json['nadirTemperatureCelsius'] ?? json['nadir_temperature_celsius']),
      follicularAvgCelsius: parseDouble(json['follicularAvgCelsius'] ?? json['follicular_avg_celsius']),
      lutealAvgCelsius: parseDouble(json['lutealAvgCelsius'] ?? json['luteal_avg_celsius']),
      lutealPhaseDays: ((json['lutealPhaseDays'] ?? json['luteal_phase_days']) as num?)?.toInt() ?? 0,
      points: pointsRaw.map((e) => BbtPointModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'message': message,
        if (coverlineCelsius != null) 'coverlineCelsius': coverlineCelsius,
        'shiftDetected': shiftDetected,
        if (shiftDate != null) 'shiftDate': shiftDate,
        if (shiftDeltaCelsius != null) 'shiftDeltaCelsius': shiftDeltaCelsius,
        if (nadirDate != null) 'nadirDate': nadirDate,
        if (nadirTemperatureCelsius != null) 'nadirTemperatureCelsius': nadirTemperatureCelsius,
        if (follicularAvgCelsius != null) 'follicularAvgCelsius': follicularAvgCelsius,
        if (lutealAvgCelsius != null) 'lutealAvgCelsius': lutealAvgCelsius,
        'lutealPhaseDays': lutealPhaseDays,
        'points': points.map((p) => p.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        status,
        message,
        coverlineCelsius,
        shiftDetected,
        shiftDate,
        shiftDeltaCelsius,
        nadirDate,
        nadirTemperatureCelsius,
        follicularAvgCelsius,
        lutealAvgCelsius,
        lutealPhaseDays,
        points,
      ];
}
