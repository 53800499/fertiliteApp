class ConsentementModel {
  final String id;
  final String typeConsentement;
  final String versionDocument;
  final bool accepte;
  final String? dateConsentement;
  final String? dateRetrait;

  const ConsentementModel({
    required this.id,
    required this.typeConsentement,
    required this.versionDocument,
    required this.accepte,
    this.dateConsentement,
    this.dateRetrait,
  });

  factory ConsentementModel.fromJson(Map<String, dynamic> json) {
    return ConsentementModel(
      id: json['id'] as String? ?? '',
      typeConsentement: json['typeConsentement'] as String? ?? '',
      versionDocument: json['versionDocument'] as String? ?? '1.0',
      accepte: json['accepte'] as bool? ?? false,
      dateConsentement: json['dateConsentement'] as String?,
      dateRetrait: json['dateRetrait'] as String?,
    );
  }
}

class ActiveSessionModel {
  final String id;
  final String nomAppareil;
  final String plateforme;
  final String dateConnexion;
  final String? derniereActivite;

  const ActiveSessionModel({
    required this.id,
    required this.nomAppareil,
    required this.plateforme,
    required this.dateConnexion,
    this.derniereActivite,
  });

  factory ActiveSessionModel.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['dateDerniereUtilisation'] ??
            json['dateConnexion'] ??
            json['dateCreation'] ??
            json['createdAt'] ??
            '')
        .toString();

    return ActiveSessionModel(
      id: json['id'] as String? ?? '',
      nomAppareil: (json['nomAppareil'] as String?)?.isNotEmpty == true
          ? json['nomAppareil'] as String
          : 'Appareil mobile',
      plateforme: json['plateforme'] as String? ?? 'android',
      dateConnexion: rawDate,
      derniereActivite: (json['derniereActivite'] ?? json['dateDerniereUtilisation']) as String?,
    );
  }
}
