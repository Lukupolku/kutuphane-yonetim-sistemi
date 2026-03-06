import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/isbn_lookup_service.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;

  late final AnimationController _animController;

  static final RegExp _isbnRegExp = RegExp(r'^\d{13}$');

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_processing) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue == null) continue;
      if (!_isbnRegExp.hasMatch(rawValue)) continue;

      setState(() {
        _processing = true;
      });

      final isbn = rawValue;
      final lookupService = context.read<IsbnLookupService>();
      final book = await lookupService.lookupByIsbn(isbn);

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/book/confirm',
        arguments: {
          'book': book,
          'isbn': isbn,
          'source': 'BARCODE_SCAN',
        },
      );
      return;
    }
  }

  /// Computes the viewfinder rectangle for a given container size.
  static Rect _scanRect(Size size) {
    final scanWidth = size.width * 0.75;
    final scanHeight = scanWidth * 0.45;
    final left = (size.width - scanWidth) / 2;
    final top = (size.height - scanHeight) / 2;
    return Rect.fromLTWH(left, top, scanWidth, scanHeight);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barkod Tara'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onBarcodeDetected,
          ),
          // Viewfinder overlay + scan line
          if (!_processing)
            LayoutBuilder(
              builder: (context, constraints) {
                final size =
                    Size(constraints.maxWidth, constraints.maxHeight);
                final rect = _scanRect(size);

                return Stack(
                  children: [
                    // Semi-transparent overlay with cutout
                    CustomPaint(
                      size: size,
                      painter: _ViewfinderPainter(rect),
                    ),
                    // Animated scan line
                    AnimatedBuilder(
                      animation: _animController,
                      builder: (context, _) {
                        final lineY =
                            rect.top + (_animController.value * rect.height);
                        return Padding(
                          padding: EdgeInsets.only(
                            top: lineY,
                            left: rect.left + 8,
                            right: size.width - rect.right + 8,
                          ),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Container(
                              height: 2,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.red.withOpacity(0),
                                    Colors.red.withOpacity(0.8),
                                    Colors.red,
                                    Colors.red.withOpacity(0.8),
                                    Colors.red.withOpacity(0),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          // Bottom hint
          if (!_processing)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black87,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                child: const Text(
                  'Kitabın arka kapağındaki barkodu çerçeveye hizalayın',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          // Processing overlay
          if (_processing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Card(
                  margin: const EdgeInsets.all(32),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'ISBN aranıyor...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Draws a semi-transparent overlay with a clear rectangular viewfinder window
/// and corner brackets.
class _ViewfinderPainter extends CustomPainter {
  final Rect scanRect;
  _ViewfinderPainter(this.scanRect);

  @override
  void paint(Canvas canvas, Size size) {
    // Semi-transparent background with cutout
    final bgPaint = Paint()..color = Colors.black.withOpacity(0.5);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(RRect.fromRectAndRadius(
              scanRect, const Radius.circular(12))),
      ),
      bgPaint,
    );

    // Thin border around scan area
    final borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(scanRect, const Radius.circular(12)),
      borderPaint,
    );

    // Corner brackets
    const cornerLen = 24.0;
    const cornerWidth = 3.0;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round;

    final left = scanRect.left;
    final top = scanRect.top;
    final right = scanRect.right;
    final bottom = scanRect.bottom;

    // Top-left
    canvas.drawLine(
        Offset(left, top + cornerLen), Offset(left, top), cornerPaint);
    canvas.drawLine(
        Offset(left, top), Offset(left + cornerLen, top), cornerPaint);

    // Top-right
    canvas.drawLine(
        Offset(right - cornerLen, top), Offset(right, top), cornerPaint);
    canvas.drawLine(
        Offset(right, top), Offset(right, top + cornerLen), cornerPaint);

    // Bottom-left
    canvas.drawLine(
        Offset(left, bottom - cornerLen), Offset(left, bottom), cornerPaint);
    canvas.drawLine(
        Offset(left, bottom), Offset(left + cornerLen, bottom), cornerPaint);

    // Bottom-right
    canvas.drawLine(Offset(right - cornerLen, bottom), Offset(right, bottom),
        cornerPaint);
    canvas.drawLine(Offset(right, bottom), Offset(right, bottom - cornerLen),
        cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _ViewfinderPainter oldDelegate) =>
      oldDelegate.scanRect != scanRect;
}
