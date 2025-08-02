import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smiley/services/notifications.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 21, minute: 0);
  int _notificationCount = 3;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final startHour = prefs.getInt('startHour') ?? 9;
    final startMinute = prefs.getInt('startMinute') ?? 0;
    final endHour = prefs.getInt('endHour') ?? 21;
    final endMinute = prefs.getInt('endMinute') ?? 0;
    final count = prefs.getInt('notificationCount') ?? 3;

    setState(() {
      _startTime = TimeOfDay(hour: startHour, minute: startMinute);
      _endTime = TimeOfDay(hour: endHour, minute: endMinute);
      _notificationCount = count;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt('startHour', _startTime.hour);
    await prefs.setInt('startMinute', _startTime.minute);
    await prefs.setInt('endHour', _endTime.hour);
    await prefs.setInt('endMinute', _endTime.minute);
    await prefs.setInt('notificationCount', _notificationCount);

    print("Start Time: ${_startTime.format(context)}");
    print("End Time: ${_endTime.format(context)}");
    print("Notification Count: $_notificationCount");

    // Clear previous notifications
    await NotificationService().cancelAllNotifications();

    // Schedule new ones
    await _scheduleNotifications();
  }

  Future<void> _scheduleNotifications() async {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
      _startTime.hour,
      _startTime.minute,
    );
    final end = DateTime(
      now.year,
      now.month,
      now.day,
      _endTime.hour,
      _endTime.minute,
    );

    final totalMinutes = end.difference(start).inMinutes;

    if (totalMinutes <= 0) {
      debugPrint("Invalid time range.");
      return;
    }

    final interval = totalMinutes ~/ (_notificationCount - 1);

    for (int i = 0; i < _notificationCount; i++) {
      final minutesFromStart = interval * i;
      final notifyTime = start.add(Duration(minutes: minutesFromStart));

      await NotificationService().scheduleNotification(
        id: i,
        hour: notifyTime.hour,
        minute: notifyTime.minute,
        title: 'Smile Reminder 😊',
        body: 'This is your #${i + 1} smile reminder!',
      );
    }

    debugPrint("Notifications scheduled successfully.");
  }

  Future<void> _selectTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                NotificationService().showNotification(
                  title: 'Hello!',
                  body: 'This is a notification from the Home Page.',
                );
              },
              child: const Text('Show Notification'),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Start Time:"),
                TextButton(
                  onPressed: () => _selectTime(isStart: true),
                  child: Text(_startTime.format(context)),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("End Time:"),
                TextButton(
                  onPressed: () => _selectTime(isStart: false),
                  child: Text(_endTime.format(context)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Notifications per day:"),
                Text("$_notificationCount"),
              ],
            ),
            Slider(
              value: _notificationCount.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: '$_notificationCount',
              onChanged: (double value) {
                setState(() {
                  _notificationCount = value.toInt();
                });
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveSettings,
              child: const Text('Save Settings & Schedule'),
            ),
          ],
        ),
      ),
    );
  }
}
