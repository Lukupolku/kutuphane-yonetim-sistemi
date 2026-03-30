import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/book_lookup_service.dart';
import '../providers/book_provider.dart';
import '../theme.dart';

class BarcodeScanScreen extends StatefulWidget {
  const BarcodeScanScreen({super.key});

  @override
  State<BarcodeScanScreen> createState() => _BarcodeScanScreenState();
}

class _BarcodeScanScreenState extends State<BarcodeScanScreen>
    with SingleTickerProviderStateMixin {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  final _lookupService = BookLookupService();
  bool _processing = false;
  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_processing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null) return;

    final value = barcode.rawValue;
    if (value == null || !RegExp(r'^\d{13}$').hasMatch(value)) return;

    setState(() => _processing = true);

    try {
      final book = await _lookupService.lookupByIsbn(value);
      if (!mounted) return;

      if (book != null) {
        final bookProv = context.read<BookProvider>();
        final detail = await bookProv.addBook(book);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${book.title}" eklendi!')),
          );
          Navigator.pushReplacementNamed(
              context, '/book-detail',
              arguments: detail.userBook.id);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ISBN $value icin kitap bulunamadi'),
            action: SnackBarAction(
              label: 'Manuel Ekle',
              onPressed: () => Navigator.pushReplacementNamed(context, '/add-manual'),
            ),
          ),
        );
        setState(() => _processing = false);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bir hata olustu. Tekrar deneyin.')),
        );
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Barkod Tara'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay
          Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: MebColors.primary, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: AnimatedBuilder(
                animation: _animCtrl,
                builder: (_, __) => Align(
                  alignment: Alignment(0, -1 + _animCtrl.value * 2),
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: MebColors.primary.withAlpha(180),
                      borderRadius: BorderRadius.circular(1),
                      boxShadow: [
                        BoxShadow(
                          color: MebColors.primary.withAlpha(80),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bottom instruction
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (_processing)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  Text('Barkodu cerceve icerisine hizalayin',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      )),
              ],
            ),
          ),
          // Flashlight toggle
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.small(
              heroTag: 'flash',
              backgroundColor: Colors.white.withAlpha(50),
              onPressed: () => _controller.toggleTorch(),
              child: const Icon(Icons.flashlight_on_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
