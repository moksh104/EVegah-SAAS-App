import 'package:flutter/material.dart';
import '../../data/services/support_service.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final supportService = SupportService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("FAQs", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: Colors.black)),
      ),
      // 🚨 NEW: FutureBuilder to handle the API waiting time!
      body: SafeArea(
        child: FutureBuilder<List<Map<String, String>>>(
          future: supportService.fetchFaqs(), // Calls the API
          builder: (context, snapshot) {
            
            // STATE 1: Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black),
              );
            }
            
            // STATE 2: Error
            if (snapshot.hasError) {
              return Center(
                child: Text("Oops! Couldn't load FAQs.\n${snapshot.error}", textAlign: TextAlign.center),
              );
            }

            // STATE 3: Empty
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text("No FAQs available right now.", style: TextStyle(color: Colors.grey)),
              );
            }

            // STATE 4: Success! Draw the list
            final faqs = snapshot.data!;
            
            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: faqs.length,
              itemBuilder: (context, index) {
                final faq = faqs[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: const Color(0xFF1E1452),
                      collapsedIconColor: Colors.grey,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      title: Text(
                        faq['question']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                          child: Text(
                            faq['answer']!,
                            style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}