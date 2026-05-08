import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  final Map userData;
  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String name, tel, sex, startDate, endDate;

  List<Map<String, dynamic>> globalChat = [];
  TextEditingController chatController = TextEditingController();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();

    name = widget.userData['name'] ?? "User";
    tel = widget.userData['tel'] ?? "";
    sex = widget.userData['sex'] ?? "";
    startDate = widget.userData['start_date'] ?? "";
    endDate = widget.userData['end_date'] ?? "";

    initNotifications();

    loadGlobalChat();

    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) loadGlobalChat();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkSubscriptionStatus();
    });
  }

  // 🔥 FIXED NOTIFICATIONS
  void initNotifications() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
        InitializationSettings(android: androidInit);

    await flutterLocalNotificationsPlugin.initialize(settings);

    // 🔥 IMPORTANT: نفس topic متاع PHP
    FirebaseMessaging.instance.subscribeToTopic("gym_chat");

    // 🔥 LISTENER (باش notification يطلع في app)
    FirebaseMessaging.onMessage.listen((message) {
      flutterLocalNotificationsPlugin.show(
        0,
        message.notification?.title ?? "Notification",
        message.notification?.body ?? "",
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'gym_channel',
            'Gym Notifications',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
      );
    });
  }

  Future<void> loadGlobalChat() async {
    try {
      final response = await http.get(
        Uri.parse("http://bargougym.atwebpages.com/global_chat.php"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["data"] != null) {
          setState(() {
            globalChat = List<Map<String, dynamic>>.from(data["data"]);
          });
        }
      }
    } catch (e) {
      print("Error loading chat: $e");
    }
  }

  Future<void> sendGlobalMessage() async {
    if (chatController.text.isEmpty) return;

    String msg = chatController.text;
    chatController.clear();

    try {
      await http.post(
        Uri.parse("http://bargougym.atwebpages.com/global_chat.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "add",
          "user": name,
          "message": msg,
        }),
      );

      loadGlobalChat();
    } catch (e) {
      print("Error sending chat: $e");
    }
  }

  void checkSubscriptionStatus() {}

  Future<void> handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bargou Gym"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: handleLogout,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.deepPurple : Colors.blue,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                "مرحباً $name 👋",
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 400,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(10),
                    child: Text("Global Chat 💬"),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: globalChat.length,
                      itemBuilder: (context, index) {
                        final msg = globalChat[index];
                        bool isMe = msg['user'] == name;

                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.all(5),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.blue : Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(msg['text'] ?? ""),
                          ),
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: chatController,
                          decoration: const InputDecoration(
                            hintText: "Message...",
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: sendGlobalMessage,
                      )
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
