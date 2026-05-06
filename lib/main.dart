import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'models/app_user.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const LunchPickApp());
}

class LunchPickApp extends StatelessWidget {
  const LunchPickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '점심 픽',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35)),
        useMaterial3: true,
      ),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  late final Future<AppUser?> _future;

  @override
  void initState() {
    super.initState();
    _future = _getSavedUser();
  }

  Future<AppUser?> _getSavedUser() async {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (html.window.localStorage['login_date'] != today) return null;
    final idStr = html.window.localStorage['user_id'];
    final name = html.window.localStorage['user_name'];
    final employeeNo = html.window.localStorage['user_employee_no'];
    if (idStr == null || name == null || employeeNo == null) return null;
    final id = int.tryParse(idStr);
    if (id == null) return null;
    return AppUser(id: id, name: name, employeeNo: employeeNo);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F5F5),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
            ),
          );
        }
        if (snapshot.data != null) {
          return HomeScreen(currentUser: snapshot.data!);
        }
        return const LoginScreen();
      },
    );
  }
}
