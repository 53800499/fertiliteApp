import 'package:equatable/equatable.dart';
import '../../../../core/error/api_exception.dart';
import '../../data/models/subscription_model.dart';
import '../../data/models/subscription_plan_model.dart';
import '../../data/models/subscription_policy_model.dart';
import '../../data/models/referral_model.dart';
import '../../data/models/payment_transaction_model.dart';

abstract class SubscriptionState extends Equatable {
  const SubscriptionState();

  @override
  List<Object?> get props => [];
}

class SubscriptionInitialState extends SubscriptionState {}

class SubscriptionLoadingState extends SubscriptionState {}

class SubscriptionLoadedState extends SubscriptionState {
  final SubscriptionModel subscription;
  final List<SubscriptionPlanModel> plans;
  final SubscriptionPolicyModel policy;
  final ReferralInfoModel? referralInfo;
  final List<ReferralHistoryItemModel>? referralHistory;
  final bool isSubmitting;
  final String? successMessage;
  final String? errorMessage;
  final String? errorTitle;
  final PaymentTransactionModel? activePaymentTransaction;
  final bool isInitiatingPayment;
  final bool isVerifyingPayment;
  final String? paymentMessage;

  const SubscriptionLoadedState({
    required this.subscription,
    required this.plans,
    this.policy = const SubscriptionPolicyModel(),
    this.referralInfo,
    this.referralHistory,
    this.isSubmitting = false,
    this.successMessage,
    this.errorMessage,
    this.errorTitle,
    this.activePaymentTransaction,
    this.isInitiatingPayment = false,
    this.isVerifyingPayment = false,
    this.paymentMessage,
  });

  SubscriptionLoadedState copyWith({
    SubscriptionModel? subscription,
    List<SubscriptionPlanModel>? plans,
    SubscriptionPolicyModel? policy,
    ReferralInfoModel? referralInfo,
    List<ReferralHistoryItemModel>? referralHistory,
    bool? isSubmitting,
    String? successMessage,
    String? errorMessage,
    String? errorTitle,
    PaymentTransactionModel? activePaymentTransaction,
    bool? isInitiatingPayment,
    bool? isVerifyingPayment,
    String? paymentMessage,
    bool clearActivePayment = false,
  }) {
    return SubscriptionLoadedState(
      subscription: subscription ?? this.subscription,
      plans: plans ?? this.plans,
      policy: policy ?? this.policy,
      referralInfo: referralInfo ?? this.referralInfo,
      referralHistory: referralHistory ?? this.referralHistory,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      successMessage: successMessage,
      errorMessage: errorMessage,
      errorTitle: errorTitle,
      activePaymentTransaction: clearActivePayment
          ? null
          : (activePaymentTransaction ?? this.activePaymentTransaction),
      isInitiatingPayment: isInitiatingPayment ?? this.isInitiatingPayment,
      isVerifyingPayment: isVerifyingPayment ?? this.isVerifyingPayment,
      paymentMessage: paymentMessage,
    );
  }

  @override
  List<Object?> get props => [
        subscription,
        plans,
        policy,
        referralInfo,
        referralHistory,
        isSubmitting,
        successMessage,
        errorMessage,
        errorTitle,
        activePaymentTransaction,
        isInitiatingPayment,
        isVerifyingPayment,
        paymentMessage,
      ];
}

class SubscriptionFailureState extends SubscriptionState {
  final String errorMessage;
  final String? title;
  final ApiException? exception;

  const SubscriptionFailureState({
    required this.errorMessage,
    this.title,
    this.exception,
  });

  @override
  List<Object?> get props => [errorMessage, title, exception];
}

