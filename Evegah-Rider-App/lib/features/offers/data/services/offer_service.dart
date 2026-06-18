class OfferService {
  // --- SINGLETON SETUP ---
  static final OfferService _instance = OfferService._internal();
  factory OfferService() {
    return _instance;
  }
  OfferService._internal();

  // --- OFFERS DATA ---
  final String userReferralCode = "EV-RAUNAK-50";
  double availableCredits = 150.0;

  final List<Map<String, String>> activeOffers = [
    {
      "code": "GREENWEEK",
      "title": "50% off next 3 rides",
      "subtitle": "Max discount ₹50 per ride",
      "expiry": "Valid till 30 Nov",
    },
    {
      "code": "FESTIVE25",
      "title": "Flat ₹25 off on Pro rides",
      "subtitle": "Applicable only on EVegah Pro",
      "expiry": "Valid till 15 Dec",
    },
  ];

  // --- METHODS ---
  Future<bool> applyPromoCode(String code) async {
    // Fake network delay to verify code
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real app, this would check against your backend database!
    return code.trim().toUpperCase() == "GREENWEEK" || code.trim().toUpperCase() == "FESTIVE25";
  }
}