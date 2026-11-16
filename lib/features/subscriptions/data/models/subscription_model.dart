import 'package:equatable/equatable.dart';

class SubscriptionModel extends Equatable {
  final String id;
  final String plan;
  final String statut;
  final bool isPremium;
  final DateTime dateDebut;
  final DateTime? dateFin;
  final int? joursRestants;
  final bool renouvellementAutomatique;
  final String fournisseur;
  final double montant;
  final String devise;
  final String libellePlan;
  final List<String> avantagesActifs;

  const SubscriptionModel({
    required this.id,
    required this.plan,
    required this.statut,
    required this.isPremium,
    required this.dateDebut,
    this.dateFin,
    this.joursRestants,
    required this.renouvellementAutomatique,
    required this.fournisseur,
    required this.montant,
    required this.devise,
    required this.libellePlan,
    required this.avantagesActifs,
  });

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  static int? _parseInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }

  static bool _parseBool(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) return val.toLowerCase() == 'true' || val == '1';
    return false;
  }

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id']?.toString() ?? '',
      plan: json['plan']?.toString() ?? 'gratuit',
      statut: json['statut']?.toString() ?? 'actif',
      isPremium: _parseBool(json['isPremium']),
      dateDebut: json['dateDebut'] != null
          ? DateTime.tryParse(json['dateDebut'].toString()) ?? DateTime.now()
          : DateTime.now(),
      dateFin: json['dateFin'] != null
          ? DateTime.tryParse(json['dateFin'].toString())
          : null,
      joursRestants: _parseInt(json['joursRestants']),
      renouvellementAutomatique: _parseBool(json['renouvellementAutomatique']),
      fournisseur: json['fournisseur']?.toString() ?? 'systeme',
      montant: _parseDouble(json['montant']),
      devise: json['devise']?.toString() ?? 'XOF',
      libellePlan: json['libellePlan']?.toString() ?? 'Plan Essentiel (Gratuit)',
      avantagesActifs: (json['avantagesActifs'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan': plan,
      'statut': statut,
      'isPremium': isPremium,
      'dateDebut': dateDebut.toIso8601String(),
      'dateFin': dateFin?.toIso8601String(),
      'joursRestants': joursRestants,
      'renouvellementAutomatique': renouvellementAutomatique,
      'fournisseur': fournisseur,
      'montant': montant,
      'devise': devise,
      'libellePlan': libellePlan,
      'avantagesActifs': avantagesActifs,
    };
  }

  @override
  List<Object?> get props => [
        id,
        plan,
        statut,
        isPremium,
        dateDebut,
        dateFin,
        joursRestants,
        renouvellementAutomatique,
        fournisseur,
        montant,
        devise,
        libellePlan,
        avantagesActifs,
      ];
}
