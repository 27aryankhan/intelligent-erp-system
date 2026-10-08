import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'hitam_auth_service.dart';
import 'notification_service.dart';

const String attendanceSyncTaskKey = 'intelligent_erp_attendance_sync_task';
const String periodicAttendanceSyncUniqueName =
    'intelligent_erp_periodic_attendance_sync';

/// Background task dispatcher invoked by Android WorkManager even when
/// the app is completely closed, killed from recents, or after device reboot.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('Background Worker triggered: $taskName at ${DateTime.now()}');

    try {
      // 1. Initialize notification channels and native plugin
      await NotificationService().initialize();

      // 2. Silently re-authenticate with WebPros using saved credentials
      final authOk = await HitamAuthService().ensureAuthenticated();
      debugPrint('Background Worker: ensureAuthenticated result = $authOk');

      if (authOk) {
        // 3. Fetch latest live attendance from WebPros and push notifications
        // Detects new Present / Absent marks with faculty name, percentage diffs, <75% shortages, and evening summaries
        await NotificationService().syncAttendanceNow();

        // 4. Ensure weekly period timetable reminders and exact alarms are active
        await NotificationService().syncTimetableAndReminders();

        // 5. Check if evening attendance summary should be dispatched
        await NotificationService().checkEveningSummaryNow();
      }
      debugPrint('Background Worker: Full attendance & timetable sync completed.');
    } catch (e) {
      debugPrint('Background Worker error: $e');
    }

    return Future.value(true);
  });
}

/// Manages background task scheduling through Android WorkManager.
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  bool _initialized = false;

  /// Initialize WorkManager for background execution when the app is closed
  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      _initialized = true;
      debugPrint('BackgroundService: Workmanager initialized successfully.');
    } catch (e) {
      debugPrint('BackgroundService initialization error: $e');
    }
  }

  /// Register periodic background sync task (runs every 15 minutes even when app is closed)
  Future<void> registerAttendanceSyncTask() async {
    if (kIsWeb) return;
    try {
      if (!_initialized) {
        await initialize();
      }

      await Workmanager().registerPeriodicTask(
        periodicAttendanceSyncUniqueName,
        attendanceSyncTaskKey,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
        backoffPolicy: BackoffPolicy.linear,
        backoffPolicyDelay: const Duration(minutes: 2),
      );
      debugPrint(
          'BackgroundService: Periodic attendance sync registered (every 15m while app closed).');
    } catch (e) {
      debugPrint('BackgroundService: Failed to register periodic task: $e');
    }
  }

  /// Trigger a one-off background sync immediately
  Future<void> triggerImmediateSync() async {
    if (kIsWeb) return;
    try {
      if (!_initialized) {
        await initialize();
      }
      await Workmanager().registerOneOffTask(
        'one_off_sync_${DateTime.now().millisecondsSinceEpoch}',
        attendanceSyncTaskKey,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    } catch (_) {}
  }

  /// Cancel background sync task (e.g. on user logout)
  Future<void> cancelAttendanceSyncTask() async {
    if (kIsWeb) return;
    try {
      await Workmanager().cancelByUniqueName(periodicAttendanceSyncUniqueName);
      debugPrint('BackgroundService: Periodic task cancelled.');
    } catch (_) {}
  }

  /// Checks if credentials are saved and auto-schedules the background sync
  Future<void> checkAndScheduleIfLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('hitam_user_id');
      final savedPwd = prefs.getString('hitam_user_pwd');
      if (savedId != null &&
          savedPwd != null &&
          savedId.isNotEmpty &&
          savedPwd.isNotEmpty) {
        await registerAttendanceSyncTask();
      }
    } catch (_) {}
  }
}
