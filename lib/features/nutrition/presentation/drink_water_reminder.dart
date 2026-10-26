import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../home/data/notification_service.dart';

class DrinkWaterReminder extends StatefulWidget {
  final String? userId; // Make userId optional, will fallback to current user
  const DrinkWaterReminder({super.key, this.userId});

  @override
  State<DrinkWaterReminder> createState() => _DrinkWaterReminderState();
}

class _DrinkWaterReminderState extends State<DrinkWaterReminder> {
  int _glasses = 0;
  int _reminderInterval = 60; // minutes
  bool _notificationsEnabled = false;
  FlutterLocalNotificationsPlugin? _notifications;
  Timer? _debounce;
  bool _isLoading = false;
  DateTime? _lastResetDate;
  static const int _waterNotificationBaseId =
      5000; // ID range reserved for water reminders
  static const int _maxScheduledAheadHours =
      12; // Limit scheduling window to avoid huge batches
  static const int _maxNotificationSlots =
      32; // Hard cap for safety (e.g., 32*15min ~ 8h)

  void _log(String msg, [Object? err, StackTrace? st]) {
    debugPrint('[WaterReminder] $msg${err != null ? ' :: $err' : ''}');
    if (st != null) {
      debugPrint(st.toString());
    }
  }

  String? get _getUserId {
    // Use provided userId or get from FirebaseAuth
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      return widget.userId;
    }
    return FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void initState() {
    super.initState();
    _notifications = FlutterLocalNotificationsPlugin();
    tz.initializeTimeZones();
    _initNotifications();
    _loadSettingsFromFirestore();
    _checkResetGlasses();
  }

  Future<void> _loadSettingsFromFirestore() async {
    setState(() => _isLoading = true);

    final userId = _getUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No user logged in. Please sign in again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Use user-specific document path for proper isolation
      final userWaterDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('water_settings')
          .doc('current_settings');

      // Path is already user-scoped: users/{userId}/water_settings/current_settings
      // No need for an extra where('userId') filter that would force a composite index.
      final doc = await userWaterDoc.get();
      _log('Loaded water settings document: exists=${doc.exists}');

      if (doc.exists) {
        final data = doc.data() ?? {};
        if (mounted) {
          setState(() {
            _glasses = data['water_glasses'] ?? 0;
            _reminderInterval = data['water_reminder_interval'] ?? 60;
            _notificationsEnabled =
                data['water_notifications_enabled'] ?? false;
            final lastReset = data['water_last_reset'];
            if (lastReset != null) {
              _lastResetDate = DateTime.tryParse(lastReset);
            }
          });
        }
      }
    } catch (e, st) {
      _log('Error loading settings', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading water settings: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _saveSettings() async {
    final userId = _getUserId;
    if (userId == null) return;

    try {
      // Use user-specific document path for proper isolation
      final userWaterDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('water_settings')
          .doc('current_settings');

      await userWaterDoc.set({
        'userId': userId, // Explicit user association
        'water_glasses': _glasses,
        'water_reminder_interval': _reminderInterval,
        'water_notifications_enabled': _notificationsEnabled,
        'water_last_reset': _lastResetDate?.toIso8601String(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _log(
        'Saved water settings (glasses=$_glasses, interval=$_reminderInterval, notif=$_notificationsEnabled)',
      );
    } catch (e, st) {
      _log('Error saving settings', e, st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving water settings: $e')),
        );
      }
    }
  }

  Future<void> _checkResetGlasses() async {
    final now = DateTime.now();
    if (_lastResetDate == null ||
        now.difference(_lastResetDate!).inHours >= 24) {
      // Reset once every 24h (simple rolling window). For stricter calendar-day reset,
      // replace difference check with comparison on Date (year/month/day).
      setState(() {
        _glasses = 0;
        _lastResetDate = now;
      });
      _log('Daily reset executed');
      await _saveSettings();
    }
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );
    await _notifications?.initialize(settings);
  }

  Future<void> _cancelWaterNotifications() async {
    for (int i = 0; i < _maxNotificationSlots; i++) {
      await _notifications?.cancel(_waterNotificationBaseId + i);
    }
  }

  Future<void> _scheduleWaterNotificationsBatch() async {
    if (!_notificationsEnabled) return;
    if (_reminderInterval <= 0) return;

    // Clear previous batch in reserved range (avoid cancelling all app notifications)
    await _cancelWaterNotifications();

    final now = DateTime.now();
    final maxAhead = Duration(hours: _maxScheduledAheadHours);
    final endCutoff = now.add(maxAhead);
    int slot = 0;
    DateTime next = now.add(Duration(minutes: _reminderInterval));

    while (next.isBefore(endCutoff) && slot < _maxNotificationSlots) {
      final tzTime = tz.TZDateTime.from(next, tz.local);
      final id = _waterNotificationBaseId + slot;
      await _notifications?.zonedSchedule(
        id,
        'Drink Water Reminder',
        'Time to drink a glass of water!',
        tzTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water_channel',
            'Water Reminders',
            channelDescription: 'Periodic hydration reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'water_reminder',
      );
      _log('Scheduled water notification id=$id at $tzTime');
      slot++;
      next = next.add(Duration(minutes: _reminderInterval));
    }
    _log('Batch scheduling complete. Total scheduled: $slot');
    await _saveSettings();
  }

  void _toggleNotifications(bool value) async {
    setState(() {
      _notificationsEnabled = value;
    });
    if (value) {
      await _scheduleWaterNotificationsBatch();
    } else {
      await _cancelWaterNotifications();
      await _saveSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          color: const Color(0xFFE0F7FA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_drink,
                          color: Colors.blue[700],
                          size: 28,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Drink Water',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      activeThumbColor: Colors.blue[700],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Glasses today: ', style: TextStyle(fontSize: 15)),
                    IconButton(
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: Colors.blue[700],
                      ),
                      onPressed: _glasses > 0
                          ? () {
                              setState(() => _glasses--);
                              _log('Decrement glasses -> $_glasses');
                              _saveSettings();
                            }
                          : null,
                    ),
                    Text(
                      '$_glasses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: Colors.blue[700],
                      ),
                      onPressed: () {
                        setState(() => _glasses++);
                        _log('Increment glasses -> $_glasses');
                        _saveSettings();
                        
                        // Create water reminder notification
                        NotificationService().createWaterReminder(
                          glasses: _glasses,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Reminder every ', style: TextStyle(fontSize: 15)),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'min',
                          isDense: true,
                        ),
                        onChanged: (val) {
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(
                            const Duration(milliseconds: 700),
                            () async {
                              final parsed = int.tryParse(val);
                              if (parsed != null && parsed > 0) {
                                setState(() => _reminderInterval = parsed);
                                if (_notificationsEnabled) {
                                  await _scheduleWaterNotificationsBatch();
                                }
                                await _saveSettings();
                              }
                            },
                          );
                        },
                      ),
                    ),
                    Text(' min', style: TextStyle(fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Scheduling window: next $_maxScheduledAheadHours hours (cap $_maxNotificationSlots notifications). '
                  'Changing the interval reschedules the batch. For very long intervals only the next reminder is set.',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey[700]),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.2),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
