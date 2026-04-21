import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 👈 ضرورية للحفظ
import 'dart:convert'; // 👈 ضرورية لفك شفرة البيانات
import 'login_page.dart';
import 'home_page.dart'; // 👈 تأكد من استيراد صفحة الـ Home
import 'firebase_options.dart';

// 🔔 messaging
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تشغيل Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 2. تشغيل Messaging للـ Mobile
  if (!kIsWeb) {
    await initMessaging();
  }

  // 3. التثبت من وجود مستخدم مسجل دخول سابقاً
  final prefs = await SharedPreferences.getInstance();
  final String? userRawData = prefs.getString('user_data');

  Widget initialScreen;

  if (userRawData != null) {
    // إذا لقينا بيانات، نبعثوها للـ Home مباشرة
    initialScreen = HomePage(userData: jsonDecode(userRawData));
  } else {
    // إذا مالقيناش، نفتحو صفحة الـ Login
    initialScreen = const LoginPage();
  }

  runApp(MyApp(firstScreen: initialScreen));
}

// 🔔 Firebase Messaging setup
Future<void> initMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();
  String? token = await messaging.getToken();
  print("FCM Token: $token");

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("New message: ${message.notification?.title}");
  });
}

class MyApp extends StatelessWidget {
  final Widget firstScreen;
  const MyApp({super.key, required this.firstScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bargou Gym',
      theme: ThemeData.dark(), // استعملنا الـ Dark كـ افتراضي
      home: firstScreen, // يفتح الصفحة اللي قررها الـ main
    );
  }
}
