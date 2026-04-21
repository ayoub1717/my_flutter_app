import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final nameController = TextEditingController();
  final telController = TextEditingController();
  bool isLoading = false;

  Future<void> login() async {
    if (nameController.text.isEmpty || telController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("عبي جميع الخانات")));
      return;
    }

    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      var url = Uri.parse("http://bargougym.atwebpages.com/login.php");

      // ارسال البيانات كـ JSON
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": nameController.text.trim(),
          "tel": telController.text.trim(),
        }),
      );

      // تحقق من حالة الرد
      if (response.statusCode != 200) {
        throw Exception("السيرفر رجع ${response.statusCode}");
      }

      // فك JSON
      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        throw Exception("السيرفر ما رجعش JSON صالح");
      }

      if (data["status"] == "success") {
        if (!mounted) return;

        // 1. جلب الـ SharedPreferences
        final prefs = await SharedPreferences.getInstance();

        // 2. تحويل الـ data["data"] لـ String (JSON) وحفظها
        // استعملنا jsonEncode باش نحفظو الـ Map كاملة (ID, Name, Tel, etc.)
        await prefs.setString('user_data', jsonEncode(data["data"]));

        // 3. التعدية للـ HomePage مع بعث البيانات
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomePage(userData: data["data"]),
          ),
        );
      } else {
        // في حالة فشل الدخول (اسم أو هاتف غلط)
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "فشل تسجيل الدخول")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطأ: $e")));
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Login",
                style: TextStyle(color: Colors.white, fontSize: 30),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Name",
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: telController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Tel",
                  labelStyle: TextStyle(color: Colors.white),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator(color: Colors.blue)
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: login,
                        child: const Text("Login"),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
