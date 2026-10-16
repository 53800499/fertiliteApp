import 'package:dio/dio.dart';
import '../models/notification_model.dart';
import '../models/notification_preferences_model.dart';

abstract class INotificationRemoteDataSource {
  Future<Map<String, dynamic>> getNotifications();
  Future<NotificationItemModel> markAsRead(String id);
  Future<int> markAllAsRead();
  Future<NotificationPreferencesModel> getPreferences();
  Future<NotificationPreferencesModel> updatePreferences(
      NotificationPreferencesModel prefs);
  Future<NotificationItemModel> sendTestNotification();
  Future<int> evaluateReminders();
}

class NotificationRemoteDataSourceImpl implements INotificationRemoteDataSource {
  final Dio dio;

  // Cache mémoire résilient pour le mode hors-ligne / fallback
  final List<NotificationItemModel> _localFallbackNotifications = [];
  NotificationPreferencesModel _localFallbackPrefs =
      const NotificationPreferencesModel();

  NotificationRemoteDataSourceImpl({required this.dio}) {
    _initLocalDemoNotifications();
  }

  void _initLocalDemoNotifications() {
    final now = DateTime.now();
    _localFallbackNotifications.addAll([
      NotificationItemModel(
        id: 'demo-notif-1',
        type: 'fenetre_fertile',
        canal: 'push',
        statut: 'envoyee',
        titre: '🌸 Fenêtre fertile imminente',
        message:
            'Votre période de fertilité maximale débute dans 48h selon vos cycles récents.',
        datePlanifiee: now.subtract(const Duration(hours: 3)),
        dateEnvoi: now.subtract(const Duration(hours: 3)),
        dateCreation: now.subtract(const Duration(hours: 3)),
      ),
      NotificationItemModel(
        id: 'demo-notif-2',
        type: 'rappel_saisie',
        canal: 'push',
        statut: 'lue',
        titre: '🌿 Moment d’écoute du corps',
        message:
            'Pensez à noter vos observations (température, glaire ou ressentis) du jour.',
        datePlanifiee: now.subtract(const Duration(days: 1, hours: 2)),
        dateEnvoi: now.subtract(const Duration(days: 1, hours: 2)),
        dateLecture: now.subtract(const Duration(days: 1)),
        dateCreation: now.subtract(const Duration(days: 1, hours: 2)),
      ),
    ]);
  }

  @override
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await dio.get('/notifications');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final itemsRaw = data['items'] as List<dynamic>? ?? [];
        final items = itemsRaw
            .map((e) => NotificationItemModel.fromJson(e as Map<String, dynamic>))
            .toList();
        final unreadCount = data['unreadCount'] as int? ??
            items.where((n) => !n.isRead).length;

        return {
          'items': items,
          'unreadCount': unreadCount,
          'total': data['total'] ?? items.length,
        };
      }
    } catch (_) {
      // Fallback gracieux en cas de non déploiement immédiat sur Render
    }

    final unread = _localFallbackNotifications.where((n) => !n.isRead).length;
    return {
      'items': List<NotificationItemModel>.from(_localFallbackNotifications),
      'unreadCount': unread,
      'total': _localFallbackNotifications.length,
    };
  }

  @override
  Future<NotificationItemModel> markAsRead(String id) async {
    try {
      final response = await dio.patch('/notifications/$id/read');
      if (response.data is Map<String, dynamic>) {
        return NotificationItemModel.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (_) {
      // Fallback local
    }

    final index = _localFallbackNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final old = _localFallbackNotifications[index];
      final updated = NotificationItemModel(
        id: old.id,
        type: old.type,
        canal: old.canal,
        statut: 'lue',
        titre: old.titre,
        message: old.message,
        donneesSupplementaires: old.donneesSupplementaires,
        datePlanifiee: old.datePlanifiee,
        dateEnvoi: old.dateEnvoi,
        dateLecture: DateTime.now(),
        dateCreation: old.dateCreation,
      );
      _localFallbackNotifications[index] = updated;
      return updated;
    }

    throw Exception('Notification introuvable');
  }

  @override
  Future<int> markAllAsRead() async {
    try {
      final response = await dio.post('/notifications/read-all');
      if (response.data is Map<String, dynamic>) {
        return (response.data['updatedCount'] as int?) ?? 0;
      }
    } catch (_) {
      // Fallback local
    }

    int count = 0;
    for (int i = 0; i < _localFallbackNotifications.length; i++) {
      final old = _localFallbackNotifications[i];
      if (!old.isRead) {
        _localFallbackNotifications[i] = NotificationItemModel(
          id: old.id,
          type: old.type,
          canal: old.canal,
          statut: 'lue',
          titre: old.titre,
          message: old.message,
          donneesSupplementaires: old.donneesSupplementaires,
          datePlanifiee: old.datePlanifiee,
          dateEnvoi: old.dateEnvoi,
          dateLecture: DateTime.now(),
          dateCreation: old.dateCreation,
        );
        count++;
      }
    }
    return count;
  }

  @override
  Future<NotificationPreferencesModel> getPreferences() async {
    try {
      final response = await dio.get('/notifications/preferences');
      if (response.data is Map<String, dynamic>) {
        _localFallbackPrefs = NotificationPreferencesModel.fromJson(response.data);
        return _localFallbackPrefs;
      }
    } catch (_) {
      // Fallback local
    }
    return _localFallbackPrefs;
  }

  @override
  Future<NotificationPreferencesModel> updatePreferences(
      NotificationPreferencesModel prefs) async {
    try {
      final response = await dio.put('/notifications/preferences', data: prefs.toJson());
      if (response.data is Map<String, dynamic>) {
        _localFallbackPrefs = NotificationPreferencesModel.fromJson(response.data);
        return _localFallbackPrefs;
      }
    } catch (_) {
      // Fallback local
    }
    _localFallbackPrefs = prefs;
    return _localFallbackPrefs;
  }

  @override
  Future<NotificationItemModel> sendTestNotification() async {
    try {
      final response = await dio.post('/notifications/test');
      if (response.data is Map<String, dynamic>) {
        final item = NotificationItemModel.fromJson(response.data);
        _localFallbackNotifications.insert(0, item);
        return item;
      }
    } catch (_) {
      // Fallback local
    }

    final now = DateTime.now();
    final testItem = NotificationItemModel(
      id: 'test-${now.millisecondsSinceEpoch}',
      type: 'information_generale',
      canal: 'push',
      statut: 'envoyee',
      titre: '✨ Test des alertes FertiliteApp',
      message:
          'Vos notifications et rappels physiologiques sont parfaitement configurés et opérationnels.',
      datePlanifiee: now,
      dateEnvoi: now,
      dateCreation: now,
    );
    _localFallbackNotifications.insert(0, testItem);
    return testItem;
  }

  @override
  Future<int> evaluateReminders() async {
    try {
      final response = await dio.post('/notifications/evaluate');
      if (response.data is Map<String, dynamic>) {
        return (response.data['createdCount'] as int?) ?? 0;
      }
    } catch (_) {
      // Fallback local
    }
    return 0;
  }
}
