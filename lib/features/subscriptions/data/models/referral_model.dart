import 'package:equatable/equatable.dart';

class ReferralInfoModel extends Equatable {
  final String codeParrainage;
  final String lienPartage;
  final int totalFilleules;
  final int totalJoursGagnes;
  final bool peutUtiliserUnCode;
  final bool parrainageActif;
  final int joursOffertsParFilleule;

  const ReferralInfoModel({
    required this.codeParrainage,
    required this.lienPartage,
    required this.totalFilleules,
    required this.totalJoursGagnes,
    required this.peutUtiliserUnCode,
    required this.parrainageActif,
    required this.joursOffertsParFilleule,
  });

  static int _parseInt(dynamic val, {int defaultValue = 0}) {
    if (val == null) return defaultValue;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  static bool _parseBool(dynamic val, {bool defaultValue = false}) {
    if (val == null) return defaultValue;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) return val.toLowerCase() == 'true' || val == '1';
    return defaultValue;
  }

  factory ReferralInfoModel.fromJson(Map<String, dynamic> json) {
    return ReferralInfoModel(
      codeParrainage: json['codeParrainage']?.toString() ?? '',
      lienPartage: json['lienPartage']?.toString() ?? '',
      totalFilleules: _parseInt(json['totalFilleules'], defaultValue: 0),
      totalJoursGagnes: _parseInt(json['totalJoursGagnes'], defaultValue: 0),
      peutUtiliserUnCode: _parseBool(json['peutUtiliserUnCode'], defaultValue: true),
      parrainageActif: _parseBool(json['parrainageActif'], defaultValue: true),
      joursOffertsParFilleule: _parseInt(json['joursOffertsParFilleule'], defaultValue: 30),
    );
  }

  @override
  List<Object?> get props => [
        codeParrainage,
        lienPartage,
        totalFilleules,
        totalJoursGagnes,
        peutUtiliserUnCode,
        parrainageActif,
        joursOffertsParFilleule,
      ];
}

class ReferralHistoryItemModel extends Equatable {
  final String id;
  final DateTime date;
  final String libelle;
  final String statut;
  final int joursGagnes;

  const ReferralHistoryItemModel({
    required this.id,
    required this.date,
    required this.libelle,
    required this.statut,
    required this.joursGagnes,
  });

  static int _parseInt(dynamic val, {int defaultValue = 30}) {
    if (val == null) return defaultValue;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  factory ReferralHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return ReferralHistoryItemModel(
      id: json['id']?.toString() ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      libelle: json['libelle']?.toString() ?? 'Amie invitée',
      statut: json['statut']?.toString() ?? 'valide',
      joursGagnes: _parseInt(json['joursGagnes'], defaultValue: 30),
    );
  }

  @override
  List<Object?> get props => [id, date, libelle, statut, joursGagnes];
}
