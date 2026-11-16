import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/security/secure_storage_helper.dart';
import '../../data/datasources/notification_remote_data_source.dart';
import '../../data/models/notification_model.dart';
import '../../services/local_notification_service.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final INotificationRemoteDataSource remoteDataSource;
  final SecureStorageHelper storage;
  final LocalNotificationService localNotificationService;

  NotificationBloc({
    required this.remoteDataSource,
    SecureStorageHelper? storage,
    LocalNotificationService? localNotificationService,
  })  : storage = storage ?? SecureStorageHelper(),
        localNotificationService =
            localNotificationService ?? LocalNotificationService.instance,
        super(NotificationInitialState()) {
    on<LoadNotificationsEvent>(_onLoadNotifications);
    on<LoadPreferencesEvent>(_onLoadPreferences);
    on<UpdatePreferencesEvent>(_onUpdatePreferences);
    on<MarkNotificationAsReadEvent>(_onMarkAsRead);
    on<MarkAllNotificationsAsReadEvent>(_onMarkAllAsRead);
    on<TriggerTestNotificationEvent>(_onTriggerTestNotification);
    on<EvaluateRemindersEvent>(_onEvaluateReminders);
  }

  Future<void> _onLoadNotifications(
    LoadNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (!event.silent && state is! NotificationLoadedState) {
      emit(NotificationLoadingState());
    }

    try {
      final notifsData = await remoteDataSource.getNotifications();
      final prefs = await remoteDataSource.getPreferences();

      final items = (notifsData['items'] as List<NotificationItemModel>?) ?? [];
      final unreadCount = (notifsData['unreadCount'] as int?) ??
          items.where((n) => !n.isRead).length;

      // Synchronisation des rappels planifiés & affichage des nouvelles notifications non lues
      await localNotificationService.syncScheduledReminders(prefs);
      await localNotificationService.displayNewUnreadNotifications(
        items: items,
        prefs: prefs,
        storage: storage,
      );

      emit(NotificationLoadedState(
        notifications: items,
        unreadCount: unreadCount,
        preferences: prefs,
      ));
    } catch (e) {
      if (state is NotificationLoadedState) {
        // Garder l'état existant en cas d'erreur ponctuelle
        return;
      }
      emit(NotificationErrorState(e.toString()));
    }
  }

  Future<void> _onLoadPreferences(
    LoadPreferencesEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final prefs = await remoteDataSource.getPreferences();
      await localNotificationService.syncScheduledReminders(prefs);
      if (state is NotificationLoadedState) {
        final current = state as NotificationLoadedState;
        emit(current.copyWith(preferences: prefs));
      } else {
        final notifsData = await remoteDataSource.getNotifications();
        final items = (notifsData['items'] as List<NotificationItemModel>?) ?? [];
        final unreadCount = (notifsData['unreadCount'] as int?) ??
            items.where((n) => !n.isRead).length;
        emit(NotificationLoadedState(
          notifications: items,
          unreadCount: unreadCount,
          preferences: prefs,
        ));
      }
    } catch (e) {
      if (state is! NotificationLoadedState) {
        emit(NotificationErrorState(e.toString()));
      }
    }
  }

  Future<void> _onUpdatePreferences(
    UpdatePreferencesEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoadedState) {
      final current = state as NotificationLoadedState;
      emit(current.copyWith(
        preferences: event.preferences,
        isSavingPreferences: true,
      ));

      try {
        final updated = await remoteDataSource.updatePreferences(event.preferences);
        await localNotificationService.syncScheduledReminders(updated);
        emit(current.copyWith(
          preferences: updated,
          isSavingPreferences: false,
          feedbackMessage: 'Préférences d’alertes enregistrées',
        ));
      } catch (e) {
        emit(current.copyWith(
          isSavingPreferences: false,
          feedbackMessage: 'Erreur lors de la sauvegarde',
        ));
      }
    }
  }

  Future<void> _onMarkAsRead(
    MarkNotificationAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoadedState) {
      final current = state as NotificationLoadedState;
      try {
        await remoteDataSource.markAsRead(event.id);
        final updatedList = current.notifications.map((n) {
          if (n.id == event.id) {
            return NotificationItemModel(
              id: n.id,
              type: n.type,
              canal: n.canal,
              statut: 'lue',
              titre: n.titre,
              message: n.message,
              donneesSupplementaires: n.donneesSupplementaires,
              datePlanifiee: n.datePlanifiee,
              dateEnvoi: n.dateEnvoi,
              dateLecture: DateTime.now(),
              dateCreation: n.dateCreation,
            );
          }
          return n;
        }).toList();

        final newUnread = updatedList.where((n) => !n.isRead).length;
        emit(current.copyWith(
          notifications: updatedList,
          unreadCount: newUnread,
        ));
      } catch (_) {}
    }
  }

  Future<void> _onMarkAllAsRead(
    MarkAllNotificationsAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoadedState) {
      final current = state as NotificationLoadedState;
      try {
        await remoteDataSource.markAllAsRead();
        final now = DateTime.now();
        final updatedList = current.notifications.map((n) {
          return NotificationItemModel(
            id: n.id,
            type: n.type,
            canal: n.canal,
            statut: 'lue',
            titre: n.titre,
            message: n.message,
            donneesSupplementaires: n.donneesSupplementaires,
            datePlanifiee: n.datePlanifiee,
            dateEnvoi: n.dateEnvoi,
            dateLecture: now,
            dateCreation: n.dateCreation,
          );
        }).toList();

        emit(current.copyWith(
          notifications: updatedList,
          unreadCount: 0,
          feedbackMessage: 'Toutes les alertes sont marquées comme lues',
        ));
      } catch (_) {}
    }
  }

  Future<void> _onTriggerTestNotification(
    TriggerTestNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationLoadedState) {
      final current = state as NotificationLoadedState;
      try {
        final newNotif = await remoteDataSource.sendTestNotification();
        await localNotificationService.showNotificationFromItem(newNotif);
        await storage.markNotificationIdsDisplayed([newNotif.id]);
        final updatedList = [newNotif, ...current.notifications];
        emit(current.copyWith(
          notifications: updatedList,
          unreadCount: current.unreadCount + 1,
          feedbackMessage: 'Alerte test envoyée sur votre appareil',
        ));
      } catch (e) {
        emit(current.copyWith(
          feedbackMessage: 'Impossible d’émettre l’alerte de test',
        ));
      }
    }
  }

  Future<void> _onEvaluateReminders(
    EvaluateRemindersEvent event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await remoteDataSource.evaluateReminders();
      add(const LoadNotificationsEvent(silent: true));
    } catch (_) {}
  }
}
