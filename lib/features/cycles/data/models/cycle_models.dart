class JourReglesModel {
  final String id;
  final String cycleId;
  final String date;
  final String intensiteFlux;
  final int? douleurNiveau;
  final String? notes;

  const JourReglesModel({
    required this.id,
    required this.cycleId,
    required this.date,
    required this.intensiteFlux,
    this.douleurNiveau,
    this.notes,
  });

  factory JourReglesModel.fromJson(Map<String, dynamic> json) {
    return JourReglesModel(
      id: json['id'] as String? ?? '',
      cycleId: json['cycleId'] as String? ?? '',
      date: json['date'] as String? ?? '',
      intensiteFlux: json['intensiteFlux'] as String? ?? 'moyen',
      douleurNiveau: (json['douleurNiveau'] as num?)?.toInt(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'cycleId': cycleId,
        'date': date,
        'intensiteFlux': intensiteFlux,
        if (douleurNiveau != null) 'douleurNiveau': douleurNiveau,
        if (notes != null) 'notes': notes,
      };
}

class CycleModel {
  final String id;
  final String dateDebut;
  final String? dateFin;
  final int? dureeCycleJours;
  final int? dureeReglesJours;
  final String statut;
  final List<JourReglesModel> joursRegles;

  const CycleModel({
    required this.id,
    required this.dateDebut,
    this.dateFin,
    this.dureeCycleJours,
    this.dureeReglesJours,
    required this.statut,
    this.joursRegles = const [],
  });

  factory CycleModel.fromJson(Map<String, dynamic> json) {
    final rawJours = json['joursRegles'] as List<dynamic>? ?? [];
    return CycleModel(
      id: json['id'] as String? ?? '',
      dateDebut: json['dateDebut'] as String? ?? '',
      dateFin: json['dateFin'] as String?,
      dureeCycleJours: (json['dureeCycleJours'] as num?)?.toInt(),
      dureeReglesJours: (json['dureeReglesJours'] as num?)?.toInt(),
      statut: json['statut'] as String? ?? 'en_cours',
      joursRegles: rawJours
          .map((j) => JourReglesModel.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isEnCours => statut == 'en_cours';

  /// Jour du cycle actuel (1-indexed) par rapport à la date de début
  int get currentCycleDay {
    try {
      final start = DateTime.parse(dateDebut);
      final today = DateTime.now();
      final diff = today.difference(start).inDays + 1;
      return diff > 0 ? diff : 1;
    } catch (_) {
      return 1;
    }
  }
}

class StartCycleRequestModel {
  final String dateDebut;
  final String? intensiteFlux;
  final int? douleurNiveau;
  final String? notes;

  const StartCycleRequestModel({
    required this.dateDebut,
    this.intensiteFlux = 'moyen',
    this.douleurNiveau,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'dateDebut': dateDebut,
        if (intensiteFlux != null) 'intensiteFlux': intensiteFlux,
        if (douleurNiveau != null) 'douleurNiveau': douleurNiveau,
        if (notes != null) 'notes': notes,
      };
}

class LogFlowRequestModel {
  final String date;
  final String intensiteFlux;
  final int? douleurNiveau;
  final String? notes;

  const LogFlowRequestModel({
    required this.date,
    required this.intensiteFlux,
    this.douleurNiveau,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'intensiteFlux': intensiteFlux,
        if (douleurNiveau != null) 'douleurNiveau': douleurNiveau,
        if (notes != null) 'notes': notes,
      };
}

class UpdateCycleRequestModel {
  final String? dateDebut;
  final String? dateFin;
  final String? statut;

  const UpdateCycleRequestModel({
    this.dateDebut,
    this.dateFin,
    this.statut,
  });

  Map<String, dynamic> toJson() => {
        if (dateDebut != null) 'dateDebut': dateDebut,
        if (dateFin != null) 'dateFin': dateFin,
        if (statut != null) 'statut': statut,
      };
}

class CycleHistoryItemModel {
  final String cycleId;
  final String dateDebut;
  final String? dateFin;
  final int? dureeCycleJours;
  final int? dureeReglesJours;
  final String statut;

  const CycleHistoryItemModel({
    required this.cycleId,
    required this.dateDebut,
    this.dateFin,
    this.dureeCycleJours,
    this.dureeReglesJours,
    required this.statut,
  });

  factory CycleHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return CycleHistoryItemModel(
      cycleId: json['cycleId'] as String? ?? '',
      dateDebut: json['dateDebut'] as String? ?? '',
      dateFin: json['dateFin'] as String?,
      dureeCycleJours: (json['dureeCycleJours'] as num?)?.toInt(),
      dureeReglesJours: (json['dureeReglesJours'] as num?)?.toInt(),
      statut: json['statut'] as String? ?? 'termine',
    );
  }
}

class CycleStatsModel {
  final int totalCycles;
  final int completedCycles;
  final double averageDuration;
  final int minDuration;
  final int maxDuration;
  final double standardDeviation;
  final String regularity;
  final double averagePeriodDuration;
  final List<CycleHistoryItemModel> history;

  const CycleStatsModel({
    required this.totalCycles,
    required this.completedCycles,
    required this.averageDuration,
    required this.minDuration,
    required this.maxDuration,
    required this.standardDeviation,
    required this.regularity,
    required this.averagePeriodDuration,
    required this.history,
  });

  factory CycleStatsModel.fromJson(Map<String, dynamic> json) {
    final rawHistory = json['history'] as List<dynamic>? ?? [];
    return CycleStatsModel(
      totalCycles: (json['totalCycles'] as num?)?.toInt() ?? 0,
      completedCycles: (json['completedCycles'] as num?)?.toInt() ?? 0,
      averageDuration: (json['averageDuration'] as num?)?.toDouble() ?? 28.0,
      minDuration: (json['minDuration'] as num?)?.toInt() ?? 28,
      maxDuration: (json['maxDuration'] as num?)?.toInt() ?? 28,
      standardDeviation: (json['standardDeviation'] as num?)?.toDouble() ?? 0.0,
      regularity: json['regularity'] as String? ?? 'indetermine',
      averagePeriodDuration: (json['averagePeriodDuration'] as num?)?.toDouble() ?? 5.0,
      history: rawHistory
          .map((h) => CycleHistoryItemModel.fromJson(h as Map<String, dynamic>))
          .toList(),
    );
  }

  String get regularityLabel {
    switch (regularity) {
      case 'tres_regulier':
        return 'Très régulier (< 2 j)';
      case 'regulier':
        return 'Régulier (± 2-4 j)';
      case 'irregulier':
        return 'Irrégulier (> 4 j)';
      default:
        return 'Données insuffisantes';
    }
  }
}

