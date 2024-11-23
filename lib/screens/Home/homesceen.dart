import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/main.dart';
import 'package:to_do_app/models/task.dart';
import 'package:to_do_app/screens/login/loginscreen.dart';
import 'package:to_do_app/screens/services/Hive/task.dart';
import 'package:to_do_app/screens/services/Hive/taskprovider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class Homescreen extends StatefulWidget {
  @override
  _HomescreenState createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  @override
  Widget build(BuildContext context) {
    void _logout(BuildContext context) {
      // Logic for logging out the user
      // For example, you can clear user data, remove authentication tokens, etc.

      // Example: Navigate back to the login screen
     Get.offAll(LoginScreen()) ;// Make sure you have defined the '/login' route in your app
    }

    final taskProvider = Provider.of<TaskProvider>(context);
    final taskDates = taskProvider.tasks.map((task) => task.dateTime).toList();

    final tasksForSelectedDay = taskProvider.tasks
        .where((task) => isSameDay(
            task.dateTime, _selectedDay)) // Filter tasks by selected day
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do App'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _logout(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            // Marking dates with tasks
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                // Check if the date has any tasks assigned
                if (taskDates.contains(date)) {
                  return Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.red, // Mark tasks with red color
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }
                return SizedBox.shrink();
              },
            ),
          ),
          const SizedBox(height: 16),
           Expanded(
            child: ListView.builder(
              itemCount: taskProvider.tasks.length,
              itemBuilder: (context, index) {
                final task = taskProvider.tasks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(task.title),
                    subtitle: Text(task.dateTime.toString()),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Add Task'),
              onPressed: () async {
                



                final newTask = await showDialog<Task>(
                  context: context,
                  builder: (context) => AddTaskDialog(),
                );
                
                if (newTask != null) {
                  taskProvider.addTask(newTask);
                   scheduleNotification(newTask, (DateTime.now().millisecondsSinceEpoch % (2^31 - 1)).toInt(), );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddTaskDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController();
    DateTime? selectedDateTime;

    return AlertDialog(
      title: Text('Add New Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input field for task title
          TextField(
            controller: titleController,
            decoration: InputDecoration(hintText: 'Task Title'),
          ),
          const SizedBox(height: 16),
          
          // Button to select date
          ElevatedButton(
            onPressed: () async {
              // Show DatePicker
              final selectedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              
              if (selectedDate != null) {
                // After selecting the date, show TimePicker
                final selectedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(DateTime.now()),
                );
                
                if (selectedTime != null) {
                  // Combine the selected date and time into a DateTime object
                  selectedDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                }
              }
            },
            child: Text('Select Date & Time'),
          ),
        ],
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        // Add button
        TextButton(
          onPressed: () {
            // Ensure the date and time are selected and title is provided
            if (selectedDateTime != null && titleController.text.isNotEmpty) {
              final task = Task(
                title: titleController.text,
                dateTime: selectedDateTime!,
                id: (DateTime.now().millisecondsSinceEpoch % (2^31 - 1)).toInt(),
              );

              Navigator.pop(context, task);
            } else {
              // Show error if fields are not filled
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please fill in all fields')),
              );
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
  Future<void> scheduleNotification(Task task) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final DateTime scheduledTime = task.dateTime;

  // Set the notification details
  const NotificationDetails notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'task_channel_id', // Channel ID
      'Task Notifications', // Channel Name
      channelDescription: 'Notifications for scheduled tasks',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  // Schedule the notification
  await flutterLocalNotificationsPlugin.zonedSchedule(
    0, // Notification ID (you can increment this for multiple notifications)
    'Task Reminder', // Notification title
    task.title,
    
     // Notification body
    scheduledTime.isBefore(DateTime.now())
        ? tz.TZDateTime.from(scheduledTime.add(Duration(seconds: 10)) , tz.local)// Add 10 seconds to avoid notification in the past
        :  tz.TZDateTime.from(scheduledTime, tz.local), // Task's scheduled time
    notificationDetails,
   // Allow notification when the app is in the background
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,// Match time only
  );
}

}


