import 'package:flutter/material.dart';
import '../../../dashboard/presentation/screens/main_navigation.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 1. Add a tiny delay so the screen doesn't instantly flash (feels more premium)
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    // 2. Route the user to Main Navigation directly (Auth is checked later when booking)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This is the "Splash Screen" the user sees for half a second while the app checks their login status.
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        // You can replace this with your EVegah App Logo later!
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );
  }
}