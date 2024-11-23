import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:flutter/material.dart';
// Assuming Task class is defined here
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:to_do_app/main.dart';
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
    scheduleNotification(task, task.id);

    notifyListeners();
  }

  // Remove a task and cancel its notification
  // void removeTask(int index) {
  //   final task = _tasks[index];
  //   _tasks.removeAt(index);
  //   _tasksBox.deleteAt(index); // Remove the task from Hive box

  //   // Cancel the scheduled notification for this task
  //   _cancelNotification(task);

  //   notifyListeners();
  // }

  // Schedule a notification for a task at its specified date and time
 Future<void> scheduleNotification(Task task, int id) async {
   AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    '1234567', // Notification channel ID
    'To-Do Notifications', // Notification channel name
    channelDescription: task.title,
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    styleInformation: BigTextStyleInformation(''),
  );

   NotificationDetails notificationDetails = NotificationDetails(
    android: androidDetails,
  );

  await notificationsPlugin.zonedSchedule(
    id, // Notification ID
    'Task Reminder', // Notification title
    task.title, // Notification content
    tz.TZDateTime.from(
        task.dateTime, tz.local), // Task datetime converted to TZDateTime
    notificationDetails,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    androidScheduleMode:
        AndroidScheduleMode.exactAllowWhileIdle, // Schedule mode
  );
}

  // Cancel the scheduled notification for a task
  Future<void> _cancelNotification(Task task) async {
    await flutterLocalNotificationsPlugin
        .cancel(task.id); // Cancel the notification using the task's ID
  }
}
