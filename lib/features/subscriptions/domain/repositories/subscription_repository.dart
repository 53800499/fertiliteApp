import '../../data/models/subscription_model.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../data/models/subscription_policy_model.dart';
import '../../data/models/referral_model.dart';
import '../../data/models/payment_transaction_model.dart';

abstract class ISubscriptionRepository {
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

