import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/api_exception.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../../data/models/subscription_policy_model.dart';
import 'subscription_event.dart';
import 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final ISubscriptionRepository subscriptionRepository;

  SubscriptionBloc({required this.subscriptionRepository})
      : super(SubscriptionInitialState()) {
    on<LoadSubscriptionEvent>(_onLoadSubscription);
    on<SubscribeToPlanEvent>(_onSubscribeToPlan);
    on<CancelSubscriptionEvent>(_onCancelSubscription);
    on<LoadReferralInfoEvent>(_onLoadReferralInfo);
    on<ApplyReferralCodeEvent>(_onApplyReferralCode);
    on<LoadReferralHistoryEvent>(_onLoadReferralHistory);
    on<InitiatePaymentEvent>(_onInitiatePayment);
    on<VerifyPaymentEvent>(_onVerifyPayment);
    on<ClearPaymentStateEvent>(_onClearPaymentState);
  }

  Future<void> _onLoadSubscription(
    LoadSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final previousLoaded = state is SubscriptionLoadedState ? state as SubscriptionLoadedState : null;
    if (!event.silent && previousLoaded == null) {
      emit(SubscriptionLoadingState());
    }

    try {
      final sub = await subscriptionRepository.getCurrentSubscription();
      final plans = await subscriptionRepository.getPlans();
      var policy = previousLoaded?.policy;
      try {
        policy = await subscriptionRepository.getSubscriptionPolicy();
      } catch (_) {}
      var refInfo = previousLoaded?.referralInfo;
      try {
        refInfo = await subscriptionRepository.getReferralInfo();
      } catch (_) {}

      emit(SubscriptionLoadedState(
        subscription: sub,
        plans: plans,
        policy: policy ?? const SubscriptionPolicyModel(),
        referralInfo: refInfo,
        referralHistory: previousLoaded?.referralHistory,
      ));
    } on ApiException catch (e) {
      if (previousLoaded != null) {
        if (!event.silent) {
          emit(previousLoaded.copyWith(
            errorMessage: e.message,
            errorTitle: 'Actualisation impossible',
          ));
        }
      } else {
        emit(SubscriptionFailureState(
          errorMessage: e.message,
          title: 'Erreur Abonnement',
          exception: e,
        ));
      }
    } catch (e) {
      if (previousLoaded != null) {
        if (!event.silent) {
          emit(previousLoaded.copyWith(
            errorMessage: e.toString(),
            errorTitle: 'Actualisation impossible',
          ));
        }
      } else {
        emit(SubscriptionFailureState(
          errorMessage: e.toString(),
          title: 'Erreur Inattendue',
        ));
      }
    }
  }

  Future<void> _onSubscribeToPlan(
    SubscribeToPlanEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final currentState = state;
    if (currentState is SubscriptionLoadedState) {
      emit(currentState.copyWith(isSubmitting: true, successMessage: null));
    }

    try {
      final updatedSub = await subscriptionRepository.subscribe(
        plan: event.plan,
        montant: event.montant,
        devise: event.devise,
      );

      if (state is SubscriptionLoadedState) {
        final current = state as SubscriptionLoadedState;
        emit(current.copyWith(
          subscription: updatedSub,
          isSubmitting: false,
          successMessage: 'Bienvenue dans l\'expérience Premium Sérénité ! Vos fonctionnalités avancées sont actives. 🎉',
        ));
      } else {
        add(const LoadSubscriptionEvent(silent: true));
      }
    } on ApiException catch (e) {
      if (currentState is SubscriptionLoadedState) {
        emit(currentState.copyWith(
          isSubmitting: false,
          errorMessage: e.message,
          errorTitle: 'Échec de la souscription',
        ));
      } else {
        emit(SubscriptionFailureState(
          errorMessage: e.message,
          title: 'Échec de la souscription',
          exception: e,
        ));
      }
    } catch (e) {
      if (currentState is SubscriptionLoadedState) {
        emit(currentState.copyWith(
          isSubmitting: false,
          errorMessage: e.toString(),
          errorTitle: 'Erreur',
        ));
      } else {
        emit(SubscriptionFailureState(
          errorMessage: e.toString(),
          title: 'Erreur',
        ));
      }
    }
  }

  Future<void> _onCancelSubscription(
    CancelSubscriptionEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final currentState = state;
    if (currentState is SubscriptionLoadedState) {
      emit(currentState.copyWith(isSubmitting: true));
    }

    try {
      final updatedSub = await subscriptionRepository.cancelSubscription();

      if (state is SubscriptionLoadedState) {
        final current = state as SubscriptionLoadedState;
        emit(current.copyWith(
          subscription: updatedSub,
          isSubmitting: false,
          successMessage: 'Le renouvellement automatique a bien été interrompu. Vous conservez vos accès jusqu\'au terme prévu.',
        ));
      }
    } on ApiException catch (e) {
      if (currentState is SubscriptionLoadedState) {
        emit(currentState.copyWith(
          isSubmitting: false,
          errorMessage: e.message,
          errorTitle: 'Erreur résiliation',
        ));
      } else {
        emit(SubscriptionFailureState(
          errorMessage: e.message,
          title: 'Erreur résiliation',
          exception: e,
        ));
      }
    }
  }

  Future<void> _onLoadReferralInfo(
    LoadReferralInfoEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final refInfo = await subscriptionRepository.getReferralInfo();
      if (state is SubscriptionLoadedState) {
        final current = state as SubscriptionLoadedState;
        emit(current.copyWith(referralInfo: refInfo));
      }
    } catch (_) {}
  }

  Future<void> _onApplyReferralCode(
    ApplyReferralCodeEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final currentState = state;
    if (currentState is SubscriptionLoadedState) {
      emit(currentState.copyWith(isSubmitting: true));
    }

    try {
      final res = await subscriptionRepository.applyReferralCode(event.code);
      final message = res['message'] as String? ?? 'Code parrainage appliqué avec succès !';

      final updatedSub = await subscriptionRepository.getCurrentSubscription();
      final updatedRefInfo = await subscriptionRepository.getReferralInfo();

      if (state is SubscriptionLoadedState) {
        final current = state as SubscriptionLoadedState;
        emit(current.copyWith(
          subscription: updatedSub,
          referralInfo: updatedRefInfo,
          isSubmitting: false,
          successMessage: message,
        ));
      }
    } on ApiException catch (e) {
      if (currentState is SubscriptionLoadedState) {
        emit(currentState.copyWith(
          isSubmitting: false,
          errorMessage: e.message,
          errorTitle: 'Code invalide',
        ));
      } else {
        emit(SubscriptionFailureState(
          errorMessage: e.message,
          title: 'Code invalide',
          exception: e,
        ));
      }
    } catch (e) {
      if (currentState is SubscriptionLoadedState) {
        emit(currentState.copyWith(
          isSubmitting: false,
          errorMessage: e.toString(),
          errorTitle: 'Erreur',
        ));
      } else {
        emit(SubscriptionFailureState(
          errorMessage: e.toString(),
          title: 'Erreur',
        ));
      }
    }
  }

  Future<void> _onLoadReferralHistory(
    LoadReferralHistoryEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    try {
      final history = await subscriptionRepository.getReferralHistory();
      if (state is SubscriptionLoadedState) {
        final current = state as SubscriptionLoadedState;
        emit(current.copyWith(referralHistory: history));
      }
    } catch (_) {}
  }

  Future<void> _onInitiatePayment(
    InitiatePaymentEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SubscriptionLoadedState) return;

    emit(currentState.copyWith(
      isInitiatingPayment: true,
      paymentMessage: 'Initialisation de la passerelle de paiement FedaPay...',
    ));

    try {
      final transaction = await subscriptionRepository.initiatePayment(
        plan: event.plan,
        moyenPaiement: event.moyenPaiement,
        phoneNumber: event.phoneNumber,
      );

      emit(currentState.copyWith(
        isInitiatingPayment: false,
        activePaymentTransaction: transaction,
        paymentMessage: transaction.message,
      ));
    } on ApiException catch (e) {
      emit(currentState.copyWith(
        isInitiatingPayment: false,
        paymentMessage: null,
        errorMessage: e.message,
        errorTitle: 'Erreur FedaPay',
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isInitiatingPayment: false,
        paymentMessage: null,
        errorMessage: e.toString(),
        errorTitle: 'Erreur Paiement',
      ));
    }
  }

  Future<void> _onVerifyPayment(
    VerifyPaymentEvent event,
    Emitter<SubscriptionState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SubscriptionLoadedState) return;

    emit(currentState.copyWith(
      isVerifyingPayment: true,
      paymentMessage: 'Vérification de la confirmation opérateur en cours...',
    ));

    try {
      final result = await subscriptionRepository.verifyPayment(event.transactionId);
      final isApproved = result['status'] == 'approved' || result['approved'] == true;

      if (isApproved) {
        final updatedSub = await subscriptionRepository.getCurrentSubscription();
        emit(currentState.copyWith(
          subscription: updatedSub,
          isVerifyingPayment: false,
          clearActivePayment: true,
          successMessage: result['message'] as String? ?? 'Paiement confirmé ! Votre abonnement Premium est activé.',
          paymentMessage: null,
        ));
      } else {
        emit(currentState.copyWith(
          isVerifyingPayment: false,
          paymentMessage: result['message'] as String? ?? 'Le paiement n\'a pas encore été finalisé.',
        ));
      }
    } on ApiException catch (e) {
      emit(currentState.copyWith(
        isVerifyingPayment: false,
        paymentMessage: null,
        errorMessage: e.message,
        errorTitle: 'Échec de vérification',
      ));
    } catch (e) {
      emit(currentState.copyWith(
        isVerifyingPayment: false,
        paymentMessage: null,
        errorMessage: e.toString(),
        errorTitle: 'Erreur Vérification',
      ));
    }
  }

  void _onClearPaymentState(
    ClearPaymentStateEvent event,
    Emitter<SubscriptionState> emit,
  ) {
    if (state is SubscriptionLoadedState) {
      emit((state as SubscriptionLoadedState).copyWith(
        clearActivePayment: true,
        isInitiatingPayment: false,
        isVerifyingPayment: false,
        paymentMessage: null,
      ));
    }
  }
}

