import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/book_provider.dart';
import '../models/book_note.dart';
import '../theme.dart';

/// Captures a photo of a book page, runs OCR, and lets the user
/// select underlined/highlighted text to save as a note.
class NoteCaptureScreen extends StatefulWidget {
  const NoteCaptureScreen({super.key});

  @override
  State<NoteCaptureScreen> createState() => _NoteCaptureScreenState();
}

class _NoteCaptureScreenState extends State<NoteCaptureScreen> {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _picker = ImagePicker();

  File? _imageFile;
  List<String> _lines = [];
  final Set<int> _selectedLines = {};
  bool _processing = false;
  final _pageCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureImage());
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _pageCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    final xFile = await _picker.pickImage(source: ImageSource.camera);
    if (xFile == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      _imageFile = File(xFile.path);
      _processing = true;
    });

    try {
      final inputImage = InputImage.fromFile(_imageFile!);
      final result = await _textRecognizer.processImage(inputImage);

      if (mounted) {
        setState(() {
          _lines = result.blocks
              .expand((block) => block.lines)
              .map((line) => line.text)
              .toList();
          _processing = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Metin tanima basarisiz oldu')),
        );
      }
    }
  }

  void _saveNote() {
    if (_selectedLines.isEmpty) return;

    final userBookId = ModalRoute.of(context)!.settings.arguments as String;
    final bookProv = context.read<BookProvider>();

    final content = _selectedLines.toList()
      ..sort();
    final selectedText = content.map((i) => _lines[i]).join('\n');

    bookProv.addNote(
      userBookId,
      content: selectedText,
      pageNumber: int.tryParse(_pageCtrl.text),
      type: NoteType.highlight,
      imagePath: _imageFile?.path,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Not kaydedildi!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sayfa Notu'),
        actions: [
          if (_selectedLines.isNotEmpty)
            TextButton.icon(
              onPressed: _saveNote,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('Kaydet', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _processing
          ? const Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Metin taniniyor...'),
              ],
            ))
          : _lines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.camera_alt_outlined, size: 64, color: MebColors.textTertiary),
                      const SizedBox(height: 16),
                      Text('Sayfa fotografi cekin',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: MebColors.textSecondary,
                          )),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _captureImage,
                        icon: const Icon(Icons.camera_alt_rounded),
                        label: const Text('Fotograf Cek'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Image preview
                    if (_imageFile != null)
                      SizedBox(
                        height: 120,
                        width: double.infinity,
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      ),

                    // Page number input
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.numbers, size: 18, color: MebColors.textTertiary),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _pageCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                hintText: 'Sayfa',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text('${_selectedLines.length} satir secili',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _selectedLines.isNotEmpty
                                    ? MebColors.primary
                                    : MebColors.textTertiary,
                              )),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Alti cizili satirlara dokunarak secin:',
                          style: TextStyle(fontSize: 12, color: MebColors.textTertiary)),
                    ),
                    const SizedBox(height: 4),

                    // Selectable lines
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _lines.length,
                        itemBuilder: (context, i) {
                          final selected = _selectedLines.contains(i);
                          return InkWell(
                            onTap: () {
                              setState(() {
                                if (selected) {
                                  _selectedLines.remove(i);
                                } else {
                                  _selectedLines.add(i);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 10),
                              margin: const EdgeInsets.only(bottom: 2),
                              decoration: BoxDecoration(
                                color: selected
                                    ? MebColors.primary.withAlpha(25)
                                    : null,
                                borderRadius: BorderRadius.circular(6),
                                border: selected
                                    ? Border.all(color: MebColors.primary.withAlpha(80))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selected
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    size: 18,
                                    color: selected
                                        ? MebColors.primary
                                        : MebColors.textTertiary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_lines[i],
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: selected
                                              ? MebColors.textPrimary
                                              : MebColors.textSecondary,
                                        )),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _lines.isNotEmpty
          ? FloatingActionButton(
              heroTag: 'retake',
              onPressed: _captureImage,
              child: const Icon(Icons.camera_alt_rounded),
            )
          : null,
    );
  }
}
