import 'package:flutter/material.dart';
import 'otp_screen.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/constants/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController phoneController = TextEditingController();
  final AuthService authService = AuthService();
  bool isLoading = false;
  bool isPhoneValid = false;

  late AnimationController _floatController;
  late Animation<Offset> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _floatAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 0.05),
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    phoneController.addListener(_validatePhone);
  }

  void _validatePhone() {
    final text = phoneController.text.trim();
    final valid = text.length == 10 && RegExp(r'^[0-9]+$').hasMatch(text);
    if (valid != isPhoneValid) {
      setState(() {
        isPhoneValid = valid;
      });
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Future<void> sendOtp() async {
    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter mobile number"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      bool isExistingUser = await authService.checkMobileNumber(phoneController.text.trim());
      bool otpSent = await authService.sendOtp(phoneController.text.trim());
      
      if (otpSent && mounted) {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => OtpScreen(
              authService: authService,
              phoneNumber: phoneController.text.trim(),
              isExistingUser: isExistingUser,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFE),
      body: SafeArea(
        child: Column(
          children: [
            // Header: Logo & Branding
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(AppConstants.logoImg, height: 36, fit: BoxFit.contain),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 12, color: Colors.black54),
                        SizedBox(width: 4),
                        Text(
                          "Secure Login",
                          style: TextStyle(fontSize: 9, color: Colors.black54, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Contents (Scrollable to prevent overflow)
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    if (!keyboardOpen) ...[
                      const SizedBox(height: 10),
                      const Text(
                        "Welcome Rider!",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F0933),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Sign in to continue your ride",
                        style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 12),

                      // Animated floating Scooter Graphic
                      SlideTransition(
                        position: _floatAnimation,
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxHeight: 180),
                            child: Image.asset(
                              "assets/scooter_bg.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Input Form Box Card
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 24,
                            offset: Offset(0, -8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Phone Number",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F0933),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Custom Text Field with prefix flag dropdown
                          TextField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            decoration: InputDecoration(
                              counterText: "",
                              hintText: "Enter phone number",
                              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontWeight: FontWeight.normal),
                              filled: true,
                              fillColor: const Color(0xFFFAFBFE),
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
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 2),
                                        Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 16),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 22,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(width: 10),
                                ],
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.grey.shade200),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFF4313B8), width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Main CTA "Get OTP" Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: (isLoading || !isPhoneValid) ? null : sendOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4313B8),
                                disabledBackgroundColor: const Color(0xFF4313B8).withValues(alpha: 0.4),
                                elevation: 0,
                                shadowColor: const Color(0xFF4313B8).withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                      "Get OTP",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isPhoneValid ? Colors.white : Colors.white70,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Alternates Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey.shade200)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Text(
                                  "or continue with",
                                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey.shade200)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Social Buttons Row
                          Row(
                            children: [
                              Expanded(
                                child: _buildSocialBtn(
                                  Image.asset('assets/google_logo.png', height: 18),
                                  "Google",
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildSocialBtn(
                                  const Icon(Icons.apple, size: 20, color: Colors.black),
                                  "Apple",
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildSocialBtn(
                                  const Icon(Icons.textsms_outlined, size: 20, color: Color(0xFF25D366)),
                                  "Phone OTP",
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // The "Sign Up" button was removed to strictly enforce OTP flow
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialBtn(Widget icon, String text) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFFFAFBFE),
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(14),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
