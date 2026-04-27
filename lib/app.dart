import 'package:flutter/material.dart';
import 'package:launch_frontend/presentation/pages/launch_home_page.dart';

class LaunchApp extends StatelessWidget {
  const LaunchApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Launch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const LaunchHomePage(),
    );
  }
}
