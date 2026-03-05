import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../models/holding.dart';
import '../providers/inventory_provider.dart';
import '../providers/school_provider.dart';
import '../services/isbn_lookup_service.dart';

class ShelfResultsScreen extends StatefulWidget {
  final List<String> detectedTitles;

  const ShelfResultsScreen({super.key, required this.detectedTitles});

  @override
  State<ShelfResultsScreen> createState() => _ShelfResultsScreenState();
}

class _ShelfResultsScreenState extends State<ShelfResultsScreen> {
  late List<bool> _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = List<bool>.filled(widget.detectedTitles.length, true);
  }

  bool get _allSelected => _selected.every((s) => s);

  int get _selectedCount => _selected.where((s) => s).length;

  void _toggleAll() {
    setState(() {
      final newValue = !_allSelected;
      _selected = List<bool>.filled(widget.detectedTitles.length, newValue);
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
    });

    try {
      final lookupService = context.read<IsbnLookupService>();
      final inventoryProvider = context.read<InventoryProvider>();
      final schoolProvider = context.read<SchoolProvider>();
      final schoolId = schoolProvider.selectedSchool!.id;
      const uuid = Uuid();

      for (int i = 0; i < widget.detectedTitles.length; i++) {
        if (!_selected[i]) continue;

        final title = widget.detectedTitles[i];
        final results = await lookupService.searchByTitle(title);

        Book book;
        if (results.isNotEmpty) {
          book = results.first;
        } else {
          book = Book(
            id: uuid.v4(),
            title: title,
            authors: ['Bilinmiyor'],
            language: 'tr',
            source: BookSource.ocr,
            createdAt: DateTime.now(),
          );
        }

        await inventoryProvider.addBook(
          book: book,
          schoolId: schoolId,
          addedBy: 'current_user',
          source: HoldingSource.shelfOcr,
        );
      }

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
        title: Text('Raf Sonuçları (${widget.detectedTitles.length})'),
      ),
      body: Column(
        children: [
          CheckboxListTile(
            title: Text(_allSelected ? 'Tümünü Kaldır' : 'Tümünü Seç'),
            value: _allSelected,
            onChanged: (_) => _toggleAll(),
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: widget.detectedTitles.length,
              itemBuilder: (context, index) {
                return CheckboxListTile(
                  title: Text(widget.detectedTitles[index]),
                  value: _selected[index],
                  onChanged: (value) {
                    setState(() {
                      _selected[index] = value ?? false;
                    });
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed:
                    (_selectedCount == 0 || _saving) ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text('$_selectedCount Kitap Kaydet'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
