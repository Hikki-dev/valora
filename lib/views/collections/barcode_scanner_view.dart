import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: [BarcodeFormat.upcA, BarcodeFormat.upcE, BarcodeFormat.ean13, BarcodeFormat.ean8],
  );

  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_scanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final String upc = barcodes.first.rawValue ?? '';
                if (upc.isNotEmpty) {
                  setState(() => _scanned = true);
                  _controller.stop();
                  Navigator.pop(context, upc);
                }
              }
            },
          ),
          // Custom Scanning Overlay
          _buildOverlay(context),
          
          // Back button
          Positioned(
            top: 60,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black.withValues(alpha: 0.5),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    return Column(
      children: [
        Expanded(child: Container(color: Colors.black.withValues(alpha: 0.5))),
        Row(
          children: [
            Expanded(child: Container(color: Colors.black.withValues(alpha: 0.5))),
            Container(
              width: 280,
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyanAccent, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            Expanded(child: Container(color: Colors.black.withValues(alpha: 0.5))),
          ],
        ),
        Expanded(
          child: Container(
            color: Colors.black.withValues(alpha: 0.5),
            width: double.infinity,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ALIGN BARCODE',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Scanning physical discs...',
                    style: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
