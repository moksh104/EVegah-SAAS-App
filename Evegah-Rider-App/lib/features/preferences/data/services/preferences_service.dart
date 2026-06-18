class PreferencesService {
  // --- SINGLETON SETUP ---
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() {
    return _instance;
  }
  PreferencesService._internal();

  // --- PREFERENCES DATA ---
  bool pushNotifications = true;
  bool emailPromos = false;
  
  String selectedLanguage = "English";
  
  // 🚨 REMOVED THE OTHER LANGUAGES
  final List<String> availableLanguages = [
    "English",
  ];

  // --- METHODS ---
  Future<bool> toggleSetting(String settingType, bool value) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    if (settingType == 'push') pushNotifications = value;
    if (settingType == 'email') emailPromos = value;
    
    return true;
  }

  Future<bool> changeLanguage(String newLanguage) async {
    await Future.delayed(const Duration(milliseconds: 500));
    selectedLanguage = newLanguage;
    return true;
  }
}