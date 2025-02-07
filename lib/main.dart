import 'package:campustalk/SplashScreen.dart';
import 'package:campustalk/home.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart'; // Import the permission_handler package

// Initialize the notifications plugin globally
final FlutterLocalNotificationsPlugin _notificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await Firebase.initializeApp();

  // Initialize notifications
  await initNotifications();

  runApp(const MyApp());
}

Future<void> initNotifications() async {
  // Initialize timezones to schedule notifications correctly
  tz.initializeTimeZones();

  // Android initialization settings (use your app's launcher icon)
  const AndroidInitializationSettings androidInitSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initSettings =
      InitializationSettings(android: androidInitSettings);

  // Initialize the notifications plugin
  await _notificationsPlugin.initialize(initSettings);

  if (Platform.isAndroid) {
    // Extract the Android version code correctly
    final sdkVersionString = Platform.operatingSystemVersion.split(" ")[0];

    // Remove any non-digit characters, only keeping the version number
    final sdkVersion =
        int.tryParse(sdkVersionString.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    // For Android 13 and above (API 33+), request notification permission
    if (sdkVersion >= 33) {
      // Request notification permission using permission_handler
      PermissionStatus permissionStatus =
          await Permission.notification.request();
      if (permissionStatus.isGranted) {
        print('Notification permission granted');
      } else {
        print('Notification permission denied');
      }
    } else {
      // No need to request permission for Android 10 to 12 (API 29 to 32)
      print(
          'No notification permission request needed for Android $sdkVersion');
    }
  }

  // Create a notification channel for devices running Android 8.0 (API 26) and above
  await _createNotificationChannel();
}

// Function to create a notification channel for Android 8.0 and above
Future<void> _createNotificationChannel() async {
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'your_channel_id', // Channel ID
    'Your Channel Name', // Channel Name
    importance: Importance.high,
    description: 'This is a high-priority channel for notifications.',
  );

  // Create the notification channel
  await _notificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CampusTalk',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Check if the user is logged in and navigate accordingly
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Display splash screen or loading indicator while waiting for auth state
            return const SplashScreen();
          }
          if (snapshot.hasData) {
            // User is logged in, navigate to HomePage
            return const HomePage();
          } else {
            // User is not logged in, navigate to LoginPage
            return const LoginPage();
          }
        },
      ),
    );
  }
}
