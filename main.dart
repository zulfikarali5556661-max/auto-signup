import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_accessibility_service/flutter_accessibility_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Random _random = Random();

  // নাম এবং সারনেম লিস্ট
  final List<String> firstNames = ["Rohim", "Korim", "Riyad", "Junaed", "Momin", "Eva", "Nova", "Rahim", "Karim", "Ayesha", "Fatema", "Sumon", "Rasel", "Tania", "Sonia", "Faruk", "Salma", "Jamil", "Nasir", "Rasel"];
  final List<String> surnames = ["Ali", "Khan", "Ahmed", "Hossain", "Rahman", "Islam", "Begum", "Akter", "Chowdhury", "Sarkar", "Mia", "Uddin", "Sikder", "Parvin"];

  // কনফিগারেবল ভ্যারিয়েবলস
  final TextEditingController _numbersController = TextEditingController();
  List<String> mobileNumbers = [];
  int totalNumbers = 0;
  int remainingNumbers = 0;
  int successfulAccounts = 0;
  int failedAttempts = 0;
  int selectedBrowsers = 1;
  int repeatPerNumber = 2;
  bool isRunning = false;

  // আপনার সঠিক ওয়েবসাইট লিঙ্ক এখানে
  final String websiteUrl = "https://m.facebook.com/reg/"; 

  // ব্রাউজার প্যাকেজ নাম (Via Browser)
  final List<String> viaPackages = ["mark.via.gp"];

  String getRandomName(List<String> list) => list[_random.nextInt(list.length)];

  // পাসওয়ার্ড জেনারেশন লজিক (সংশোধিত)
  String generateRandomPassword() {
    const letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    const special = '!@#\$%^&*()';
    String password = '';
    password += letters[_random.nextInt(letters.length)];
    password += numbers[_random.nextInt(numbers.length)];
    password += special[_random.nextInt(special.length)];
    
    int len = 8 + _random.nextInt(4);
    String all = letters + numbers + special;
    for (int i = 0; i < len; i++) {
      password += all[_random.nextInt(all.length)];
    }
    return (password.split('')..shuffle()).join('');
  }

  void uploadNumbers() {
    List<String> lines = _numbersController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    setState(() {
      mobileNumbers = lines;
      totalNumbers = lines.length;
      remainingNumbers = lines.length;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Numbers Uploaded Successfully!")));
  }

  Future<void> startAutoSignup() async {
    if (mobileNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("আগে মোবাইল নম্বর আপলোড করুন")));
      return;
    }

    bool granted = await FlutterAccessibilityService.isAccessibilityPermissionEnabled();
    if (!granted) {
      await FlutterAccessibilityService.requestAccessibilityPermission();
      return;
    }

    setState(() {
      isRunning = true;
      successfulAccounts = 0;
      failedAttempts = 0;
    });

    _runInstance(viaPackages[0], mobileNumbers);
  }

  Future<void> _runInstance(String packageName, List<String> numbers) async {
    for (String number in numbers) {
      if (!isRunning) break;
      for (int r = 0; r < repeatPerNumber; r++) {
        try {
          await FlutterAccessibilityService.launchApp(packageName, url: websiteUrl);
          
          StreamSubscription? subscription;
          subscription = FlutterAccessibilityService.accessibilityStream.listen((event) async {
            if (event.packageName == packageName) {
              final String? textLower = event.text?.toLowerCase();

              // অটোমেশন ধাপসমূহ
              if (textLower?.contains("create new account") == true) {
                await FlutterAccessibilityService.performActionOnText("Create new account", NodeAction.actionClick);
              }

              if (textLower?.contains("first name") == true) {
                await FlutterAccessibilityService.performActionOnText("First name", NodeAction.actionSetText, arguments: {"text": getRandomName(firstNames)});
                await Future.delayed(const Duration(milliseconds: 600));
                await FlutterAccessibilityService.performActionOnText("Surname", NodeAction.actionSetText, arguments: {"text": getRandomName(surnames)});
                await Future.delayed(const Duration(milliseconds: 600));
                await FlutterAccessibilityService.performActionOnText("Next", NodeAction.actionClick);
              }

              if (textLower?.contains("mobile number") == true) {
                await FlutterAccessibilityService.performActionOnText("Mobile number", NodeAction.actionSetText, arguments: {"text": number});
                await Future.delayed(const Duration(milliseconds: 600));
                await FlutterAccessibilityService.performActionOnText("Next", NodeAction.actionClick);
              }

              if (textLower?.contains("password") == true) {
                await FlutterAccessibilityService.performActionOnText("Password", NodeAction.actionSetText, arguments: {"text": generateRandomPassword()});
                await Future.delayed(const Duration(milliseconds: 600));
                await FlutterAccessibilityService.performActionOnText("Next", NodeAction.actionClick);
              }

              if (textLower?.contains("confirm your mobile number") == true) {
                setState(() {
                  successfulAccounts++;
                  remainingNumbers--;
                });
                subscription?.cancel();
              }
            }
          });

          await Future.delayed(const Duration(seconds: 35));
          subscription.cancel();

        } catch (e) {
          setState(() => failedAttempts++);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text("Auto Signup Tool"), backgroundColor: Colors.blueAccent),
        body: isRunning ? _buildRunningScreen() : _buildSetupScreen(),
      ),
    );
  }

  Widget _buildSetupScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _numbersController,
            maxLines: 8,
            decoration: const InputDecoration(hintText: "নম্বরগুলো এখানে দিন (প্রতি লাইনে একটি)", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(onPressed: uploadNumbers, icon: const Icon(Icons.upload_file), label: const Text("Upload Numbers")),
          const Divider(height: 40),
          Text("Total Numbers: $totalNumbers", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: startAutoSignup,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("START PROCESS", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRunningScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 25),
          Text("Successful: $successfulAccounts", style: const TextStyle(fontSize: 22, color: Colors.green)),
          Text("Failed: $failedAttempts", style: const TextStyle(fontSize: 22, color: Colors.red)),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () => setState(() => isRunning = false),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("STOP AUTOMATION", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

