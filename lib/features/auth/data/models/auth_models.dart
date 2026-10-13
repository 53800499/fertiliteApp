class AuthUserModel {
  final String id;
  final String email;
  final bool emailVerified;

  const AuthUserModel({
    required this.id,
    required this.email,
    required this.emailVerified,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      emailVerified: json['emailVerified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'emailVerified': emailVerified,
      };
}

class AuthTokensModel {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;

  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn = 900,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresIn: json['expiresIn'] as int? ?? 900,
    );
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresIn': expiresIn,
      };
}

class AuthResponseModel {
  final AuthUserModel user;
  final AuthTokensModel tokens;

  const AuthResponseModel({
    required this.user,
    required this.tokens,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      user: AuthUserModel.fromJson(
        json['user'] as Map<String, dynamic>? ?? {},
      ),
      tokens: AuthTokensModel.fromJson(
        json['tokens'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class LoginRequestModel {
  final String email;
  final String password;
  final String? deviceName;
  final String? platform;

  const LoginRequestModel({
    required this.email,
    required this.password,
    this.deviceName,
    this.platform,
  });

  Map<String, dynamic> toJson() => {
        'email': email.trim().toLowerCase(),
        'password': password,
        if (deviceName != null) 'deviceName': deviceName,
        if (platform != null) 'platform': platform,
      };
}

class ConsentItemModel {
  final String type;
  final String version;
  final bool accepted;

  const ConsentItemModel({
    required this.type,
    this.version = '1.0',
    required this.accepted,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'version': version,
        'accepted': accepted,
      };
}

class RegisterRequestModel {
  final String email;
  final String password;
  final String birthDate; // YYYY-MM-DD
  final String? preferredLanguage;
  final String? timezone;
  final List<ConsentItemModel> consents;

  const RegisterRequestModel({
    required this.email,
    required this.password,
    required this.birthDate,
    this.preferredLanguage = 'fr',
    this.timezone = 'Africa/Porto-Novo',
    required this.consents,
  });

  Map<String, dynamic> toJson() => {
        'email': email.trim().toLowerCase(),
        'password': password,
        'birthDate': birthDate,
        if (preferredLanguage != null) 'preferredLanguage': preferredLanguage,
        if (timezone != null) 'timezone': timezone,
        'consents': consents.map((c) => c.toJson()).toList(),
      };
}
