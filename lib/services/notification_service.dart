import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:invoicemaker/l10n/translations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'invoice_reminders';
  static const _channelName = 'Invoice Reminders';
  static const _channelDesc = 'Reminders for unpaid invoices on their due date';

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();
  }

  static NotificationDetails get _details => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  static Future<void> scheduleInvoiceReminder({
    required int invoiceId,
    required String clientName,
    required String invoiceNumber,
    required String dueDate,
  }) async {
    await cancelInvoiceReminder(invoiceId);

    // Try the formats the app uses, in order of likelihood
    final dateFormats = [
      'MMM dd, yyyy',
      'dd MMM yyyy',
      'yyyy-MM-dd',
      'dd/MM/yyyy',
    ];
    DateTime? due;
    for (final fmt in dateFormats) {
      due = DateFormat(fmt).tryParse(dueDate);
      if (due != null) break;
    }
    if (due == null) {
      debugPrint('NotificationService: could not parse due date "$dueDate"');
      return;
    }

    final scheduledDate = DateTime(due.year, due.month, due.day, 9, 0, 0);
    final now = DateTime.now();

    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('app_locale') ?? 'en';
    String t(String key) => AppTranslations.tl(lang, key);

    if (scheduledDate.isBefore(now)) {
      await _plugin.show(
        invoiceId,
        t('notif_overdue_title'),
        t('notif_overdue_body')
            .replaceAll('{number}', invoiceNumber)
            .replaceAll('{client}', clientName)
            .replaceAll('{date}', dueDate),
        _details,
      );
      return;
    }

    await _plugin.zonedSchedule(
      invoiceId,
      t('notif_due_today_title'),
      t('notif_due_today_body')
          .replaceAll('{number}', invoiceNumber)
          .replaceAll('{client}', clientName),
      tz.TZDateTime.from(scheduledDate, tz.local),
      _details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelInvoiceReminder(int invoiceId) async {
    await _plugin.cancel(invoiceId);
  }
}
