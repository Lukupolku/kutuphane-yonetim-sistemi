import 'dart:io';

import 'package:excel/excel.dart' hide Border;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/book.dart';
import '../models/holding.dart';
import '../providers/inventory_provider.dart';
import '../providers/school_provider.dart';

/// Excel import template format:
/// | Başlık | Yazar | Yayınevi | ISBN | Adet |
/// Row 1 = header, Row 2+ = data
class ExcelImportScreen extends StatefulWidget {
  const ExcelImportScreen({super.key});

  @override
  State<ExcelImportScreen> createState() => _ExcelImportScreenState();
}

class _ExcelImportScreenState extends State<ExcelImportScreen> {
  List<_ImportRow> _rows = [];
  bool _loading = false;
  bool _saving = false;
  String? _error;
  String? _fileName;

  Future<void> _pickFile() async {
    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _loading = false;
        });
        return;
      }

      final file = result.files.first;
      _fileName = file.name;

      final bytes = File(file.path!).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      final sheet = excel.tables.values.first;
      final rows = sheet.rows;

      if (rows.length < 2) {
        setState(() {
          _loading = false;
          _error = 'Excel dosyası boş veya sadece başlık satırı var.';
        });
        return;
      }

      // Skip header row (index 0), parse data rows
      final parsed = <_ImportRow>[];
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        final title = _cellValue(row, 0);
        if (title.isEmpty) continue;

        parsed.add(_ImportRow(
          title: title,
          author: _cellValue(row, 1),
          publisher: _cellValue(row, 2),
          isbn: _cellValue(row, 3),
          quantity: _cellInt(row, 4, defaultValue: 1),
          selected: true,
        ));
      }

      setState(() {
        _rows = parsed;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Dosya okunamadı: ${e.toString()}';
      });
    }
  }

  String _cellValue(List<Data?> row, int index) {
    if (index >= row.length || row[index] == null) return '';
    return row[index]!.value?.toString().trim() ?? '';
  }

  int _cellInt(List<Data?> row, int index, {int defaultValue = 1}) {
    final val = _cellValue(row, index);
    if (val.isEmpty) return defaultValue;
    return int.tryParse(val) ?? defaultValue;
  }

  Future<void> _import() async {
    final selectedRows = _rows.where((r) => r.selected).toList();
    if (selectedRows.isEmpty) return;

    setState(() {
      _saving = true;
    });

    try {
      final provider = context.read<InventoryProvider>();
      final schoolId = context.read<SchoolProvider>().selectedSchool!.id;
      const uuid = Uuid();

      int imported = 0;
      for (final row in selectedRows) {
        final authors = row.author.isNotEmpty
            ? row.author
                .split(',')
                .map((a) => a.trim())
                .where((a) => a.isNotEmpty)
                .toList()
            : <String>['Bilinmiyor'];

        final book = Book(
          id: uuid.v4(),
          isbn: row.isbn.isNotEmpty ? row.isbn : null,
          title: row.title,
          authors: authors,
          publisher: row.publisher.isNotEmpty ? row.publisher : null,
          language: 'tr',
          source: BookSource.manual,
          createdAt: DateTime.now(),
        );

        // Add multiple times for quantity
        for (int q = 0; q < row.quantity; q++) {
          await provider.addBook(
            book: book,
            schoolId: schoolId,
            addedBy: 'excel_import',
            source: HoldingSource.manual,
          );
        }
        imported++;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$imported kitap başarıyla eklendi')),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
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
        title: const Text('Excel\'den Yükle'),
      ),
      body: Column(
        children: [
          // Template info
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Excel Şablonu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'İlk satır başlık olmalıdır:',
                  style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      _ColumnChip('Başlık*'),
                      _ColumnChip('Yazar'),
                      _ColumnChip('Yayınevi'),
                      _ColumnChip('ISBN'),
                      _ColumnChip('Adet'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '* Zorunlu alan. Adet boşsa 1 kabul edilir.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blue.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Pick file button
          if (_rows.isEmpty && !_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _pickFile,
                icon: const Icon(Icons.file_upload),
                label: const Text('Excel Dosyası Seç'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),

          if (_loading) const Center(child: CircularProgressIndicator()),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // Preview list
          if (_rows.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    _fileName ?? 'Dosya',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Spacer(),
                  Text(
                    '${_rows.where((r) => r.selected).length}/${_rows.length} seçili',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        final allSelected =
                            _rows.every((r) => r.selected);
                        for (final r in _rows) {
                          r.selected = !allSelected;
                        }
                      });
                    },
                    child: Text(
                      _rows.every((r) => r.selected)
                          ? 'Tümünü Kaldır'
                          : 'Tümünü Seç',
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _rows.length,
                itemBuilder: (context, index) {
                  final row = _rows[index];
                  return CheckboxListTile(
                    value: row.selected,
                    onChanged: (v) {
                      setState(() {
                        row.selected = v ?? false;
                      });
                    },
                    title: Text(
                      row.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        if (row.author.isNotEmpty) row.author,
                        if (row.publisher.isNotEmpty) row.publisher,
                        if (row.isbn.isNotEmpty) 'ISBN: ${row.isbn}',
                        'Adet: ${row.quantity}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    dense: true,
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () {
                                setState(() {
                                  _rows = [];
                                  _fileName = null;
                                });
                              },
                        child: const Text('Farklı Dosya'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: (_saving ||
                                _rows.where((r) => r.selected).isEmpty)
                            ? null
                            : _import,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(
                          '${_rows.where((r) => r.selected).length} Kitap Ekle',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImportRow {
  final String title;
  final String author;
  final String publisher;
  final String isbn;
  final int quantity;
  bool selected;

  _ImportRow({
    required this.title,
    required this.author,
    required this.publisher,
    required this.isbn,
    required this.quantity,
    required this.selected,
  });
}

class _ColumnChip extends StatelessWidget {
  final String label;
  const _ColumnChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
