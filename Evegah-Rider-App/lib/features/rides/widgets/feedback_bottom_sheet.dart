import 'package:flutter/material.dart';
import '../data/services/ride_service.dart'; // 🚨 Imported our Chef!

class FeedbackBottomSheet extends StatefulWidget {
  final String rideId; // Currently passing vehicleId/rideId string
  const FeedbackBottomSheet({super.key, required this.rideId});

  @override
  State<FeedbackBottomSheet> createState() => _FeedbackBottomSheetState();
}

class _FeedbackBottomSheetState extends State<FeedbackBottomSheet> {
  int _rating = 0;
  final List<String> _selectedIssues = [];
  final TextEditingController _commentController = TextEditingController();
  bool isSubmitting = false;

  // The predefined tags for the mechanics
  final List<String> _complaintTags = [
    "Battery Issue",
    "Brakes Loose",
    "App Glitch",
    "Motor/Speed",
    "Dirty Vehicle",
    "Flat Tire"
  ];

  // 🚨 CLEAN ARCHITECTURE: The UI just calls the service!
  Future<void> _submitFeedback() async {
    setState(() => isSubmitting = true);

    bool success = await RideService().submitFeedback(
      vehicleId: widget.rideId,
      rideBookingId: 456, // TODO: Pass this dynamically from the active ride
      rating: _rating,
      issues: _selectedIssues,
      comment: _commentController.text,
    );

    if (!mounted) return;
    setState(() => isSubmitting = false);

    if (success) {
      Navigator.pop(context); // Close the sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback submitted successfully! Thank you."), backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit feedback. Please try again."), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if it's a "Complaint Path" (1, 2, or 3 stars)
    bool isComplaint = _rating > 0 && _rating <= 3;

    return Padding(
      // This ensures the sheet moves up when the keyboard opens!
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar at the top
            Container(
              width: 50, height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 24),
            const Text(
              "How was your ride?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 8),
            Text("Vehicle ID: ${widget.rideId}", style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            // --- THE STARS ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: AnimatedScale(
                      scale: _rating >= index + 1 ? 1.2 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        _rating >= index + 1 ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: _rating >= index + 1 ? Colors.amber : Colors.grey.shade400,
                        size: 40,
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // --- THE SMART COMPLAINT EXPANSION ---
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isComplaint
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const SizedBox(height: 16),
                        const Text("What went wrong?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _complaintTags.map((tag) {
                            bool isSelected = _selectedIssues.contains(tag);
                            return FilterChip(
                              label: Text(tag),
                              selected: isSelected,
                              selectedColor: Colors.red.shade100,
                              checkmarkColor: Colors.red,
                              backgroundColor: Colors.grey.shade100,
                              onSelected: (selected) {
                                setState(() {
                                  selected ? _selectedIssues.add(tag) : _selectedIssues.remove(tag);
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),

            // --- TEXT FEEDBACK ---
            if (_rating > 0) ...[
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: isComplaint ? "Provide more details for our mechanics..." : "Leave a comment (optional)",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- SUBMIT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit Feedback", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}