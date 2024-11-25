import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:to_do_app/models/task.dart';
import 'package:to_do_app/screens/login/loginscreen.dart';
import 'package:to_do_app/screens/login/signup.dart';
import 'package:to_do_app/screens/services/Hive/task.dart';
import 'package:to_do_app/screens/services/Hive/taskprovider.dart';
import 'firebase_options.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and open the tasks box
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox('tasksBox');

  // Initialize notifications
  await initNotifications();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize time zones
  await initTimeZone();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => TaskProvider(notificationsPlugin),
        ),
      ],
      child: MyApp(),
    ),
  );
}

Future<void> initNotifications() async {
  const AndroidInitializationSettings androidInitialization =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: androidInitialization,
  );

  await notificationsPlugin.initialize(initializationSettings);
}

Future<void> initTimeZone() async {
  tz.initializeTimeZones();
  tz.setLocalLocation(
      tz.getLocation('Asia/Dubai')); // Set your desired time zone
}

// This function schedules the notification for a task
Future<void> scheduleNotification(Task task, int id) async {
  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'channel_id', // Notification channel ID
    'To-Do Notifications', // Notification channel name
    channelDescription: 'Notifications for To-Do tasks',
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    styleInformation: BigTextStyleInformation(''),
  );

  const NotificationDetails notificationDetails = NotificationDetails(
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

// This function schedules a general reminder notification
Future<void> scheduleGeneralNotification(DateTime scheduledTime) async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'task_reminder_channel', // Channel ID
    'Task Reminders', // Channel name
    channelDescription: 'This channel is for task reminders',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true, // Play sound even while the device is idle
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await notificationsPlugin.zonedSchedule(
    0, // Notification ID
    'Task Reminder', // Notification title
    'Don\'t forget your scheduled task!', // Notification body
    tz.TZDateTime.from(scheduledTime, tz.local), // Scheduled time
    platformChannelSpecifics,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    androidScheduleMode:
        AndroidScheduleMode.exactAllowWhileIdle, // Schedule mode
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize:
          Size(ScreenUtil.defaultSize.width, ScreenUtil.defaultSize.height),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          onGenerateRoute: routes,
          debugShowCheckedModeBanner: false,
          title: 'To-Do App',
          theme: ThemeData(
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
              },
            ),
            textTheme: GoogleFonts.dmSansTextTheme(),
            primaryColor: const Color.fromARGB(255, 8, 25, 38),
          ),
          home: LoginScreen(),
        );
      },
    );
  }

  Route? routes(RouteSettings settings) {
    if (settings.name == 'LoginScreen') {
      return MaterialPageRoute(builder: (context) => LoginScreen());
    } else if (settings.name == 'SignUpScreen') {
      return MaterialPageRoute(builder: (context) => SignUpScreen());
    }
    return null;
  }
}
