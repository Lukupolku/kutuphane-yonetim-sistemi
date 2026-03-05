import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';
import 'shelf_results_screen.dart';

class ShelfOcrScreen extends StatefulWidget {
  const ShelfOcrScreen({super.key});

  @override
  State<ShelfOcrScreen> createState() => _ShelfOcrScreenState();
}

class _ShelfOcrScreenState extends State<ShelfOcrScreen> {
  bool _processing = false;
  String? _error;
  final OcrService _ocrService = OcrService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureAndProcess();
    });
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _captureAndProcess() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);

    if (!mounted) return;

    if (photo == null) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final text = await _ocrService.extractText(File(photo.path));
      final titles = OcrService.parseShelfTexts(text);

      if (!mounted) return;

      if (titles.isEmpty) {
        setState(() {
          _processing = false;
          _error = 'Kitap sırtı algılanamadı. Lütfen tekrar deneyin.';
        });
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ShelfResultsScreen(detectedTitles: titles),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = 'Kitap sırtı algılanamadı. Lütfen tekrar deneyin.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raf OCR'),
      ),
      body: Center(
        child: _processing
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Raf görüntüsü işleniyor...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              )
            : _error != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _captureAndProcess,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
      ),
    );
  }
}
