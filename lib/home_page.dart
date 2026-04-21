import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart'; // إضافية للـ Logout
import 'login_page.dart';

class HomePage extends StatefulWidget {
  final Map userData;
  const HomePage({super.key, required this.userData});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isDarkMode = true;
  late String name, tel, sex, startDate, endDate;
  late String deviceToken;

  List<Map<String, dynamic>> messages = [];
  List<Map<String, dynamic>> globalChat = [];
  bool showMessages = false;
  bool showGlobalChat = false;
  TextEditingController chatController = TextEditingController();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    // إسناد البيانات مع حماية من الـ null
    name = widget.userData['name'] ?? "User";
    tel = widget.userData['tel'] ?? "";
    sex = widget.userData['sex'] ?? "";
    startDate = widget.userData['start_date'] ?? "";
    endDate = widget.userData['end_date'] ?? "";

    initNotifications();
    getDeviceToken();

    // تشغيل التنبيه التلقائي بعد رسم الواجهة
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkSubscriptionStatus();
    });

    loadGlobalChat();

    // 🔥 تحديث chat كل 5 ثواني
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && showGlobalChat) loadGlobalChat();
    });
  }

  // ================== Firebase Device Token ==================
  void getDeviceToken() async {
    deviceToken = await FirebaseMessaging.instance.getToken() ?? '';
    print("DEVICE TOKEN: $deviceToken");
  }

  // ================== Notifications ==================
  void initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void showNotification(String message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'global_chat_channel',
      'Global Chat',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'رسالة جديدة',
      message,
      platformDetails,
    );
  }

  // ================== Membership Check (Logic Improved) ==================
  void checkSubscriptionStatus() {
    try {
      DateTime today = DateTime.now();
      DateTime end = DateTime.parse(endDate);

      // التنبيه يظهر إذا كان اليوم هو يوم النهاية أو فات
      if (today.isAfter(end) ||
          (today.year == end.year &&
              today.month == end.month &&
              today.day == end.day)) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
            title: Text("تنبيه الخلاص ⚠️",
                style:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                textAlign: TextAlign.right),
            content: Text(
              "يا كابتن $name، اشتراكك وفى اليوم أو فات وقتو. الرجاء تجديد الاشتراك لمواصلة التمارين!",
              style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87),
              textAlign: TextAlign.right,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("واضح"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print("Date parsing error: $e");
    }
  }

  bool isActive() {
    try {
      DateTime now = DateTime.now();
      DateTime end = DateTime.parse(endDate);
      return now.isBefore(end);
    } catch (e) {
      return false;
    }
  }

  void loadMessages() {
    if (messages.isNotEmpty) return;
    DateTime now = DateTime.now();
    DateTime lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    if (now.day == lastDayOfMonth.day) {
      setState(() {
        messages = [
          {"text": "لقد انتهت عضويتك ,الرجاء تجديدها", "date": DateTime.now()},
        ];
        showMessages = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("رسائل الشهر ستظهر آخر أيام الشهر فقط")),
      );
    }
  }

  // ================== Global Chat ==================
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

    try {
      await http.post(
        Uri.parse("http://bargougym.atwebpages.com/global_chat.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "action": "add",
          "user": name,
          "message": chatController.text,
        }),
      );

      showNotification(chatController.text);
      chatController.clear();
      loadGlobalChat();
    } catch (e) {
      print("Error sending chat: $e");
    }
  }

  // ================== Logout Logic ==================
  Future<void> handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data'); // فسخ البيانات من الهاتف

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ================== UI ==================
  @override
  Widget build(BuildContext context) {
    bool active = isActive();

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.black : Colors.blue,
        title: const Text("Home"),
        actions: [
          if (messages.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () => setState(() => showMessages = !showMessages),
            ),
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => setState(() => isDarkMode = !isDarkMode),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: handleLogout, // استدعاء دالة الخروج الصحيحة
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.deepPurple[700] : Colors.blue[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "مرحبًا $name 👋",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          active ? "عضوية فعّالة" : "العضوية منتهية",
                          style: TextStyle(
                            color: active ? Colors.green[200] : Colors.red[200],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: loadMessages,
                      child: const Text("رسائل الشهر"),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  infoCard("Name", name),
                  infoCard("Tel", tel),
                  infoCard("Sex", sex),
                  infoCard("Start", startDate),
                  infoCard("End", endDate),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => showGlobalChat = !showGlobalChat);
                      if (showGlobalChat) loadGlobalChat();
                    },
                    child: Text(
                      showGlobalChat
                          ? "إخفاء Global Chat"
                          : "إظهار Global Chat",
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (showGlobalChat)
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[900] : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Global Chat",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    setState(() => showGlobalChat = false),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView(
                              children: globalChat
                                  .map(
                                    (msg) =>
                                        Text("${msg['user']}: ${msg['text']}"),
                                  )
                                  .toList(),
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: chatController,
                                  style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                                  decoration: const InputDecoration(
                                    hintText: "اكتب رسالة...",
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.send),
                                onPressed: sendGlobalMessage,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              if (showMessages)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "رسائل الشهر الحالي",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...messages.map(
                        (msg) => Text(
                          "${msg['text']} - ${msg['date'].hour}:${msg['date'].minute}",
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget infoCard(String title, String value) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
