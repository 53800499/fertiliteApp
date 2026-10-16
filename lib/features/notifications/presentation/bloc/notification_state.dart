import 'package:equatable/equatable.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/notification_preferences_model.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitialState extends NotificationState {}

class NotificationLoadingState extends NotificationState {}

class NotificationLoadedState extends NotificationState {
  final List<NotificationItemModel> notifications;
  final int unreadCount;
  final NotificationPreferencesModel preferences;
  final bool isSavingPreferences;
  final String? feedbackMessage;

  const NotificationLoadedState({
    required this.notifications,
    required this.unreadCount,
    required this.preferences,
    this.isSavingPreferences = false,
    this.feedbackMessage,
  });

  NotificationLoadedState copyWith({
    List<NotificationItemModel>? notifications,
    int? unreadCount,
    NotificationPreferencesModel? preferences,
    bool? isSavingPreferences,
    String? feedbackMessage,
  }) {
    return NotificationLoadedState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      preferences: preferences ?? this.preferences,
      isSavingPreferences: isSavingPreferences ?? this.isSavingPreferences,
      feedbackMessage: feedbackMessage,
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        unreadCount,
        preferences,
        isSavingPreferences,
        feedbackMessage,
      ];
}

class NotificationErrorState extends NotificationState {
  final String message;
  const NotificationErrorState(this.message);

  @override
  List<Object?> get props => [message];
}
