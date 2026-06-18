import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

//import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../dashboard/presentation/screens/main_navigation.dart';

class KycUploadScreen extends StatefulWidget {
  const KycUploadScreen({super.key});

  @override
  State<KycUploadScreen> createState() => _KycUploadScreenState();
}

class _KycUploadScreenState extends State<KycUploadScreen> {
  bool drivingUploaded = true;
  bool aadhaarUploaded = true;
  bool selfieUploaded = true;

  String drivingFile = "";
  String aadhaarFile = "";
  String selfieFile = "";

  Future<void> pickFile(String type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      String fileName = result.files.single.name;

      setState(() {
        if (type == "dl") {
          drivingUploaded = true;
          drivingFile = fileName;
        } else if (type == "aadhaar") {
          aadhaarUploaded = true;
          aadhaarFile = fileName;
        } else {
          selfieUploaded = true;
          selfieFile = fileName;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: 450,

            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // HEADER
                  const Text(
                    "KYC Verification 🪪",

                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Verify your identity to unlock EV rides",

                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),

                  const SizedBox(height: 30),

                  // STEPPER
                  Row(
                    children: [
                      buildStep("Profile", true),

                      buildLine(),

                      buildStep("KYC", true),

                      buildLine(),

                      buildStep("Verify", false),

                      buildLine(),

                      buildStep("Dashboard", false),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // DRIVING LICENSE
                  buildUploadCard(
                    title: "Driving License",

                    subtitle: "Upload front side of your DL",

                    icon: Icons.credit_card,

                    uploaded: drivingUploaded,

                    fileName: drivingFile,

                    onTap: () {
                      pickFile("dl");
                    },
                  ),

                  const SizedBox(height: 20),

                  // AADHAAR
                  buildUploadCard(
                    title: "Aadhaar Card",

                    subtitle: "Upload government identity",

                    icon: Icons.badge_outlined,

                    uploaded: aadhaarUploaded,

                    fileName: aadhaarFile,

                    onTap: () {
                      pickFile("aadhaar");
                    },
                  ),

                  const SizedBox(height: 20),

                  // SELFIE
                  buildUploadCard(
                    title: "Selfie Verification",

                    subtitle: "Take a clear selfie photo",

                    icon: Icons.camera_alt_outlined,

                    uploaded: selfieUploaded,

                    fileName: selfieFile,

                    onTap: () {
                      pickFile("selfie");
                    },
                  ),

                  const SizedBox(height: 35),

                  // SECURITY CARD
                  Container(
                    padding: const EdgeInsets.all(20),

                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade700],
                      ),

                      borderRadius: BorderRadius.circular(24),
                    ),

                    child: const Row(
                      children: [
                        Icon(Icons.lock, color: Colors.white, size: 36),

                        SizedBox(width: 16),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Text(
                                "Your Documents Are Secure 🔒",

                                style: TextStyle(
                                  color: Colors.white,

                                  fontSize: 18,

                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 6),

                              Text(
                                "All uploaded files are encrypted and protected.",

                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,

                    height: 60,

                    child: ElevatedButton(
                      onPressed: () {
                        if (drivingUploaded &&
                            aadhaarUploaded &&
                            selfieUploaded) {
                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (context) => const VerificationScreen(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please upload all documents"),
                            ),
                          );
                        }
                      },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),

                      child: const Text(
                        "Submit Verification",

                        style: TextStyle(
                          fontSize: 18,

                          color: Colors.white,

                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool uploaded,
    required String fileName,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius: BorderRadius.circular(24),

          border: Border.all(
            color: uploaded ? Colors.green : Colors.transparent,

            width: 2,
          ),
        ),

        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: uploaded ? Colors.green.shade100 : Colors.grey.shade100,

                borderRadius: BorderRadius.circular(18),
              ),

              child: Icon(
                uploaded ? Icons.check : icon,

                color: uploaded ? Colors.green : Colors.black,
              ),
            ),

            const SizedBox(width: 18),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,

                    style: const TextStyle(
                      fontSize: 18,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(subtitle, style: const TextStyle(color: Colors.grey)),

                  const SizedBox(height: 6),

                  Text(
                    fileName,

                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            ),

            Text(
              uploaded ? "Uploaded" : "Upload",

              style: TextStyle(
                color: uploaded ? Colors.green : Colors.black,

                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStep(String title, bool active) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 16,

            backgroundColor: active ? Colors.green : Colors.grey.shade300,

            child: Icon(
              active ? Icons.check : Icons.circle,

              size: 14,

              color: Colors.white,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            title,

            style: TextStyle(
              fontSize: 12,

              color: active ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLine() {
    return Expanded(child: Container(height: 2, color: Colors.grey.shade300));
  }
}

// VERIFICATION SCREEN

class VerificationScreen extends StatelessWidget {
  const VerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushAndRemoveUntil(
  context,
  MaterialPageRoute(builder: (context) => const MainNavigation()),
  (route) => false, // 🚨 This tells Flutter to destroy every previous screen!
);
    });

    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              height: 120,
              width: 120,

              decoration: BoxDecoration(
                color: Colors.orange.shade100,

                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.verified_user,

                size: 70,

                color: Colors.orange.shade700,
              ),
            ),

            const SizedBox(height: 40),

            const Text(
              "Verification In Progress ⏳",

              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            const Text(
              "Your documents are being reviewed.\nRedirecting to dashboard...",

              textAlign: TextAlign.center,

              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),

            const SizedBox(height: 40),

            const CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}
