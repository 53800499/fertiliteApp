import 'package:equatable/equatable.dart';
import '../../data/models/notification_preferences_model.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class LoadNotificationsEvent extends NotificationEvent {
  final bool silent;
  const LoadNotificationsEvent({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

class LoadPreferencesEvent extends NotificationEvent {}

class UpdatePreferencesEvent extends NotificationEvent {
  final NotificationPreferencesModel preferences;
  const UpdatePreferencesEvent(this.preferences);

  @override
  List<Object?> get props => [preferences];
}

class MarkNotificationAsReadEvent extends NotificationEvent {
  final String id;
  const MarkNotificationAsReadEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class MarkAllNotificationsAsReadEvent extends NotificationEvent {}

class TriggerTestNotificationEvent extends NotificationEvent {}

class EvaluateRemindersEvent extends NotificationEvent {}
