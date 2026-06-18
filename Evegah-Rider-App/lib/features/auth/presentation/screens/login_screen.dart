import 'package:flutter/material.dart';

import 'otp_screen.dart';
import 'create_profile_screen.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/constants/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();

  final AuthService authService = AuthService();

  bool isLoading = false;

  Future<void> sendOtp() async {
    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter mobile number")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    bool exists = await authService.checkMobileNumber(
      phoneController.text.trim(),
    );

    if (exists) {
      bool otpSent = await authService.sendOtp(phoneController.text.trim());

      if (otpSent && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(authService: authService),
          ),
        );
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.6,
            color: Colors.white,
          ),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  /// LOGO
                  Center(child: Image.asset(AppConstants.logoImg, height: 60)),

                  const SizedBox(height: 16),

                  const Text(
                    "Welcome Rider!",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Color(0xff2B0B78),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    "Sign in to continue your journey",
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),

                  const SizedBox(height: 24),

                  /// SCOOTER IMAGE
                  Image.asset(
                    "assets/scooter_bg.png",
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),

                  const SizedBox(height: 20),

                  /// BOTTOM CARD
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Phone Number",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xff2B0B78),
                          ),
                        ),

                        const SizedBox(height: 10),

                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          decoration: InputDecoration(
                            counterText: "",
                            hintText: "Enter phone number",
                            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: Row(
                                    children: [
                                      const Text("🇮🇳", style: TextStyle(fontSize: 20)),
                                      const SizedBox(width: 6),
                                      const Text(
                                        "+91",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 24,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(width: 12),
                              ],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xff2B0B78),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2B0B78),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    "Get OTP",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "or continue with",
                                style: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                              child: socialButton(
                                Image.asset('assets/google_logo.png', height: 18),
                                "Google",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: socialButton(
                                const Icon(Icons.apple, size: 22, color: Colors.black),
                                "Apple",
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: socialButton(
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    const Icon(Icons.smartphone_outlined, size: 22, color: Color(0xff2B0B78)),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(width: 2, height: 2, decoration: const BoxDecoration(color: Color(0xff2B0B78), shape: BoxShape.circle)),
                                          const SizedBox(width: 1.5),
                                          Container(width: 2, height: 2, decoration: const BoxDecoration(color: Color(0xff2B0B78), shape: BoxShape.circle)),
                                          const SizedBox(width: 1.5),
                                          Container(width: 2, height: 2, decoration: const BoxDecoration(color: Color(0xff2B0B78), shape: BoxShape.circle)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                "Phone OTP",
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: TextStyle(color: Colors.grey, fontSize: 15),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CreateProfileScreen()),
                                );
                              },
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: Color(0xff2B0B78),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget socialButton(Widget icon, String text) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }
}
