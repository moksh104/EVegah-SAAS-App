import 'package:flutter/material.dart';

/// OTP verification screen placeholder.
/// TODO: Implement OTP verification flow.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('OTP Verification'),
      ),
    );
  }
}
