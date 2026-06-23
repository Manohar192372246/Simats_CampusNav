import 'package:flutter/material.dart';
import 'splash_screen.dart';

void main() {
  runApp(const CampusNavApp());
}

class CampusNavApp extends StatelessWidget {
  const CampusNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}