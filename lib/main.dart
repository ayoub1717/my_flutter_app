import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'login_page.dart';
import 'home_page.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  // 1. ضرورية جداً باش الـ SharedPreferences والـ Firebase يخدموا قبل الـ runApp
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تشغيل Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. تشغيل Messaging للـ Mobile فقط
  if (!kIsWeb) {
    await initMessaging();
  }

  // 4. التثبت من وجود مستخدم مسجل دخول سابقاً
  final prefs = await SharedPreferences.getInstance();
  final String? userRawData = prefs.getString('user_data');

  Widget initialScreen;

  if (userRawData != null) {
    try {
      // إذا لقينا بيانات، نبعثوها للـ Home مباشرة
      initialScreen = HomePage(userData: jsonDecode(userRawData));
    } catch (e) {
      // في حالة وجود خطأ في فك التشفير، نرجع للـ Login للسلامة
      initialScreen = const LoginPage();
    }
  } else {
    // إذا مالقيناش، نفتحو صفحة الـ Login
    initialScreen = const LoginPage();
  }

  runApp(MyApp(firstScreen: initialScreen));
}

// إعدادات الإشعارات
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
      theme: ThemeData.dark(),
      home: firstScreen,
    );
  }
}
