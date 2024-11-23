import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
// Assuming Task class is defined here
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:to_do_app/models/task.dart';
import 'package:to_do_app/screens/services/Hive/task.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  final Box _tasksBox = Hive.box('tasksBox');
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  TaskProvider(this.flutterLocalNotificationsPlugin);

  List<Task> get tasks => _tasks;

  // Add a new task and schedule a notification for it
  void addTask(Task task) {
    _tasks.add(task);
    _tasksBox.add(task); // Store task in Hive box

    // Schedule a notification for the task
    _scheduleNotification(task);

    notifyListeners();
  }

  // Remove a task and cancel its notification
  void removeTask(int index) {
    final task = _tasks[index];
    _tasks.removeAt(index);
    _tasksBox.deleteAt(index); // Remove the task from Hive box

    // Cancel the scheduled notification for this task
    _cancelNotification(task);

    notifyListeners();
  }

  // Schedule a notification for a task at its specified date and time
  Future<void> _scheduleNotification(Task task) async {
    var scheduledTime = task.dateTime;

    // Notification details (for Android)
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'task_channel_id', // Channel ID
      'Task Reminders', // Channel name
      channelDescription: 'Notifications for task reminders',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    // Schedule the notification for the task
    await flutterLocalNotificationsPlugin.zonedSchedule(
// Notification content

      task.id, // Use the task's unique ID
      'Task Reminder',
      task.title,
      tz.TZDateTime.from(
          scheduledTime, tz.local), // The time the notification will fire
      notificationDetails,

      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Cancel the scheduled notification for a task
  Future<void> _cancelNotification(Task task) async {
    await flutterLocalNotificationsPlugin
        .cancel(task.id); // Cancel the notification using the task's ID
  }
}
