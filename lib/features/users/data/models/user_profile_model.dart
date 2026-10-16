class UserProfileDetailModel {
  final String? prenom;
  final int dureeMoyenneCycle;
  final int dureeMoyenneRegles;
  final String objectifPrincipal;
  final bool irregulariteDeclaree;
  final String? dateDernieresReglesConnues;

  const UserProfileDetailModel({
    this.prenom,
    this.dureeMoyenneCycle = 28,
    this.dureeMoyenneRegles = 5,
    this.objectifPrincipal = 'suivi_cycle',
    this.irregulariteDeclaree = false,
    this.dateDernieresReglesConnues,
  });

  factory UserProfileDetailModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserProfileDetailModel();

    // Normalisation de l'objectif
    String rawObj = (json['objectifPrincipal'] ?? json['objectif_principal'] ?? 'suivi_cycle').toString();
    if (rawObj == 'concevoir') rawObj = 'planifier_grossesse';
    if (rawObj == 'contraception_naturelle') rawObj = 'eviter_grossesse';
    if (rawObj == 'suivre_cycle') rawObj = 'suivi_cycle';

    final rawIrreg = json['irregulariteDeclaree'] ?? json['irregularite_declaree'];
    final bool isIrreg = rawIrreg is bool
        ? rawIrreg
        : (rawIrreg == 1 || rawIrreg == '1' || rawIrreg == 'true');

    return UserProfileDetailModel(
      prenom: (json['prenom'] ?? json['nom']) as String?,
      dureeMoyenneCycle: ((json['dureeCycleHabituelleJours'] ??
              json['duree_cycle_habituelle_jours'] ??
              json['dureeMoyenneCycle'] ??
              28) as num)
          .toInt(),
      dureeMoyenneRegles: ((json['dureeReglesHabituelleJours'] ??
              json['duree_regles_habituelle_jours'] ??
              json['dureeMoyenneRegles'] ??
              5) as num)
          .toInt(),
      objectifPrincipal: rawObj,
      irregulariteDeclaree: isIrreg,
      dateDernieresReglesConnues: (json['dateDernieresReglesConnues'] ??
          json['date_dernieres_regles_connues']) as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (prenom != null) 'prenom': prenom,
        'dureeMoyenneCycle': dureeMoyenneCycle,
        'dureeCycleHabituelleJours': dureeMoyenneCycle,
        'dureeMoyenneRegles': dureeMoyenneRegles,
        'dureeReglesHabituelleJours': dureeMoyenneRegles,
        'objectifPrincipal': objectifPrincipal,
        'irregulariteDeclaree': irregulariteDeclaree,
        if (dateDernieresReglesConnues != null)
          'dateDernieresReglesConnues': dateDernieresReglesConnues,
      };
}

class UserPrivacySettingsModel {
  final bool partageDonneesRecherche;
  final bool notificationsActivees;
  final bool verrouillageBiometrique;
  final bool masquageDonneesSensibles;

  const UserPrivacySettingsModel({
    this.partageDonneesRecherche = false,
    this.notificationsActivees = true,
    this.verrouillageBiometrique = false,
    this.masquageDonneesSensibles = false,
  });

  factory UserPrivacySettingsModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserPrivacySettingsModel();
    return UserPrivacySettingsModel(
      partageDonneesRecherche: json['partageDonneesRecherche'] as bool? ?? false,
      notificationsActivees: json['notificationsActivees'] as bool? ?? true,
      verrouillageBiometrique: json['verrouillageBiometrique'] as bool? ?? false,
      masquageDonneesSensibles: json['masquageDonneesSensibles'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'partageDonneesRecherche': partageDonneesRecherche,
        'notificationsActivees': notificationsActivees,
        'verrouillageBiometrique': verrouillageBiometrique,
        'masquageDonneesSensibles': masquageDonneesSensibles,
      };
}

class FullUserProfileModel {
  final String id;
  final String email;
  final String? dateNaissance;
  final String languePreferee;
  final String fuseauHoraire;
  final UserProfileDetailModel profil;
  final UserPrivacySettingsModel parametresConfidentialite;

  const FullUserProfileModel({
    required this.id,
    required this.email,
    this.dateNaissance,
    this.languePreferee = 'fr',
    this.fuseauHoraire = 'Africa/Porto-Novo',
    required this.profil,
    required this.parametresConfidentialite,
  });

  factory FullUserProfileModel.fromJson(Map<String, dynamic> json) {
    // Si la réponse contient la clé 'profil' imbriquée
    // ou si json est directement l'entité ProfilUtilisateur
    final Map<String, dynamic>? profilJson = (json.containsKey('profil') && json['profil'] is Map<String, dynamic>)
        ? json['profil'] as Map<String, dynamic>
        : (json.containsKey('dureeCycleHabituelleJours') ||
                json.containsKey('dureeMoyenneCycle') ||
                json.containsKey('objectifPrincipal')
            ? json
            : null);

    return FullUserProfileModel(
      id: json['id'] as String? ?? json['utilisateurId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateNaissance: json['dateNaissance'] as String?,
      languePreferee: json['languePreferee'] as String? ?? 'fr',
      fuseauHoraire: json['fuseauHoraire'] as String? ?? 'Africa/Porto-Novo',
      profil: UserProfileDetailModel.fromJson(profilJson),
      parametresConfidentialite: UserPrivacySettingsModel.fromJson(
        json['parametresConfidentialite'] as Map<String, dynamic>?,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        if (dateNaissance != null) 'dateNaissance': dateNaissance,
        'languePreferee': languePreferee,
        'fuseauHoraire': fuseauHoraire,
        'profil': profil.toJson(),
        'parametresConfidentialite': parametresConfidentialite.toJson(),
      };
}

class UpdateProfileRequestModel {
  final String? prenom;
  final int? dureeMoyenneCycle;
  final int? dureeMoyenneRegles;
  final String? objectifPrincipal;
  final bool? irregulariteDeclaree;
  final String? dateDernieresReglesConnues;
  final UserPrivacySettingsModel? parametresConfidentialite;

  const UpdateProfileRequestModel({
    this.prenom,
    this.dureeMoyenneCycle,
    this.dureeMoyenneRegles,
    this.objectifPrincipal,
    this.irregulariteDeclaree,
    this.dateDernieresReglesConnues,
    this.parametresConfidentialite,
  });

  Map<String, dynamic> toJson() {
    String? normalizedObjective = objectifPrincipal;
    if (normalizedObjective == 'concevoir') normalizedObjective = 'planifier_grossesse';
    if (normalizedObjective == 'contraception_naturelle') normalizedObjective = 'eviter_grossesse';
    if (normalizedObjective == 'suivre_cycle') normalizedObjective = 'suivi_cycle';

    final data = <String, dynamic>{};
    if (prenom != null) data['prenom'] = prenom;
    if (dureeMoyenneCycle != null) {
      data['dureeCycleHabituelleJours'] = dureeMoyenneCycle;
      data['dureeMoyenneCycle'] = dureeMoyenneCycle;
    }
    if (dureeMoyenneRegles != null) {
      data['dureeReglesHabituelleJours'] = dureeMoyenneRegles;
      data['dureeMoyenneRegles'] = dureeMoyenneRegles;
    }
    if (normalizedObjective != null) {
      data['objectifPrincipal'] = normalizedObjective;
    }
    if (irregulariteDeclaree != null) {
      data['irregulariteDeclaree'] = irregulariteDeclaree;
    }
    if (dateDernieresReglesConnues != null) {
      data['dateDernieresReglesConnues'] = dateDernieresReglesConnues;
    }
    return data;
  }
}
