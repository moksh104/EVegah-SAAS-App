import 'dart:async';

import 'package:flutter/material.dart';

import 'success_screen.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/session_service.dart';

class OtpScreen extends StatefulWidget {
  final AuthService authService;

  const OtpScreen({super.key, required this.authService});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();

  final SessionService sessionService = SessionService();

  int seconds = 30;

  Timer? timer;

  String errorMessage = "";

  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    startTimer();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds > 0) {
        setState(() {
          seconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> verifyOtp() async {
    setState(() {
      isLoading = true;
    });

    bool verified = widget.authService.verifyOtp(otpController.text);

    if (verified) {
      setState(() {
        errorMessage = "";
      });
      print("🚨 THE ID CARD I AM HANDING THE WALLET IS: '${widget.authService.accessToken}'");
      // SAVE ACCESS TOKEN
      await sessionService.saveToken(widget.authService.accessToken);

      Navigator.pushReplacement(
        context,

        MaterialPageRoute(builder: (context) => const SuccessScreen()),
      );
    } else {
      setState(() {
        errorMessage = "Invalid OTP";
      });
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    timer?.cancel();

    otpController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
      // 🚨 1. This tells the Scaffold to resize when the keyboard opens
      resizeToAvoidBottomInset: true, 

      body: Center(
        child: SizedBox(
          width: 400,
          child: Column(
            children: [
              // 🚨 2. EXPANDED + SCROLLVIEW: This area will shrink and scroll when the keyboard pops up!
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Text(
                        "OTP Verification",
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Enter OTP sent to your phone",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const SizedBox(height: 40),

                      // OTP FIELD
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: "Enter OTP",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ERROR MESSAGE
                      Text(errorMessage, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 20),

                      // RESEND TIMER
                      Center(
                        child: seconds == 0
                            ? TextButton(
                                onPressed: () async {
                                  setState(() {
                                    seconds = 30;
                                  });
                                  await widget.authService.sendOtp("");
                                  startTimer();
                                },
                                child: const Text("Resend OTP"),
                              )
                            : Text(
                                "Resend OTP in 00:$seconds",
                                style: const TextStyle(color: Colors.grey),
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // 🚨 3. PINNED BUTTON: This stays outside the scroll view so the keyboard smoothly pushes it up!
              Padding(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : verifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Verify OTP",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
