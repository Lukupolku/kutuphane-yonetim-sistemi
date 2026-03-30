import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/book_lookup_service.dart';
import '../providers/book_provider.dart';
import '../models/book.dart';
import '../theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _lookupService = BookLookupService();
  List<Book> _results = [];
  bool _loading = false;
  String? _error;

  Future<void> _search() async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await _lookupService.search(query);
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Arama yapilamadi. Internet baglantinizi kontrol edin.';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kitap Ara')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Kitap adi, yazar veya ISBN...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _results = []);
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!,
                  style: const TextStyle(color: MebColors.error)),
            ),
          Expanded(
            child: _results.isEmpty && !_loading
                ? Center(
                    child: Text(
                      _searchCtrl.text.isEmpty
                          ? 'Kitap adi, yazar veya ISBN ile arayin'
                          : 'Sonuc bulunamadi',
                      style: TextStyle(color: MebColors.textTertiary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _results.length,
                    itemBuilder: (context, i) =>
                        _SearchResultTile(book: _results[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final Book book;
  const _SearchResultTile({required this.book});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _addBook(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: book.coverImageUrl != null
                    ? Image.network(
                        book.coverImageUrl!,
                        width: 50,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _Placeholder(),
                      )
                    : _Placeholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        )),
                    if (book.authors.isNotEmpty)
                      Text(book.authors.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: MebColors.textSecondary)),
                    Row(
                      children: [
                        if (book.publisher != null)
                          Text(book.publisher!,
                              style: const TextStyle(fontSize: 11, color: MebColors.textTertiary)),
                        if (book.publishedDate != null)
                          Text(' (${book.publishedDate})',
                              style: const TextStyle(fontSize: 11, color: MebColors.textTertiary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.add_circle_outline, color: MebColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  void _addBook(BuildContext context) async {
    final bookProv = context.read<BookProvider>();
    final detail = await bookProv.addBook(book);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${book.title}" eklendi!')),
      );
      Navigator.pushNamed(context, '/book-detail', arguments: detail.userBook.id);
    }
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 72,
      decoration: BoxDecoration(
        color: MebColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.menu_book, size: 24, color: MebColors.primary),
    );
  }
}
