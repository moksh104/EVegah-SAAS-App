class KycService {
  // --- SINGLETON SETUP ---
  static final KycService _instance = KycService._internal();
  factory KycService() {
    return _instance;
  }
  KycService._internal();

  // --- KYC DATA ---
  // Statuses: "Pending", "Uploaded", "Verified"
  String aadhaarStatus = "Pending";
  String drivingLicenseStatus = "Pending";
  String selfieStatus = "Pending"; // 🚨 NEW: Added Selfie tracking

  // --- METHODS ---
  Future<bool> uploadDocument(String documentType) async {
    try {
      // Simulate the time it takes to upload a photo
      await Future.delayed(const Duration(seconds: 2));
      
      if (documentType == 'Aadhaar') {
        aadhaarStatus = "Uploaded";
      } else if (documentType == 'DL') {
        drivingLicenseStatus = "Uploaded";
      } else if (documentType == 'Selfie') {
        selfieStatus = "Uploaded"; // 🚨 NEW: Handle Selfie upload
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // 🚨 NEW: Requires all 3 to be uploaded now!
  bool get isKycComplete => 
      aadhaarStatus == "Uploaded" && 
      drivingLicenseStatus == "Uploaded" && 
      selfieStatus == "Uploaded"; 
}