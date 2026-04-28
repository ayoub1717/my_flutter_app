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
  // الاعتماد على ثيم النظام بدل المتغير اليدوي لجعل التطبيق "Pro"
  late String name, tel, sex, startDate, endDate;
  List<Map<String, dynamic>> globalChat = [];
  bool showGlobalChat = false;
  bool showMessages = false;
  List<Map<String, dynamic>> messages = [];
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

    // تشغيل الـ Chat فوراً عند الدخول
    loadGlobalChat();

    // تحديث المحادثة كل 5 ثواني
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) loadGlobalChat();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkSubscriptionStatus();
    });
  }

  // ================== إعدادات التنبيهات المحلية ==================
  void initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // ================== جلب المحادثة من السيرفر ==================
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

  // ================== إرسال رسالة ==================
  Future<void> sendGlobalMessage() async {
    if (chatController.text.isEmpty) return;
    String msg = chatController.text;
    chatController.clear(); // مسح النص فوراً لتجربة مستخدم أسرع

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

  void checkSubscriptionStatus() {
    // منطق التنبيه (كما هو في كودك)
  }

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
    // معرفة هل التطبيق في وضع الـ Dark أو Light
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bargou Gym"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: handleLogout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Colors.deepPurple[700] : Colors.blue[600],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("مرحباً $name 👋",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text("تاريخ نهاية الاشتراك: $endDate",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // المعلومات الشخصية
            infoCard("الإسم", name, context),
            infoCard("الهاتف", tel, context),
            infoCard("نهاية الاشتراك", endDate, context),

            const SizedBox(height: 20),

            // قسم الـ Global Chat المتطور
            Container(
              height: 400,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border:
                    Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text("الدردشة الجماعية 💬",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black)),
                  ),
                  Expanded(
                    child: ListView.builder(
                      reverse: false,
                      itemCount: globalChat.length,
                      itemBuilder: (context, index) {
                        var msg = globalChat[index];
                        bool isMe = msg['user'] == name;
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.blue[700]
                                  : (isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[300]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe)
                                  Text(msg['user'],
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange)),
                                Text(msg['text'],
                                    style: TextStyle(
                                        color: (isMe || isDark)
                                            ? Colors.white
                                            : Colors.black)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: chatController,
                            decoration: InputDecoration(
                              hintText: "اكتب رسالة...",
                              filled: true,
                              fillColor: isDark ? Colors.black26 : Colors.white,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        IconButton(
                            icon: const Icon(Icons.send, color: Colors.blue),
                            onPressed: sendGlobalMessage),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget infoCard(String title, String value, BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
        ],
      ),
    );
  }
}
