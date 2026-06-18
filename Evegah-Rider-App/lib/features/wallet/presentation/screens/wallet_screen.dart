import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../data/services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  final TextEditingController _amountController = TextEditingController();

  late Razorpay _razorpay;
  bool isProcessingPayment = false;
  
  // 🚨 UI State Variables for Real Data
  bool isLoadingData = true;
  double _walletBalance = 0.0;
  List<Map<String, dynamic>> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    
    // Fetch real data on screen load!
    _loadWalletData();
  }

  // 🚨 THE NEW FETCH FUNCTION
  Future<void> _loadWalletData() async {
    setState(() => isLoadingData = true);
    
    double balance = await _walletService.fetchWalletBalance();
    List<Map<String, dynamic>> txs = await _walletService.fetchRecentTransactions();
    
    if (mounted) {
      setState(() {
        _walletBalance = balance;
        _recentTransactions = txs;
        isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    setState(() => isProcessingPayment = false);
    print("✅ SUCCESS: Payment ID: ${response.paymentId}");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Payment Successful! Wallet Recharged."), backgroundColor: Colors.green),
    );
    // 🚨 REFRESH THE DATA AUTOMATICALLY AFTER PAYMENT!
    _loadWalletData(); 
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => isProcessingPayment = false);
    print("❌ ERROR: ${response.code} - ${response.message}");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}"), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => isProcessingPayment = false);
    print("📱 EXTERNAL WALLET SELECTED: ${response.walletName}");
  }

  Future<void> _startPayment(double amount) async {
    setState(() => isProcessingPayment = true);

    Map<String, String>? orderData = await _walletService.createOrder(amount.toInt());

    if (orderData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to secure payment connection."), backgroundColor: Colors.red),
        );
      }
      setState(() => isProcessingPayment = false);
      return;
    }

    var options = {
      'key': orderData["keyId"], 
      'amount': (amount * 100).toInt(), 
      'name': 'EVegah Mobility',
      'description': 'Wallet Recharge',
      'order_id': orderData["orderId"], 
      'timeout': 120, 
      'prefill': {
        'contact': '9876543210', // You can swap this with the real user phone later!
        'email': 'user@evegah.com'
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      print("Razorpay Error: $e");
      setState(() => isProcessingPayment = false);
    }
  }

  void _showAddMoneySheet() {
    final List<int> quickAmounts = [50, 100, 200, 400, 500, 1000];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Add Money to Wallet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: "₹ ",
                      hintText: "Enter amount",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onChanged: (value) => setModalState(() {}),
                  ),
                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: quickAmounts.map((amount) {
                      return GestureDetector(
                        onTap: () => setModalState(() => _amountController.text = amount.toString()),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Text(
                            "₹$amount",
                            style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isProcessingPayment ? null : () async {
                        double amount = double.tryParse(_amountController.text) ?? 0;
                        if (amount > 0) {
                          Navigator.pop(context); 
                          await _startPayment(amount); 
                          _amountController.clear();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isProcessingPayment 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Proceed to Pay", style: TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            );
          }
        );
      },
    );
  }

  // 🚨 THE TRANSACTION HISTORY POP-UP
  void _showTransactionHistorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(height: 5, width: 50, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("All Transactions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              Expanded(
                child: _recentTransactions.isEmpty
                    ? const Center(child: Text("No transactions yet.", style: TextStyle(color: Colors.grey)))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: _recentTransactions.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final tx = _recentTransactions[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                              child: Icon(tx['isCredit'] ? Icons.account_balance_wallet : Icons.electric_scooter, color: tx['isCredit'] ? Colors.green : Colors.blue),
                            ),
                            title: Text(tx['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(tx['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            trailing: Text(
                              "₹ ${tx['amount']}", 
                              style: TextStyle(color: tx['isCredit'] ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🚨 THE GREEN REWARDS POP-UP
  void _showGreenRewardsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                child: const Icon(Icons.eco, color: Colors.green, size: 48),
              ),
              const SizedBox(height: 20),
              const Text("Eco Champion!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                "You have saved 18kg of CO₂ this month by riding an EV instead of a petrol vehicle.\n\nThat is equivalent to planting 1 tree! Keep riding to increase your impact.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Awesome!", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text("Wallet & Payments", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: Colors.black)),
        centerTitle: false,
      ),
      // Show full screen loader if initializing for the first time
      body: isLoadingData 
        ? const Center(child: CircularProgressIndicator(color: Colors.purple))
        : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4CAF50), Color(0xFF9C27B0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.purple.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Available Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 8),
                Text(
                  // 🚨 LIVE REAL BALANCE
                  "₹ ${_walletBalance.toStringAsFixed(2)}",
                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _showAddMoneySheet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Add Money", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 24),

          _buildActionTile(
            title: "Transaction History",
            subtitle: "View all wallet payments & recharges",
            icon: Icons.history,
            iconColor: Colors.purple,
            iconBg: Colors.purple.shade50,
            onTap: _showTransactionHistorySheet, // 🚨 CONNECTED!
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            title: "Green Rewards",
            subtitle: "You saved 18kg CO₂ this month 🌱",
            icon: Icons.eco,
            iconColor: Colors.green,
            iconBg: Colors.green.shade50,
            showArrow: false,
            onTap: _showGreenRewardsDialog, // 🚨 CONNECTED!
          ),
          const SizedBox(height: 32),

          const Text("Recent Transactions", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 16),
          
          // 🚨 LIVE REAL TRANSACTIONS
          if (_recentTransactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 20),
                child: Text("No recent transactions", style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ..._recentTransactions.map((tx) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.green),
                ),
                title: Text(tx['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(tx['date'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                trailing: Text(
                  "₹ ${tx['amount']}", 
                  // Green for deposits (+), Red for rides (-)
                  style: TextStyle(color: tx['isCredit'] ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 16)
                ),
              );
            }),
        ],
      ),
    );
  }

  // 🚨 UPDATED TILE BUILDER WITH ONTAP AND INKWELL
  Widget _buildActionTile({
    required String title, 
    required String subtitle, 
    required IconData icon, 
    required Color iconColor, 
    required Color iconBg, 
    bool showArrow = true,
    VoidCallback? onTap, 
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  ],
                ),
              ),
              if (showArrow) const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}