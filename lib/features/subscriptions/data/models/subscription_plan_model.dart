import 'package:equatable/equatable.dart';

class SubscriptionPlanModel extends Equatable {
  final String id;
  final String nom;
  final double prix;
  final String devise;
  final String periode;
  final String description;
  final bool populaire;
  final String? economie;
  final List<String> avantages;

  const SubscriptionPlanModel({
    required this.id,
    required this.nom,
    required this.prix,
    required this.devise,
    required this.periode,
    required this.description,
    required this.populaire,
    this.economie,
    required this.avantages,
  });

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  static bool _parseBool(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) return val.toLowerCase() == 'true' || val == '1';
    return false;
  }

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlanModel(
      id: json['id']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      prix: _parseDouble(json['prix']),
      devise: json['devise']?.toString() ?? 'XOF',
      periode: json['periode']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      populaire: _parseBool(json['populaire']),
      economie: json['economie']?.toString(),
      avantages: (json['avantages'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [
        id,
        nom,
        prix,
        devise,
        periode,
        description,
        populaire,
        economie,
        avantages,
      ];
}
