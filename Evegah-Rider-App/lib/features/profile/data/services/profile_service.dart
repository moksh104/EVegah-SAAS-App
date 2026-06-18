class ProfileService {
  // --- SINGLETON SETUP ---
  // Ensures the app only ever has one instance of the user's data running
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() {
    return _instance;
  }
  ProfileService._internal();

  // --- USER DATA (The "Database") ---
  String userName = "Raunak Kumar";
  String phoneNumber = "+91 98765 43210";
  String kycStatus = "Pending"; // Can be: Pending, Under Review, Approved
  
  // --- METHODS (The "Actions") ---
  
  // Simulates fetching data from a server when the app starts
  Future<void> fetchUserData() async {
    // 1. Fake a 1-second network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // 2. Here is where you will eventually put your real API call!
    // e.g., var response = await api.get('/user/profile');
    // userName = response.data['name'];
  }

  // Simulates updating the user's name
  Future<bool> updateUserName(String newName) async {
    try {
      // Fake network delay
      await Future.delayed(const Duration(seconds: 1));
      
      // Update local memory
      userName = newName;
      
      // Return true to tell the UI the save was successful
      return true;
    } catch (e) {
      return false;
    }
  }

  // Simulates submitting KYC
  Future<void> submitKycDocuments() async {
    await Future.delayed(const Duration(seconds: 2));
    kycStatus = "Under Review";
  }
}