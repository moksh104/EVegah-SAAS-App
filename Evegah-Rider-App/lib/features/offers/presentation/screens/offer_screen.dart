import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 🚨 Required for the Clipboard!
import '../../data/services/offer_service.dart';

class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key});

  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  final OfferService _offerService = OfferService();
  final TextEditingController _promoController = TextEditingController();
  bool _isApplying = false;

  // Uses the native device clipboard!
  void _copyReferralCode() {
    Clipboard.setData(ClipboardData(text: _offerService.userReferralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Referral code copied to clipboard! 📋"), backgroundColor: Colors.green),
    );
  }

  Future<void> _applyPromo() async {
    if (_promoController.text.isEmpty) return;

    setState(() => _isApplying = true);
    bool isValid = await _offerService.applyPromoCode(_promoController.text);
    setState(() => _isApplying = false);

    if (mounted) {
      if (isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Promo Code Applied! 🎉"), backgroundColor: Colors.green),
        );
        _promoController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid or expired promo code"), backgroundColor: Colors.red),
        );
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
        title: const Text("Offers & Referrals", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.black)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // --- 1. HERO REFERRAL CARD ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF57C00), Color(0xFFFF9800)], // Vibrant Orange
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  const Text("Invite Friends, Earn Rides!", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    "Get ₹50 in ride credits for every friend who takes their first ride with EVegah.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  
                  // The Copy-to-Clipboard Box
                  GestureDetector(
                    onTap: _copyReferralCode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _offerService.userReferralCode,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text("Available Credits: ₹${_offerService.availableCredits.toStringAsFixed(0)}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- 2. APPLY PROMO CODE ---
            const Text("Have a Promo Code?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: "Enter code here",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                          
               const SizedBox(width: 12),
               SizedBox(
                 height: 55,
                 width: 120, // 🚨 FIX 1: Give it a strict maximum width
                 child: ElevatedButton(
                   onPressed: _isApplying ? null : _applyPromo,
                   style: ElevatedButton.styleFrom(
                     minimumSize: Size.zero, // 🚨 FIX 2: This overrides your AppTheme's infinite width!
                     padding: EdgeInsets.zero,
                     backgroundColor: Colors.black,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   ),
                   child: _isApplying 
                       ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                       : const Text("Apply", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                 ),
               )
              ],
            ),
            const SizedBox(height: 32),

            // --- 3. ACTIVE OFFERS LIST ---
            const Text("Active Offers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 16),
            ..._offerService.activeOffers.map((offer) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.local_offer_rounded, color: Colors.green, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(offer['code']!, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black)),
                          const SizedBox(height: 4),
                          Text(offer['title']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text(offer['subtitle']!, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                            child: Text(offer['expiry']!, style: TextStyle(color: Colors.grey.shade700, fontSize: 11, fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        _promoController.text = offer['code']!;
                        _applyPromo();
                      },
                      child: const Text("APPLY", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    )
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}