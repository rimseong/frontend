import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/app_user.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const LunchPickApp());
}

class LunchPickApp extends StatelessWidget {
  const LunchPickApp({super.key});

  Future<AppUser?> _getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    if (prefs.getString('login_date') != today) return null;
    final id = prefs.getInt('user_id');
    final name = prefs.getString('user_name');
    final employeeNo = prefs.getString('user_employee_no');
    if (id == null || name == null || employeeNo == null) return null;
    return AppUser(id: id, name: name, employeeNo: employeeNo);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '점심 픽',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35)),
        useMaterial3: true,
      ),
      home: FutureBuilder<AppUser?>(
        future: _getSavedUser(),
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
      ),
    );
  }
}
