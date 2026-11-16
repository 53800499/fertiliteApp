import '../../domain/repositories/subscription_repository.dart';
import '../datasources/subscription_remote_data_source.dart';
import '../models/subscription_model.dart';
import '../models/subscription_plan_model.dart';
import '../models/subscription_policy_model.dart';
import '../models/referral_model.dart';
import '../models/payment_transaction_model.dart';

class SubscriptionRepositoryImpl implements ISubscriptionRepository {
  final ISubscriptionRemoteDataSource remoteDataSource;

  SubscriptionRepositoryImpl({required this.remoteDataSource});

  @override
  Future<SubscriptionModel> getCurrentSubscription() {
    return remoteDataSource.getCurrentSubscription();
  }

  @override
  Future<List<SubscriptionPlanModel>> getPlans() {
    return remoteDataSource.getPlans();
  }

  @override
  Future<SubscriptionPolicyModel> getSubscriptionPolicy() {
    return remoteDataSource.getSubscriptionPolicy();
  }

  @override
  Future<SubscriptionModel> subscribe({
    required String plan,
    double? montant,
    String? devise,
    String? fournisseur,
  }) {
    return remoteDataSource.subscribe(
      plan: plan,
      montant: montant,
      devise: devise,
      fournisseur: fournisseur,
    );
  }

  @override
  Future<SubscriptionModel> cancelSubscription() {
    return remoteDataSource.cancelSubscription();
  }

  @override
  Future<PaymentTransactionModel> initiatePayment({
    required String plan,
    String? moyenPaiement,
    String? phoneNumber,
    String? callbackUrl,
  }) {
    return remoteDataSource.initiatePayment(
      plan: plan,
      moyenPaiement: moyenPaiement,
      phoneNumber: phoneNumber,
      callbackUrl: callbackUrl,
    );
  }

  @override
  Future<Map<String, dynamic>> verifyPayment(String transactionId) {
    return remoteDataSource.verifyPayment(transactionId);
  }

  @override
  Future<ReferralInfoModel> getReferralInfo() {
    return remoteDataSource.getReferralInfo();
  }

  @override
  Future<Map<String, dynamic>> applyReferralCode(String code) {
    return remoteDataSource.applyReferralCode(code);
  }

  @override
  Future<List<ReferralHistoryItemModel>> getReferralHistory() {
    return remoteDataSource.getReferralHistory();
  }
}

