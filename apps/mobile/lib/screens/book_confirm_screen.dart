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

  const BookConfirmScreen({
    super.key,
    this.book,
    this.isbn,
    required this.sourceType,
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
    if (widget.isbn != null) {
      _isbnController.text = widget.isbn!;
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
    Book bookToSave;

    if (widget.book != null) {
      bookToSave = widget.book!;
    } else {
      if (!_formKey.currentState!.validate()) return;

      final uuid = const Uuid();
      final authors = _authorsController.text
          .split(',')
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty)
          .toList();

      final isbnText = _isbnController.text.trim();

      bookToSave = Book(
        id: uuid.v4(),
        isbn: isbnText.isNotEmpty ? isbnText : null,
        title: _titleController.text.trim(),
        authors: authors,
        publisher: _publisherController.text.trim().isNotEmpty
            ? _publisherController.text.trim()
            : null,
        language: 'tr',
        source: BookSource.fromString(widget.sourceType),
        createdAt: DateTime.now(),
      );
    }

    setState(() {
      _saving = true;
    });

    try {
      final schoolProvider = context.read<SchoolProvider>();
      final schoolId = schoolProvider.selectedSchool!.id;

      await context.read<InventoryProvider>().addBook(
            book: bookToSave,
            schoolId: schoolId,
            addedBy: 'current_user',
            source: HoldingSource.fromString(widget.sourceType),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book != null ? 'Kitap Onayla' : 'Manuel Giris'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.book != null) _buildBookInfoCard() else _buildManualForm(),
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

  Widget _buildBookInfoCard() {
    final book = widget.book!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              book.authors.join(', '),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            if (book.publisher != null) ...[
              const SizedBox(height: 4),
              Text(
                book.publisher!,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (book.isbn != null) ...[
              const SizedBox(height: 8),
              Text(
                book.isbn!,
                style: const TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildManualForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Baslik',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Baslik zorunludur';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _authorsController,
            decoration: const InputDecoration(
              labelText: 'Yazar',
              helperText: 'Birden fazla yazar icin virgul ile ayirin',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Yazar zorunludur';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _publisherController,
            decoration: const InputDecoration(
              labelText: 'Yayinevi',
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
