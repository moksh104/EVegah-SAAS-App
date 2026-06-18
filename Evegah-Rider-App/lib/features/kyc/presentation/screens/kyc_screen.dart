import 'package:flutter/material.dart';
import '../../data/services/kyc_service.dart';
import '../../../../features/profile/data/services/profile_service.dart';

class KycScreen extends StatefulWidget {
  const KycScreen({super.key});

  @override
  State<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends State<KycScreen> {
  final KycService _kycService = KycService();
  final ProfileService _profileService = ProfileService();

  bool _isUploadingAadhaar = false;
  bool _isUploadingDL = false;
  bool _isUploadingSelfie = false; // 🚨 NEW

  Future<void> _handleUpload(String docType) async {
    // 1. Start loading spinner
    if (docType == 'Aadhaar') setState(() => _isUploadingAadhaar = true);
    if (docType == 'DL') setState(() => _isUploadingDL = true);
    if (docType == 'Selfie') setState(() => _isUploadingSelfie = true);

    // 2. Upload
    bool success = await _kycService.uploadDocument(docType);

    // 3. Stop loading spinner
    if (docType == 'Aadhaar') setState(() => _isUploadingAadhaar = false);
    if (docType == 'DL') setState(() => _isUploadingDL = false);
    if (docType == 'Selfie') setState(() => _isUploadingSelfie = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$docType Uploaded Successfully! 📸"), backgroundColor: Colors.green),
      );
      
      // If ALL THREE are uploaded, update the global Profile status!
      if (_kycService.isKycComplete) {
        _profileService.kycStatus = "Under Review";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Verification (KYC)", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.black)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              "Complete your KYC to unlock vehicles and start riding.",
              style: TextStyle(color: Colors.grey, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 32),

            // --- 1. AADHAAR CARD ---
            _buildDocumentCard(
              title: "Aadhaar Card",
              subtitle: "For identity verification",
              icon: Icons.badge_outlined,
              status: _kycService.aadhaarStatus,
              isUploading: _isUploadingAadhaar,
              onTap: () => _handleUpload('Aadhaar'),
            ),
            const SizedBox(height: 20),

            // --- 2. DRIVING LICENSE ---
            _buildDocumentCard(
              title: "Driving License",
              subtitle: "Required for EVegah Pro",
              icon: Icons.directions_car_filled_outlined,
              status: _kycService.drivingLicenseStatus,
              isUploading: _isUploadingDL,
              onTap: () => _handleUpload('DL'),
            ),
            const SizedBox(height: 20),

            // --- 3. LIVE SELFIE (🚨 NEW) ---
            _buildDocumentCard(
              title: "Live Selfie",
              subtitle: "To match with your ID documents",
              icon: Icons.face_rounded,
              status: _kycService.selfieStatus,
              isUploading: _isUploadingSelfie,
              onTap: () => _handleUpload('Selfie'),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER: Document Card ---
  Widget _buildDocumentCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String status,
    required bool isUploading,
    required VoidCallback onTap,
  }) {
    bool isDone = status == "Uploaded" || status == "Verified";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDone ? Colors.green.shade300 : Colors.grey.shade200, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDone ? Colors.green.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: isDone ? Colors.green : const Color(0xFF1E1452), size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isDone
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle, color: Colors.green),
                    label: const Text("Document Uploaded", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.green),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  )
                : ElevatedButton(
                    onPressed: isUploading ? null : onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E1452),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isUploading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("Upload Document", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
          )
        ],
      ),
    );
  }
}