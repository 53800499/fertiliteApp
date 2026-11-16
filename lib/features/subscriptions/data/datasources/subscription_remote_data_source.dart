import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/api_exception.dart';
import '../models/subscription_model.dart';
import '../models/subscription_plan_model.dart';
import '../models/subscription_policy_model.dart';
import '../models/referral_model.dart';
import '../models/payment_transaction_model.dart';

abstract class ISubscriptionRemoteDataSource {
  Future<SubscriptionModel> getCurrentSubscription();
  Future<List<SubscriptionPlanModel>> getPlans();
  Future<SubscriptionPolicyModel> getSubscriptionPolicy();
  Future<SubscriptionModel> subscribe({
    required String plan,
    double? montant,
    String? devise,
    String? fournisseur,
  });
  Future<SubscriptionModel> cancelSubscription();
  Future<PaymentTransactionModel> initiatePayment({
    required String plan,
    String? moyenPaiement,
    String? phoneNumber,
    String? callbackUrl,
  });
  Future<Map<String, dynamic>> verifyPayment(String transactionId);
  Future<ReferralInfoModel> getReferralInfo();
  Future<Map<String, dynamic>> applyReferralCode(String code);
  Future<List<ReferralHistoryItemModel>> getReferralHistory();
}

class SubscriptionRemoteDataSourceImpl implements ISubscriptionRemoteDataSource {
  final Dio dio;

  // État local en mémoire pour tester sans blocage si le serveur distant renvoie 404
  SubscriptionModel? _localFallbackSub;

  SubscriptionRemoteDataSourceImpl({required this.dio});

  bool _isTransientOrUnavailable(DioException e) {
    final code = e.response?.statusCode;
    return code == 404 ||
        (code != null && code >= 500) ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout;
  }

