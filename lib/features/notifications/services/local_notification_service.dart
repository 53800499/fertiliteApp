import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:workmanager/workmanager.dart';

import '../../../core/network/api_client.dart';
import '../../../core/security/secure_storage_helper.dart';
import '../data/datasources/notification_remote_data_source.dart';
import '../data/models/notification_model.dart';
import '../data/models/notification_preferences_model.dart';

/// Point d'entrée natif utilisé par Workmanager dans un isolate en arrière-plan
/// lorsque l'application est fermée ou tuée.
@pragma('vm:entry-point')
void notificationBackgroundDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    return LocalNotificationService.runBackgroundSync();
  });
}

/// Service centralisant les notifications système natives (locales, planifiées
/// et synchronisées en arrière-plan même lorsque l'application est fermée).
class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  static const String _channelId = 'fertilite_alerts_channel';
  static const String _channelName = 'Alertes & Rappels FertiliteApp';
  static const String _channelDescription =
      'Rappels quotidiens de saisie, fenêtre fertile et alertes de cycle.';

  static const String backgroundSyncUniqueName =
      'fertilite_notifications_periodic_sync';
  static const String backgroundSyncTaskName = 'fertilite_notifications_sync';

  static const int _dailyReminderId = 1001;
  static const int _fertileWindowId = 1002;
  static const int _expectedPeriodId = 1003;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _backgroundRegistered = false;
  bool _tzInitialized = false;
  void Function(String? payload)? _onNotificationTap;

  /// Initialise le plugin de notifications natives et les fuseaux horaires locaux.
  Future<void> init({
    bool requestPermissions = false,
    void Function(String? payload)? onNotificationTap,
  }) async {
    if (onNotificationTap != null) {
      _onNotificationTap = onNotificationTap;
    }

    await _ensureTimezoneConfigured();

    if (!_initialized) {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Ouvrir FertiliteApp',
      );
      const windowsSettings = WindowsInitializationSettings(
        appName: 'FertiliteApp',
        appUserModelId: 'Femax.FertiliteApp.Desktop.1',
        guid: 'b9d4c2b6-4f9b-4f88-9b70-48e0e8b21a11',
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
        linux: linuxSettings,
        windows: windowsSettings,
      );

      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          _onNotificationTap?.call(response.payload);
        },
      );

      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.high,
          ),
        );
      }

      _initialized = true;
    }

    if (requestPermissions) {
      await _requestOsPermissions();
    }
  }

  /// Vérifie si l'application a été ouverte depuis une notification système.
  Future<String?> consumeLaunchPayload() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      if (details != null && details.didNotificationLaunchApp) {
        return details.notificationResponse?.payload;
      }
    } catch (_) {}
    return null;
  }

  /// Enregistre la tâche périodique Workmanager (Android/iOS) pour récupérer
  /// les notifications même lorsque l'application est fermée.
  Future<void> registerBackgroundSync() async {
    if (_backgroundRegistered) return;
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    try {
      await Workmanager().initialize(notificationBackgroundDispatcher);
      await Workmanager().registerPeriodicTask(
        backgroundSyncUniqueName,
        backgroundSyncTaskName,
        frequency: const Duration(minutes: 15),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        constraints: Constraints(networkType: NetworkType.connected),
      );
      _backgroundRegistered = true;
    } catch (_) {
      // Plateforme ou simulateur non compatible
    }
  }

  /// Affiche immédiatement une notification système pour un élément reçu.
  Future<void> showNotificationFromItem(NotificationItemModel item) async {
    await showInstant(
      id: _stableNotificationId(item.id),
      title: item.titre,
      body: item.message,
      payload: item.id,
    );
  }

  /// Affiche une notification système immédiate dans le tiroir du téléphone.
  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await init(requestPermissions: false);
    }

    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _defaultNotificationDetails(),
        payload: payload,
      );
    } catch (_) {}
  }

  /// Affiche les nouvelles notifications non lues (non encore affichées en bannière)
  /// et mémorise leurs identifiants pour éviter tout doublon.
  Future<void> displayNewUnreadNotifications({
    required List<NotificationItemModel> items,
    required NotificationPreferencesModel prefs,
    required SecureStorageHelper storage,
  }) async {
    if (!prefs.canalPush || items.isEmpty) return;

    final displayedIds = await storage.getDisplayedNotificationIds();
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    final newlyDisplayed = <String>[];

    for (final item in items) {
      if (item.isRead || item.id.startsWith('demo-')) continue;
      if (displayedIds.contains(item.id)) continue;

      final eventTime = item.dateEnvoi ?? item.datePlanifiee;
      if (eventTime.isAfter(cutoff)) {
        await showNotificationFromItem(item);
      }
      newlyDisplayed.add(item.id);
    }

    if (newlyDisplayed.isNotEmpty) {
      await storage.markNotificationIdsDisplayed(newlyDisplayed);
    }
  }

  /// Programme ou annule le rappel quotidien local selon les préférences de l'utilisatrice.
  /// Fonctionne hors-ligne et même si l'application est fermée.
  Future<void> syncScheduledReminders(NotificationPreferencesModel prefs) async {
    if (!_initialized) {
      await init(requestPermissions: false);
    }

    try {
      await _plugin.cancel(id: _dailyReminderId);
    } catch (_) {}

    if (!prefs.rappelSaisieActif || !prefs.canalPush) return;

    final parts = prefs.heureRappelSaisie.split(':');
    final hour = (parts.isNotEmpty ? int.tryParse(parts[0]) : null) ?? 20;
    final minute = (parts.length > 1 ? int.tryParse(parts[1]) : null) ?? 0;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour.clamp(0, 23),
      minute.clamp(0, 59),
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _zonedScheduleWithFallback(
      id: _dailyReminderId,
      title: '🌿 Moment d’écoute : Vos observations du jour',
      body:
          'Prenez un instant pour noter votre température, glaire ou symptômes du jour.',
      scheduledDate: scheduled,
      payload: 'rappel_saisie',
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Programme les alertes locales de fenêtre fertile et règles prévues (même hors-ligne).
  Future<void> syncPredictionSchedules({
    required NotificationPreferencesModel prefs,
    DateTime? fertileStart,
    DateTime? nextPeriodDate,
  }) async {
    if (!_initialized) {
      await init(requestPermissions: false);
    }

    await _scheduleSingleDayAlert(
      id: _fertileWindowId,
      enabled: prefs.canalPush && prefs.alerteFenetreFertile,
      targetDate: fertileStart?.subtract(const Duration(days: 1)),
      title: '🌸 Fenêtre fertile imminente',
      body:
          'Votre période de fertilité optimale débute demain. Consultez votre calendrier.',
      payload: 'fenetre_fertile',
    );

    await _scheduleSingleDayAlert(
      id: _expectedPeriodId,
      enabled: prefs.canalPush && prefs.alerteReglesPrevues,
      targetDate: nextPeriodDate?.subtract(const Duration(days: 1)),
      title: '🩸 Prévision des prochaines règles',
      body:
          'Selon vos cycles précédents, vos prochaines règles pourraient arriver demain.',
      payload: 'regles_prevues',
    );
  }

  /// Annule toutes les notifications planifiées (ex: lors de la déconnexion).
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Tâche exécutée en arrière-plan par Workmanager (app en pause ou fermée).
  static Future<bool> runBackgroundSync() async {
    try {
      final storage = SecureStorageHelper();
      final hasToken = await storage.hasAccessToken();
      if (!hasToken) {
        return true;
      }

      await instance.init(requestPermissions: false);

      final apiClient = ApiClient(storage: storage);
      final remote = NotificationRemoteDataSourceImpl(dio: apiClient.dio);

      try {
        await remote.evaluateReminders();
      } catch (_) {}

      final prefs = await remote.getPreferences();
      final notifsData = await remote.getNotifications();
      final items = (notifsData['items'] as List<NotificationItemModel>?) ?? [];

      await instance.syncScheduledReminders(prefs);
      await instance.displayNewUnreadNotifications(
        items: items,
        prefs: prefs,
        storage: storage,
      );
      return true;
    } catch (_) {
      return true;
    }
  }

  Future<void> _scheduleSingleDayAlert({
    required int id,
    required bool enabled,
    required DateTime? targetDate,
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}

    if (!enabled || targetDate == null) return;

    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime(
      tz.local,
      targetDate.year,
      targetDate.month,
      targetDate.day,
      8,
      30,
    );
    if (!scheduled.isAfter(now)) return;

    await _zonedScheduleWithFallback(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      payload: payload,
    );
  }

  Future<void> _zonedScheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final details = _defaultNotificationDetails();
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
        payload: payload,
      );
    } catch (_) {
      // Fallback automatique si Android 14+ refuse les alarmes exactes
      try {
        await _plugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: matchDateTimeComponents,
          payload: payload,
        );
      } catch (_) {}
    }
  }

  Future<void> _ensureTimezoneConfigured() async {
    if (_tzInitialized) return;
    tz_data.initializeTimeZones();
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Porto-Novo'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
    _tzInitialized = true;
  }

  Future<void> _requestOsPermissions() async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        await androidImpl?.requestNotificationsPermission();
      } else if (!kIsWeb && Platform.isIOS) {
        final iosImpl = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (_) {}
  }

  NotificationDetails _defaultNotificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const linuxDetails = LinuxNotificationDetails();
    const windowsDetails = WindowsNotificationDetails();

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
      linux: linuxDetails,
      windows: windowsDetails,
    );
  }

  int _stableNotificationId(String rawId) {
    return (rawId.hashCode & 0x7FFFFFFF).clamp(2000, 0x7FFFFFFE);
  }
}

