import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/isbn_lookup_service.dart';
import '../services/ocr_service.dart';

class CoverOcrScreen extends StatefulWidget {
  const CoverOcrScreen({super.key});

  @override
  State<CoverOcrScreen> createState() => _CoverOcrScreenState();
}

class _CoverOcrScreenState extends State<CoverOcrScreen> {
  final OcrService _ocrService = OcrService();
  bool _processing = false;
  String? _error;

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

    try {
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

      final text = await _ocrService.extractText(File(photo.path));

      if (!mounted) return;

      if (text.isEmpty) {
        setState(() {
          _processing = false;
          _error = 'Metin taninamadi. Lutfen tekrar deneyin.';
        });
        return;
      }

      final parsed = OcrService.parseBookTitle(text);

      final lookupService = context.read<IsbnLookupService>();
      final results = await lookupService.searchByTitle(parsed.title);

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        '/book/confirm',
        arguments: {
          'book': results.firstOrNull,
          'isbn': null,
          'source': 'COVER_OCR',
          'parsedTitle': parsed.title,
          'parsedAuthor': parsed.author,
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kapak OCR'),
      ),
      body: Center(
        child: _processing ? _buildProcessing() : _buildError(),
      ),
    );
  }

  Widget _buildProcessing() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text(
          'Kapak metni taniniyor...',
          style: TextStyle(fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildError() {
    if (_error == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 48,
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
        ElevatedButton(
          onPressed: _captureAndProcess,
          child: const Text('Tekrar Dene'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            Navigator.pushReplacementNamed(
              context,
              '/book/confirm',
              arguments: {
                'book': null,
                'isbn': null,
                'source': 'MANUAL',
              },
            );
          },
          child: const Text('Manuel Giris'),
        ),
      ],
    );
  }
}