  @override
  Future<SubscriptionModel> getCurrentSubscription() async {
    try {
      final response = await dio.get(ApiConstants.subscriptionsCurrent);
      _localFallbackSub = SubscriptionModel.fromJson(response.data as Map<String, dynamic>);
      return _localFallbackSub!;
    } on DioException catch (e) {
      // Si l'API distante est en veille, indisponible ou non déployée
      if (_isTransientOrUnavailable(e)) {
        return _localFallbackSub ?? _getDefaultFreeSubscription();
      }
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<SubscriptionPlanModel>> getPlans() async {
    try {
      final response = await dio.get(ApiConstants.subscriptionsPlans);
      final list = response.data as List<dynamic>;
      return list
          .map((e) => SubscriptionPlanModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      // Fallback sur le catalogue par défaut en cas d'indisponibilité réseau/serveur
      if (_isTransientOrUnavailable(e)) {
        return _getDefaultPlans();
      }
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<SubscriptionPolicyModel> getSubscriptionPolicy() async {
    try {
      final response = await dio.get(ApiConstants.subscriptionsPolicy);
      return SubscriptionPolicyModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (_isTransientOrUnavailable(e)) {
        return const SubscriptionPolicyModel();
      }
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<SubscriptionModel> subscribe({
    required String plan,
    double? montant,
    String? devise,
    String? fournisseur,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.subscriptionsSubscribe,
        data: {
          'plan': plan,
          if (montant != null) 'montant': montant,
          if (devise != null) 'devise': devise,
          'fournisseur': fournisseur ?? 'fedapay',
        },
      );
      _localFallbackSub = SubscriptionModel.fromJson(response.data as Map<String, dynamic>);
      return _localFallbackSub!;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<SubscriptionModel> cancelSubscription() async {
    try {
      final response = await dio.post(ApiConstants.subscriptionsCancel);
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('abonnement')) {
        return SubscriptionModel.fromJson(data['abonnement'] as Map<String, dynamic>);
      }
      return SubscriptionModel.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 && _localFallbackSub != null) {
        _localFallbackSub = SubscriptionModel(
          id: _localFallbackSub!.id,
          plan: _localFallbackSub!.plan,
          statut: 'annule',
          isPremium: _localFallbackSub!.isPremium,
          dateDebut: _localFallbackSub!.dateDebut,
          dateFin: _localFallbackSub!.dateFin,
          joursRestants: _localFallbackSub!.joursRestants,
          renouvellementAutomatique: false,
          fournisseur: _localFallbackSub!.fournisseur,
          montant: _localFallbackSub!.montant,
          devise: _localFallbackSub!.devise,
          libellePlan: _localFallbackSub!.libellePlan,
          avantagesActifs: _localFallbackSub!.avantagesActifs,
        );
        return _localFallbackSub!;
      }
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<PaymentTransactionModel> initiatePayment({
    required String plan,
    String? moyenPaiement,
    String? phoneNumber,
    String? callbackUrl,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.subscriptionsInitiatePayment,
        data: {
          'plan': plan,
          if (moyenPaiement != null) 'moyenPaiement': moyenPaiement,
          if (phoneNumber != null) 'phoneNumber': phoneNumber,
          if (callbackUrl != null) 'callbackUrl': callbackUrl,
        },
      );
      return PaymentTransactionModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> verifyPayment(String transactionId) async {
    try {
      final response = await dio.post(
        ApiConstants.subscriptionsVerifyPayment,
        data: {'transactionId': transactionId},
      );
      final data = response.data as Map<String, dynamic>;
      if (data.containsKey('abonnement')) {
        _localFallbackSub = SubscriptionModel.fromJson(data['abonnement'] as Map<String, dynamic>);
      }
      return data;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<ReferralInfoModel> getReferralInfo() async {
    try {
      final response = await dio.get(ApiConstants.referralsMyCode);
      return ReferralInfoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (_isTransientOrUnavailable(e)) {
        return const ReferralInfoModel(
          codeParrainage: 'FERT-AMIE7',
          lienPartage: 'https://fertiliteapp.com/invitation?ref=FERT-AMIE7',
          totalFilleules: 0,
          totalJoursGagnes: 0,
          peutUtiliserUnCode: true,
          parrainageActif: true,
          joursOffertsParFilleule: 30,
        );
      }
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> applyReferralCode(String code) async {
    try {
      final response = await dio.post(
        ApiConstants.referralsApply,
        data: {'code': code},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw ApiException.fromDioError(e);
    }
  }

  @override
  Future<List<ReferralHistoryItemModel>> getReferralHistory() async {
    try {
      final response = await dio.get(ApiConstants.referralsHistory);
      final list = response.data as List<dynamic>;
      return list
          .map((e) => ReferralHistoryItemModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (_isTransientOrUnavailable(e)) {
        return const [];
      }
      throw ApiException.fromDioError(e);
    }
  }

  // --- Données par défaut de secours ---

  SubscriptionModel _getDefaultFreeSubscription() {
    return SubscriptionModel(
      id: 'default_free',
      plan: 'gratuit',
      statut: 'actif',
      isPremium: false,
      dateDebut: DateTime.now(),
      dateFin: null,
      joursRestants: null,
      renouvellementAutomatique: false,
      fournisseur: 'systeme',
      montant: 0,
      devise: 'XOF',
      libellePlan: 'Plan Essentiel (Gratuit)',
      avantagesActifs: const [
        'Calendrier menstruel intuitif',
        'Estimation standard',
        'Saisie quotidienne des observations',
      ],
    );
  }

  List<SubscriptionPlanModel> _getDefaultPlans() {
    return const [
      SubscriptionPlanModel(
        id: 'gratuit',
        nom: 'Essentiel Physiologique (Gratuit)',
        prix: 0,
        devise: 'XOF',
        periode: 'Toujours gratuit',
        description: 'Le socle bienveillant et confidentiel pour suivre vos cycles au quotidien.',
        populaire: false,
        avantages: [
          'Calendrier menstruel intuitif',
          'Estimation physiologique de base',
          'Saisie quotidienne des observations (glaire, température, humeur)',
          'Confidentialité absolue et chiffrement des données',
          'Rappels et notifications de base',
        ],
      ),
      SubscriptionPlanModel(
        id: 'premium_mensuel',
        nom: 'Premium Sérénité (Mensuel)',
        prix: 1000,
        devise: 'XOF',
        periode: 'par mois',
        description: 'La puissance de l\'algorithme avancé et le décryptage complet de vos biomarqueurs.',
        populaire: false,
        avantages: [
          'Tous les avantages du plan Gratuit',
          'Fenêtre fertile haute précision avec indice de confiance',
          'Détection automatique du décalage thermique (courbe BBT)',
          'Export PDF du Bilan Médical de Cycle pour votre praticien',
          'Historique illimité de tous vos cycles passés',
          'Alertes anticipées et conseils personnalisés',
          'Support prioritaire dédié',
        ],
      ),
      SubscriptionPlanModel(
        id: 'premium_annuel',
        nom: 'Premium Sérénité (Annuel)',
        prix: 10000,
        devise: 'XOF',
        periode: 'par an (~833 XOF/mois)',
        description: 'Une année complète de clarté, sérénité et accompagnement avec 2 mois offerts.',
        populaire: true,
        economie: '2 mois offerts',
        avantages: [
          'Tous les avantages Premium inclus',
          '2 mois offerts par rapport au paiement mensuel',
          'Analyses comparatives multi-cycles sur 12 mois',
          'Évolution des phases lutéales et régularité',
          'Accès garanti à toutes les futures fonctionnalités de prédiction',
        ],
      ),
    ];
  }
}
