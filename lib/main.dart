import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAY9Ten22UsTkVBvNRKLHgWhImplvlkS9I",
        authDomain: "simats-campusnav.firebaseapp.com",
        projectId: "simats-campusnav",
        storageBucket: "simats-campusnav.firebasestorage.app",
        messagingSenderId: "766182101171",
        appId: "1:766182101171:web:26055abf9f96aac02ee0c6",
        measurementId: "G-D7SB2N2CBS"
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

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