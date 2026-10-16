class NotificationPreferencesModel {
  final bool rappelSaisieActif;
  final String heureRappelSaisie;
  final bool alerteFenetreFertile;
  final bool alerteReglesPrevues;
  final bool canalPush;
  final bool canalEmail;
  final bool canalInApp;
  final String? fcmToken;

  const NotificationPreferencesModel({
    this.rappelSaisieActif = true,
    this.heureRappelSaisie = '20:00',
    this.alerteFenetreFertile = true,
    this.alerteReglesPrevues = true,
    this.canalPush = true,
    this.canalEmail = false,
    this.canalInApp = true,
    this.fcmToken,
  });

  NotificationPreferencesModel copyWith({
    bool? rappelSaisieActif,
    String? heureRappelSaisie,
    bool? alerteFenetreFertile,
    bool? alerteReglesPrevues,
    bool? canalPush,
    bool? canalEmail,
    bool? canalInApp,
    String? fcmToken,
  }) {
    return NotificationPreferencesModel(
      rappelSaisieActif: rappelSaisieActif ?? this.rappelSaisieActif,
      heureRappelSaisie: heureRappelSaisie ?? this.heureRappelSaisie,
      alerteFenetreFertile: alerteFenetreFertile ?? this.alerteFenetreFertile,
      alerteReglesPrevues: alerteReglesPrevues ?? this.alerteReglesPrevues,
      canalPush: canalPush ?? this.canalPush,
      canalEmail: canalEmail ?? this.canalEmail,
      canalInApp: canalInApp ?? this.canalInApp,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic val, bool fallback) {
      if (val == null) return fallback;
      if (val is bool) return val;
      if (val is num) return val != 0;
      if (val is String) {
        final lower = val.trim().toLowerCase();
        return lower == 'true' || lower == '1' || lower == 't';
      }
      return fallback;
    }

    String parseString(dynamic val, String fallback) {
      if (val == null) return fallback;
      final str = val.toString().trim();
      return str.isEmpty ? fallback : str;
    }

    return NotificationPreferencesModel(
      rappelSaisieActif: parseBool(
          json['rappelSaisieActif'] ?? json['rappel_saisie_actif'], true),
      heureRappelSaisie: parseString(
          json['heureRappelSaisie'] ?? json['heure_rappel_saisie'], '20:00'),
      alerteFenetreFertile: parseBool(
          json['alerteFenetreFertile'] ?? json['alerte_fenetre_fertile'], true),
      alerteReglesPrevues: parseBool(
          json['alerteReglesPrevues'] ?? json['alerte_regles_prevues'], true),
      canalPush:
          parseBool(json['canalPush'] ?? json['canal_push'], true),
      canalEmail:
          parseBool(json['canalEmail'] ?? json['canal_email'], false),
      canalInApp:
          parseBool(json['canalInApp'] ?? json['canal_in_app'], true),
      fcmToken: json['fcmToken']?.toString() ?? json['fcm_token']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'rappelSaisieActif': rappelSaisieActif,
        'heureRappelSaisie': heureRappelSaisie,
        'alerteFenetreFertile': alerteFenetreFertile,
        'alerteReglesPrevues': alerteReglesPrevues,
        'canalPush': canalPush,
        'canalEmail': canalEmail,
        'canalInApp': canalInApp,
        if (fcmToken != null) 'fcmToken': fcmToken,
      };
}
