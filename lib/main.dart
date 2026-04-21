import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'login_page.dart';
import 'firebase_options.dart';

// 🔔 (اختياري) messaging
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 🔥 نشغّل messaging كان في Android / iOS
  if (!kIsWeb) {
    await initMessaging();
  }

  runApp(const MyApp());
}

// 🔔 Firebase Messaging setup (mobile فقط)
Future<void> initMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // طلب permission
  NotificationSettings settings = await messaging.requestPermission();

  print('Permission: ${settings.authorizationStatus}');

  // token
  String? token = await messaging.getToken();
  print("FCM Token: $token");

  // استقبال notification
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("New message: ${message.notification?.title}");
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bargou Gym',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const LoginPage(),
    );
  }
}
