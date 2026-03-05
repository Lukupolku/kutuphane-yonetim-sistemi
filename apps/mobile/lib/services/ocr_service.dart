import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Parsed result from OCR text containing a book title and optional author.
class ParsedBookText {
  final String title;
  final String? author;

  ParsedBookText({required this.title, this.author});
}

/// Service for extracting and parsing text from images using ML Kit.
class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extract text from image file using ML Kit.
  Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  /// Parse single book title/author from OCR text.
  /// First non-empty line = title (title-cased), second = author.
  static ParsedBookText parseBookTitle(String ocrText) {
    final lines = ocrText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.isEmpty) {
      return ParsedBookText(title: '');
    }

    final title = _titleCase(lines[0]);
    final author = lines.length > 1 ? _titleCase(lines[1]) : null;

    return ParsedBookText(title: title, author: author);
  }

  /// Parse shelf photo into individual book title candidates.
  /// Each non-empty line with 3+ characters is a candidate.
  static List<String> parseShelfTexts(String ocrText) {
    return ocrText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.length >= 3)
        .toList();
  }

  /// Converts text to title case: capitalize first letter of each word,
  /// lowercase the rest.
  /// Example: "KÜÇÜK PRENS" -> "Küçük Prens"
  static String _titleCase(String text) {
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Releases ML Kit resources.
  void dispose() {
    _textRecognizer.close();
  }
}
