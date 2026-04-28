import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'login_page.dart';
import 'home_page.dart';
import 'firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 1. 🔥 لازم تكون خارج الـ main وبرا أي Class (Top-level function)
// هذي اللي تفيق التليفون كي تبدا الـ App مسكرة
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("Handling background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. تشغيل Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 3. تشغيل الـ Background Handler للـ Mobile
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await initMessaging();
  }

  final prefs = await SharedPreferences.getInstance();
  final String? userRawData = prefs.getString('user_data');

  Widget initialScreen;
  if (userRawData != null) {
    try {
      initialScreen = HomePage(userData: jsonDecode(userRawData));
    } catch (e) {
      initialScreen = const LoginPage();
    }
  } else {
    initialScreen = const LoginPage();
  }

  runApp(MyApp(firstScreen: initialScreen));
}

// إعدادات الإشعارات
Future<void> initMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // طلب الترخيص
  await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 4. 🔥 الاشتراك في الـ Topic (هذا هو اللي يخلي الـ PHP يبعث للناس الكل)
  await messaging.subscribeToTopic('gym_chat');

  // اختيار الـ Token (للتجربة الشخصية)
  String? token = await messaging.getToken();
  print("FCM Token: $token");

  // الإشعارات والتطبيق محلول (Foreground)
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      print("Foreground message: ${message.notification?.title}");
      // هنا تنجم تزيد Snack-bar باش توري الإشعار وسط الـ App
    }
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
      // 5. 🔥 تعديل الـ Theme باش يقبل الـ Light/Dark Mode تلقائياً
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.blue,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      themeMode: ThemeMode.system, // يتبع سيستم التليفون
      home: firstScreen,
    );
  }
}
