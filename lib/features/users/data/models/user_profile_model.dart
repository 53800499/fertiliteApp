class UserProfileDetailModel {
  final String? prenom;
  final int dureeMoyenneCycle;
  final int dureeMoyenneRegles;
  final String objectifPrincipal;
  final bool irregulariteDeclaree;

  const UserProfileDetailModel({
    this.prenom,
    this.dureeMoyenneCycle = 28,
    this.dureeMoyenneRegles = 5,
    this.objectifPrincipal = 'concevoir',
    this.irregulariteDeclaree = false,
  });

  factory UserProfileDetailModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const UserProfileDetailModel();
    return UserProfileDetailModel(
      prenom: json['prenom'] as String?,
      dureeMoyenneCycle: (json['dureeMoyenneCycle'] as num?)?.toInt() ?? 28,
      dureeMoyenneRegles: (json['dureeMoyenneRegles'] as num?)?.toInt() ?? 5,
      objectifPrincipal: json['objectifPrincipal'] as String? ?? 'concevoir',
      irregulariteDeclaree: json['irregulariteDeclaree'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        if (prenom != null) 'prenom': prenom,
        'dureeMoyenneCycle': dureeMoyenneCycle,
        'dureeMoyenneRegles': dureeMoyenneRegles,
        'objectifPrincipal': objectifPrincipal,
        'irregulariteDeclaree': irregulariteDeclaree,
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
    return FullUserProfileModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateNaissance: json['dateNaissance'] as String?,
      languePreferee: json['languePreferee'] as String? ?? 'fr',
      fuseauHoraire: json['fuseauHoraire'] as String? ?? 'Africa/Porto-Novo',
      profil: UserProfileDetailModel.fromJson(
        json['profil'] as Map<String, dynamic>?,
      ),
      parametresConfidentialite: UserPrivacySettingsModel.fromJson(
        json['parametresConfidentialite'] as Map<String, dynamic>?,
      ),
    );
  }
}

class UpdateProfileRequestModel {
  final String? prenom;
  final int? dureeMoyenneCycle;
  final int? dureeMoyenneRegles;
  final String? objectifPrincipal;
  final bool? irregulariteDeclaree;
  final UserPrivacySettingsModel? parametresConfidentialite;

  const UpdateProfileRequestModel({
    this.prenom,
    this.dureeMoyenneCycle,
    this.dureeMoyenneRegles,
    this.objectifPrincipal,
    this.irregulariteDeclaree,
    this.parametresConfidentialite,
  });

  Map<String, dynamic> toJson() => {
        if (prenom != null) 'prenom': prenom,
        if (dureeMoyenneCycle != null) 'dureeMoyenneCycle': dureeMoyenneCycle,
        if (dureeMoyenneRegles != null) 'dureeMoyenneRegles': dureeMoyenneRegles,
        if (objectifPrincipal != null) 'objectifPrincipal': objectifPrincipal,
        if (irregulariteDeclaree != null) 'irregulariteDeclaree': irregulariteDeclaree,
        if (parametresConfidentialite != null)
          'parametresConfidentialite': parametresConfidentialite!.toJson(),
      };
}
