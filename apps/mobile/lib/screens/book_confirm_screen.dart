import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../models/holding.dart';
import '../providers/inventory_provider.dart';
import '../providers/school_provider.dart';

class BookConfirmScreen extends StatefulWidget {
  final Book? book;
  final String? isbn;
  final String sourceType;
  final String? parsedTitle;
  final String? parsedAuthor;

  const BookConfirmScreen({
    super.key,
    this.book,
    this.isbn,
    required this.sourceType,
    this.parsedTitle,
    this.parsedAuthor,
  });

  @override
  State<BookConfirmScreen> createState() => _BookConfirmScreenState();
}

class _BookConfirmScreenState extends State<BookConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorsController = TextEditingController();
  final _publisherController = TextEditingController();
  final _isbnController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      _titleController.text = widget.book!.title;
      _authorsController.text = widget.book!.authors.join(', ');
      _publisherController.text = widget.book!.publisher ?? '';
      _isbnController.text = widget.book!.isbn ?? widget.isbn ?? '';
    } else {
      _titleController.text = widget.parsedTitle ?? '';
      _authorsController.text = widget.parsedAuthor ?? '';
      _isbnController.text = widget.isbn ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorsController.dispose();
    _publisherController.dispose();
    _isbnController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    try {
      final uuid = const Uuid();
      final authors = _authorsController.text
          .split(',')
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty)
          .toList();

      final isbnText = _isbnController.text.trim();

      final bookToSave = Book(
        id: widget.book?.id ?? uuid.v4(),
        isbn: isbnText.isNotEmpty ? isbnText : null,
        title: _titleController.text.trim(),
        authors: authors.isEmpty ? ['Bilinmiyor'] : authors,
        publisher: _publisherController.text.trim().isNotEmpty
            ? _publisherController.text.trim()
            : null,
        publishedDate: widget.book?.publishedDate,
        pageCount: widget.book?.pageCount,
        coverImageUrl: widget.book?.coverImageUrl,
        language: widget.book?.language ?? 'tr',
        source: widget.book?.source ?? _resolveBookSource(),
        createdAt: widget.book?.createdAt ?? DateTime.now(),
      );

      final schoolProvider = context.read<SchoolProvider>();
      final schoolId = schoolProvider.selectedSchool!.id;

      await context.read<InventoryProvider>().addBook(
            book: bookToSave,
            schoolId: schoolId,
            addedBy: 'current_user',
            source: _resolveHoldingSource(),
          );

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  BookSource _resolveBookSource() {
    switch (widget.sourceType) {
      case 'GOOGLE_BOOKS':
        return BookSource.googleBooks;
      case 'OPEN_LIBRARY':
        return BookSource.openLibrary;
      case 'OCR':
      case 'COVER_OCR':
      case 'SHELF_OCR':
        return BookSource.ocr;
      default:
        return BookSource.manual;
    }
  }

  HoldingSource _resolveHoldingSource() {
    switch (widget.sourceType) {
      case 'BARCODE_SCAN':
        return HoldingSource.barcodeScan;
      case 'COVER_OCR':
        return HoldingSource.coverOcr;
      case 'SHELF_OCR':
        return HoldingSource.shelfOcr;
      default:
        return HoldingSource.manual;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFromLookup = widget.book != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isFromLookup ? 'Kitap Onayla' : 'Manuel Giriş'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isFromLookup && widget.book!.coverImageUrl != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.book!.coverImageUrl!,
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            if (isFromLookup)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Color(0xFF16A34A)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kitap bilgileri bulundu. Gerekirse düzenleyebilirsiniz.',
                          style: TextStyle(color: Color(0xFF166534)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            _buildForm(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Kaydet'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Başlık',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Başlık zorunludur';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _authorsController,
            decoration: const InputDecoration(
              labelText: 'Yazar',
              helperText: 'Birden fazla yazar için virgülle ayırın',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _publisherController,
            decoration: const InputDecoration(
              labelText: 'Yayınevi',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _isbnController,
            decoration: const InputDecoration(
              labelText: 'ISBN',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }
}
