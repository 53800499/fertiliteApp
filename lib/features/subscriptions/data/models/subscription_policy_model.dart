import 'package:equatable/equatable.dart';

/// Politique d'abonnement globale configurée par le Super Admin depuis le back-office.
class SubscriptionPolicyModel extends Equatable {
  final bool exigenceAbonnementInitiale;
  final bool exigencePaywallsPremium;
  final String? messageRecommandation;

  const SubscriptionPolicyModel({
    this.exigenceAbonnementInitiale = false,
    this.exigencePaywallsPremium = true,
    this.messageRecommandation,
  });

  factory SubscriptionPolicyModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionPolicyModel(
      exigenceAbonnementInitiale: _parseBool(json['exigenceAbonnementInitiale'], fallback: false),
      exigencePaywallsPremium: _parseBool(json['exigencePaywallsPremium'], fallback: true),
      messageRecommandation: json['messageRecommandation']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exigenceAbonnementInitiale': exigenceAbonnementInitiale,
      'exigencePaywallsPremium': exigencePaywallsPremium,
      if (messageRecommandation != null) 'messageRecommandation': messageRecommandation,
    };
  }

  static bool _parseBool(dynamic val, {required bool fallback}) {
    if (val == null) return fallback;
    if (val is bool) return val;
    final s = val.toString().toLowerCase().trim();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return fallback;
  }

  @override
  List<Object?> get props => [
        exigenceAbonnementInitiale,
        exigencePaywallsPremium,
        messageRecommandation,
      ];
}

