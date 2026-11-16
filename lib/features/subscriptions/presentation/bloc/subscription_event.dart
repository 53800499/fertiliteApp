import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

class LoadSubscriptionEvent extends SubscriptionEvent {
  final bool silent;
  const LoadSubscriptionEvent({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

class SubscribeToPlanEvent extends SubscriptionEvent {
  final String plan;
  final double? montant;
  final String? devise;

  const SubscribeToPlanEvent({
    required this.plan,
    this.montant,
    this.devise,
  });

  @override
  List<Object?> get props => [plan, montant, devise];
}

class CancelSubscriptionEvent extends SubscriptionEvent {}

class InitiatePaymentEvent extends SubscriptionEvent {
  final String plan;
  final String? moyenPaiement;
  final String? phoneNumber;

  const InitiatePaymentEvent({
    required this.plan,
    this.moyenPaiement,
    this.phoneNumber,
  });

  @override
  List<Object?> get props => [plan, moyenPaiement, phoneNumber];
}

class VerifyPaymentEvent extends SubscriptionEvent {
  final String transactionId;

  const VerifyPaymentEvent({required this.transactionId});

  @override
  List<Object?> get props => [transactionId];
}

class ClearPaymentStateEvent extends SubscriptionEvent {}

class LoadReferralInfoEvent extends SubscriptionEvent {}

class ApplyReferralCodeEvent extends SubscriptionEvent {
  final String code;

  const ApplyReferralCodeEvent({required this.code});

  @override
  List<Object?> get props => [code];
}

class LoadReferralHistoryEvent extends SubscriptionEvent {}

