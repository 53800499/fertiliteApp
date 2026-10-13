class FertileWindowModel {
  final String startDate;
  final String endDate;

  const FertileWindowModel({
    required this.startDate,
    required this.endDate,
  });

  factory FertileWindowModel.fromJson(Map<String, dynamic> json) {
    return FertileWindowModel(
      startDate: json['startDate'] as String? ?? '',
      endDate: json['endDate'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'startDate': startDate,
        'endDate': endDate,
      };
}

class FactorExplanationModel {
  final String? id;
  final String type;
  final String description;
  final double weight;
  final String direction; // 'renforce' | 'diminue' | 'neutre'
  final int displayOrder;

  const FactorExplanationModel({
    this.id,
    required this.type,
    required this.description,
    required this.weight,
    required this.direction,
    required this.displayOrder,
  });

  factory FactorExplanationModel.fromJson(Map<String, dynamic> json) {
    return FactorExplanationModel(
      id: json['id'] as String?,
      type: json['type'] as String? ?? 'historique_cycles',
      description: json['description'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 0.1,
      direction: json['direction'] as String? ?? 'neutre',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'type': type,
        'description': description,
        'weight': weight,
        'direction': direction,
        'displayOrder': displayOrder,
      };
}

class PredictionModel {
  final String predictionId;
  final String generationDate;
  final String? estimatedOvulationDate;
  final int uncertaintyMarginDays;
  final FertileWindowModel fertileWindow;
  final String fertilityCategory; // 'faible' | 'moyenne' | 'elevee'
  final double fertilityScoreValue; // 0.0 à 100.0
  final String confidenceLevel; // 'faible' | 'moyen' | 'eleve'
  final String method;
  final String algorithm;
  final String modelVersion;
  final List<FactorExplanationModel> factors;

  const PredictionModel({
    required this.predictionId,
    required this.generationDate,
    this.estimatedOvulationDate,
    required this.uncertaintyMarginDays,
    required this.fertileWindow,
    required this.fertilityCategory,
    required this.fertilityScoreValue,
    required this.confidenceLevel,
    required this.method,
    required this.algorithm,
    required this.modelVersion,
    this.factors = const [],
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    final rawFactors = json['factors'] as List<dynamic>? ?? [];
    return PredictionModel(
      predictionId: json['predictionId'] as String? ?? '',
      generationDate: json['generationDate']?.toString() ?? '',
      estimatedOvulationDate: json['estimatedOvulationDate'] as String?,
      uncertaintyMarginDays: (json['uncertaintyMarginDays'] as num?)?.toInt() ?? 2,
      fertileWindow: json['fertileWindow'] != null
          ? FertileWindowModel.fromJson(json['fertileWindow'] as Map<String, dynamic>)
          : const FertileWindowModel(startDate: '', endDate: ''),
      fertilityCategory: json['fertilityCategory'] as String? ?? 'faible',
      fertilityScoreValue: (json['fertilityScoreValue'] as num?)?.toDouble() ?? 0.0,
      confidenceLevel: json['confidenceLevel'] as String? ?? 'faible',
      method: json['method'] as String? ?? 'calendrier_statistique',
      algorithm: json['algorithm'] as String? ?? 'calendar_v1',
      modelVersion: json['modelVersion'] as String? ?? 'v1.0-calendrier',
      factors: rawFactors
          .map((f) => FactorExplanationModel.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'predictionId': predictionId,
        'generationDate': generationDate,
        if (estimatedOvulationDate != null) 'estimatedOvulationDate': estimatedOvulationDate,
        'uncertaintyMarginDays': uncertaintyMarginDays,
        'fertileWindow': fertileWindow.toJson(),
        'fertilityCategory': fertilityCategory,
        'fertilityScoreValue': fertilityScoreValue,
        'confidenceLevel': confidenceLevel,
        'method': method,
        'algorithm': algorithm,
        'modelVersion': modelVersion,
        'factors': factors.map((f) => f.toJson()).toList(),
      };
}

class CalendarDaySummaryModel {
  final String date;
  final bool isPeriodDay;
  final String? flowIntensity;
  final int? painLevel;
  final bool isFertileDay;
  final bool isOvulationDay;
  final String? fertilityCategory;
  final double? fertilityScore;
  final bool hasObservations;

  const CalendarDaySummaryModel({
    required this.date,
    required this.isPeriodDay,
    this.flowIntensity,
    this.painLevel,
    required this.isFertileDay,
    required this.isOvulationDay,
    this.fertilityCategory,
    this.fertilityScore,
    required this.hasObservations,
  });

  factory CalendarDaySummaryModel.fromJson(Map<String, dynamic> json) {
    return CalendarDaySummaryModel(
      date: json['date'] as String? ?? '',
      isPeriodDay: json['isPeriodDay'] as bool? ?? false,
      flowIntensity: json['flowIntensity'] as String?,
      painLevel: (json['painLevel'] as num?)?.toInt(),
      isFertileDay: json['isFertileDay'] as bool? ?? false,
      isOvulationDay: json['isOvulationDay'] as bool? ?? false,
      fertilityCategory: json['fertilityCategory'] as String?,
      fertilityScore: (json['fertilityScore'] as num?)?.toDouble(),
      hasObservations: json['hasObservations'] as bool? ?? false,
    );
  }
}

class CalendarMonthModel {
  final int year;
  final int month;
  final String? activeCycleId;
  final String? estimatedOvulationDate;
  final String? fertileWindowStartDate;
  final String? fertileWindowEndDate;
  final List<CalendarDaySummaryModel> days;

  const CalendarMonthModel({
    required this.year,
    required this.month,
    this.activeCycleId,
    this.estimatedOvulationDate,
    this.fertileWindowStartDate,
    this.fertileWindowEndDate,
    this.days = const [],
  });

  factory CalendarMonthModel.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'] as List<dynamic>? ?? [];
    return CalendarMonthModel(
      year: (json['year'] as num?)?.toInt() ?? DateTime.now().year,
      month: (json['month'] as num?)?.toInt() ?? DateTime.now().month,
      activeCycleId: json['activeCycleId'] as String?,
      estimatedOvulationDate: json['estimatedOvulationDate'] as String?,
      fertileWindowStartDate: json['fertileWindowStartDate'] as String?,
      fertileWindowEndDate: json['fertileWindowEndDate'] as String?,
      days: rawDays
          .map((d) => CalendarDaySummaryModel.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}
