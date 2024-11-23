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
  Future<void> initNotifications() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings( android: androidInit,
   );

    await notificationsPlugin.initialize(initSettings);
  }

  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  await Hive.openBox('tasksBox');
  await initTimeZone();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => TaskProvider(
                notificationsPlugin)), // Provide the TaskProvider here
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // URLConstants.setContext(context);

    return ScreenUtilInit(
        designSize:
            Size(ScreenUtil.defaultSize.width, ScreenUtil.defaultSize.height),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return GetMaterialApp(
            onGenerateRoute: routes,
            // useInheritedMediaQuery: true,
            // locale: DevicePreview.locale(context),
            // builder: DevicePreview.appBuilder,

            debugShowCheckedModeBanner: false,
            title: 'Senfine  Online Portal',
            theme: ThemeData(
                useMaterial3: false,
                pageTransitionsTheme: const PageTransitionsTheme(builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder()
                }),
                textTheme: GoogleFonts.dmSansTextTheme(),
                primaryColor: Color.fromARGB(255, 8, 25, 38)),
            home: LoginScreen(),
          );
        });
  }

  Route? routes(RouteSettings settings) {
    if (settings.name == 'LoginScreen') {
      return MaterialPageRoute(
        builder: (context) {
          return LoginScreen();
        },
      );
    } else if (settings.name == 'SignUpScreen') {
      return MaterialPageRoute(
        builder: (context) {
          return SignUpScreen();
        },
      );
    }
  }
}

Future<void> initTimeZone() async {
  tz.initializeTimeZones();
  tz.setLocalLocation(
      tz.getLocation('Asia/Dubai')); // Set your desired time zone
}

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
