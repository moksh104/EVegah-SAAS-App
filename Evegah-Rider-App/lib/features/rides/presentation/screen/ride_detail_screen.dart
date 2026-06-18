import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../widgets/feedback_bottom_sheet.dart';

class RideDetailScreen extends StatefulWidget {
  final Map<String, dynamic> rideData;

  const RideDetailScreen({super.key, required this.rideData});

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  GoogleMapController? _mapController;
  double _sliderValue = 0.0;

  // --- MOCK ROUTE DATA ---
  final List<LatLng> _routePoints = const [
    LatLng(22.3072, 73.1812),
    LatLng(22.3075, 73.1815),
    LatLng(22.3080, 73.1818),
    LatLng(22.3085, 73.1822),
    LatLng(22.3092, 73.1825),
    LatLng(22.3100, 73.1830),
    LatLng(22.3105, 73.1835),
    LatLng(22.3110, 73.1840),
  ];

  // --- PDF GENERATION LOGIC ---
  Future<void> _generateAndDownloadInvoice() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("EVegah Mobility", style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                pw.SizedBox(height: 8),
                pw.Text("Official Ride Invoice", style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
                pw.SizedBox(height: 40),
                pw.Divider(),
                pw.SizedBox(height: 20),
                _buildPdfRow("Ride ID:", widget.rideData['rideId']),
                _buildPdfRow("Date:", widget.rideData['date']),
                _buildPdfRow("Vehicle Scanned:", widget.rideData['vehicleId']),
                _buildPdfRow("Distance Covered:", widget.rideData['distance']),
                _buildPdfRow("Total Time:", widget.rideData['time']),
                pw.SizedBox(height: 30),
                pw.Divider(),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("Total Amount Deducted:", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text(widget.rideData['cost'], style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                  ],
                ),
                pw.SizedBox(height: 40),
                pw.Text("Thank you for riding smart and riding green!", style: pw.TextStyle(fontStyle: pw.FontStyle.italic, color: PdfColors.grey)),
              ],
            ),
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'EVegah_Invoice_${widget.rideData['rideId']}.pdf',
    );
  }

  pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 16)),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    LatLng currentBikePosition = _routePoints[_sliderValue.toInt()];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Slightly cooler background
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent, // Makes the top look cleaner
        foregroundColor: const Color(0xFF111827),
        title: const Text("Ride Receipt", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            
            // --- UPGRADED ROUTE MAP ---
            Container(
              width: double.infinity,
              height: 280, // Made it taller
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.green.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
                ],
                border: Border.all(color: Colors.green.withValues(alpha: 0.3), width: 2), // Gives it a nice frame
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(target: _routePoints.first, zoom: 16.5),
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: (controller) => _mapController = controller,
                      polylines: {
                        Polyline(
                          polylineId: const PolylineId('route_history'),
                          points: _routePoints,
                          color: Colors.blue,
                          width: 5,
                        )
                      },
                      markers: {
                        Marker(
                          markerId: const MarkerId('playback_bike'),
                          position: currentBikePosition,
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                        )
                      },
                    ),

                    // --- UPGRADED SLEEK SLIDER PILL ---
                    Positioned(
                      bottom: 16, left: 24, right: 24,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30), // Pill shape
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
                          ],
                        ),
                        child: Row(
                          children: [
                           // const Icon(Icons.play_arrow_rounded, color: Colors.green, size: 28),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 4,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                ),
                                child: Slider(
                                  activeColor: Colors.green,
                                  inactiveColor: Colors.grey.shade200,
                                  min: 0.0,
                                  max: (_routePoints.length - 1).toDouble(),
                                  value: _sliderValue,
                                  onChanged: (value) {
                                    setState(() => _sliderValue = value);
                                    _mapController?.animateCamera(CameraUpdate.newLatLng(_routePoints[value.toInt()]));
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- UPGRADED RECEIPT CARD ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.grey.shade200, width: 1.5), // Crisp border
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Total Fare Deducted", style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    widget.rideData['cost'],
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF111827), letterSpacing: -1),
                  ),
                  const SizedBox(height: 24),
                  
                  // A nice dotted-style divider (using a container row)
                  Row(
                    children: List.generate(
                      40, (index) => Expanded(child: Container(color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade300, height: 2))
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  _buildReceiptRow("Date", widget.rideData['date']),
                  const SizedBox(height: 16),
                  _buildReceiptRow("Ride ID", widget.rideData['rideId']),
                  const SizedBox(height: 16),
                  _buildReceiptRow("Vehicle", widget.rideData['vehicleId']),
                  const SizedBox(height: 16),
                  _buildReceiptRow("Distance", widget.rideData['distance']),
                  const SizedBox(height: 16),
                  _buildReceiptRow("Duration", widget.rideData['time']),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- DOWNLOAD INVOICE BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _generateAndDownloadInvoice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1452),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 5,
                  shadowColor: const Color(0xFF1E1452).withValues(alpha: 0.4),
                ),
                icon: const Icon(Icons.receipt_long_rounded, size: 24),
                label: const Text("Download Invoice", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 60,
              child: OutlinedButton.icon(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true, // Allows sheet to expand to fit content
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    builder: (context) => FeedbackBottomSheet(rideId: widget.rideData['rideId']),
                  );
                  
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  side: const BorderSide(color: Colors.green, width: 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                icon: const Icon(Icons.star_rate_rounded, size: 24),
                label: const Text("Rate this Ride", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Color(0xFF111827))),
      ],
    );
  }
}