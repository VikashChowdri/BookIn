import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../data/services/database_service.dart';

class QRScannerScreen extends StatefulWidget {
  final String expectedBookingId;
  final String nextStatus;
  final VoidCallback onSuccess;

  const QRScannerScreen({
    super.key,
    required this.expectedBookingId,
    required this.nextStatus,
    required this.onSuccess,
  });

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code == null) return;

      setState(() => _isProcessing = true);

      if (code == widget.expectedBookingId) {
        // Success
        _controller.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR Code verified! Booking marked as ${widget.nextStatus}.'),
            backgroundColor: Colors.green,
          ),
        );
        // We will call DatabaseService to update status to 'active' or 'completed'
        try {
          await DatabaseService.instance.updateBookingStatus(code, widget.nextStatus);
          widget.onSuccess();
          if (mounted) Navigator.pop(context);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating booking: $e')),
            );
          }
          setState(() => _isProcessing = false);
        }
      } else {
        // Failed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid QR Code for this booking.'),
            backgroundColor: Colors.red,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _isProcessing = false);
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          CustomPaint(
            painter: ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Align QR code within the frame',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    // Draw the dark overlay
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Cut out a rounded square in the middle
    final double cutoutSize = size.width * 0.7;
    final double top = (size.height - cutoutSize) / 2;
    final double left = (size.width - cutoutSize) / 2;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, cutoutSize, cutoutSize),
      const Radius.circular(24),
    );

    // Clear the center
    canvas.drawRRect(rect, Paint()..blendMode = BlendMode.clear);
    
    // Draw corners
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
      
    final double cornerLength = 30;
    
    // Top Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top)
        ..lineTo(left + cornerLength, top),
      cornerPaint,
    );
    // Top Right
    canvas.drawPath(
      Path()
        ..moveTo(left + cutoutSize - cornerLength, top)
        ..lineTo(left + cutoutSize, top)
        ..lineTo(left + cutoutSize, top + cornerLength),
      cornerPaint,
    );
    // Bottom Left
    canvas.drawPath(
      Path()
        ..moveTo(left, top + cutoutSize - cornerLength)
        ..lineTo(left, top + cutoutSize)
        ..lineTo(left + cornerLength, top + cutoutSize),
      cornerPaint,
    );
    // Bottom Right
    canvas.drawPath(
      Path()
        ..moveTo(left + cutoutSize - cornerLength, top + cutoutSize)
        ..lineTo(left + cutoutSize, top + cutoutSize)
        ..lineTo(left + cutoutSize, top + cutoutSize - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
