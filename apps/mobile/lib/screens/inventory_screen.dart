import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/auth_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/school_provider.dart';

enum ViewMode { card, compact }

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String _searchQuery = '';
  ViewMode _viewMode = ViewMode.card;

  static const _pageSize = 20;
  int _visibleCount = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final schoolProvider = context.read<SchoolProvider>();
      final school = schoolProvider.selectedSchool;
      if (school != null) {
        context.read<InventoryProvider>().loadInventory(school.id);
      }
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      setState(() {
        _visibleCount += _pageSize;
      });
    }
  }

  List<InventoryItem> _filterItems(List<InventoryItem> items) {
    if (_searchQuery.isEmpty) return items;
    final q = _searchQuery.toLowerCase();
    return items.where((item) {
      return item.book.title.toLowerCase().contains(q) ||
          item.book.authors.any((a) => a.toLowerCase().contains(q)) ||
          (item.book.isbn?.contains(q) ?? false) ||
          (item.book.publisher?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _showAddBookBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Kitap Ekle',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Barkod Tara'),
                subtitle: const Text('ISBN barkodunu okut'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/scan/barcode');
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kapak Fotoğrafla'),
                subtitle: const Text('Kitap kapağını çek'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/scan/cover');
                },
              ),
              ListTile(
                leading: const Icon(Icons.shelves),
                title: const Text('Raf Fotoğrafla'),
                subtitle: const Text('Raf sırtlarını toplu çek'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/scan/shelf');
                },
              ),
              ListTile(
                leading: const Icon(Icons.table_chart),
                title: const Text('Excel\'den Yükle'),
                subtitle: const Text('Toplu kitap ekle'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/import/excel');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Manuel Giriş'),
                subtitle: const Text('Bilgileri elle yaz'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/book/confirm');
                },
              ),
            ],
            ),
          ),
        );
      },
    );
  }

  void _showEditBookDialog(InventoryItem item) {
    final titleController = TextEditingController(text: item.book.title);
    final authorsController =
        TextEditingController(text: item.book.authors.join(', '));
    final publisherController =
        TextEditingController(text: item.book.publisher ?? '');
    final isbnController =
        TextEditingController(text: item.book.isbn ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0DDD9),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Text(
                      'Kitap Düzenle',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Başlık',
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Zorunlu' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: authorsController,
                      decoration: const InputDecoration(
                        labelText: 'Yazar',
                        helperText: 'Birden fazla yazar için virgülle ayırın',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: publisherController,
                      decoration: const InputDecoration(
                        labelText: 'Yayınevi',
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: isbnController,
                      decoration: const InputDecoration(
                        labelText: 'ISBN',
                      ),
                      keyboardType: TextInputType.number,
                      readOnly: item.book.isbn != null,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('İptal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              final authors = authorsController.text
                                  .split(',')
                                  .map((a) => a.trim())
                                  .where((a) => a.isNotEmpty)
                                  .toList();
                              final isbnText = isbnController.text.trim();
                              final updatedBook = Book(
                                id: item.book.id,
                                isbn: isbnText.isNotEmpty ? isbnText : null,
                                title: titleController.text.trim(),
                                authors:
                                    authors.isEmpty ? ['Bilinmiyor'] : authors,
                                publisher:
                                    publisherController.text.trim().isNotEmpty
                                        ? publisherController.text.trim()
                                        : null,
                                publishedDate: item.book.publishedDate,
                                pageCount: item.book.pageCount,
                                coverImageUrl: item.book.coverImageUrl,
                                language: item.book.language,
                                source: item.book.source,
                                createdAt: item.book.createdAt,
                              );
                              context
                                  .read<InventoryProvider>()
                                  .updateBook(updatedBook);
                              Navigator.pop(context);
                            },
                            child: const Text('Kaydet'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDelete(InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kitabı Sil'),
          content: Text(
            '"${item.book.title}" envanterden silinecek. Emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC42B2B),
              ),
              onPressed: () {
                context
                    .read<InventoryProvider>()
                    .removeItem(item.holding.id);
                Navigator.pop(context);
              },
              child: const Text('Sil'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardItem(InventoryItem item, InventoryProvider provider) {
    return Dismissible(
      key: Key(item.holding.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        _confirmDelete(item);
        return false;
      },
      background: Container(
        color: const Color(0xFFC42B2B),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: InkWell(
          onTap: () => _showEditBookDialog(item),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: item.book.coverImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            item.book.coverImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.book,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.book,
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.book.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.book.authors.join(', '),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5A5A64),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.book.publisher != null)
                        Text(
                          item.book.publisher!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8E8E9A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          provider.updateQuantity(
                            item.holding.id,
                            item.holding.quantity + 1,
                          );
                        },
                      ),
                    ),
                    Text(
                      '${item.holding.quantity}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(
                      width: 32,
                      height: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: item.holding.quantity > 1
                            ? () {
                                provider.updateQuantity(
                                  item.holding.id,
                                  item.holding.quantity - 1,
                                );
                              }
                            : () => _confirmDelete(item),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactItem(InventoryItem item, InventoryProvider provider) {
    return InkWell(
      onTap: () => _showEditBookDialog(item),
      onLongPress: () => _confirmDelete(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFEDEBE8), width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.book.title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${item.holding.quantity}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E40AF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schoolProvider = context.watch<SchoolProvider>();
    final schoolName = schoolProvider.selectedSchool?.name ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(schoolName),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Çıkış Yap'),
                  content: const Text(
                      'Çıkış yapmak istediğinize emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Çıkış Yap'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                context.read<AuthProvider>().logout();
              }
            },
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, provider, _) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books,
                      size: 64, color: const Color(0xFF8E8E9A)),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz kitap eklenmemiş',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: const Color(0xFF5A5A64)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kitap eklemek için + butonuna dokunun',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: const Color(0xFF8E8E9A)),
                  ),
                ],
              ),
            );
          }

          final filtered = _filterItems(provider.items);
          final visible = filtered.take(_visibleCount).toList();
          final hasMore = visible.length < filtered.length;

          return Column(
            children: [
              // Search + view toggle + stats bar
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Column(
                  children: [
                    // Search box
                    SizedBox(
                      height: 38,
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() {
                          _searchQuery = v;
                          _visibleCount = _pageSize;
                        }),
                        decoration: InputDecoration(
                          hintText: 'Kitap ara...',
                          hintStyle: const TextStyle(fontSize: 13),
                          prefixIcon:
                              const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                      _visibleCount = _pageSize;
                                    });
                                  },
                                )
                              : null,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0DDD9)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                const BorderSide(color: Color(0xFFE0DDD9)),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Stats row + view toggle
                    Row(
                      children: [
                        Text(
                          _searchQuery.isNotEmpty
                              ? '${filtered.length} / ${provider.items.length} kitap'
                              : '${provider.items.length} kitap',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          'Toplam: ${provider.items.fold<int>(0, (sum, i) => sum + i.holding.quantity)} nüsha',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 30,
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE0DDD9)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _viewToggleButton(
                                icon: Icons.view_agenda_outlined,
                                mode: ViewMode.card,
                                isLeft: true,
                              ),
                              _viewToggleButton(
                                icon: Icons.view_list_outlined,
                                mode: ViewMode.compact,
                                isLeft: false,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: visible.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= visible.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    final item = visible[index];
                    if (_viewMode == ViewMode.compact) {
                      return _buildCompactItem(item, provider);
                    }
                    return _buildCardItem(item, provider);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBookBottomSheet,
        icon: const Icon(Icons.add),
        label: const Text('Kitap Ekle'),
      ),
    );
  }

  Widget _viewToggleButton({
    required IconData icon,
    required ViewMode mode,
    required bool isLeft,
  }) {
    final active = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: Container(
        width: 32,
        height: 30,
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.horizontal(
            left: isLeft ? const Radius.circular(5) : Radius.zero,
            right: !isLeft ? const Radius.circular(5) : Radius.zero,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? Colors.white : const Color(0xFF5A5A64),
        ),
      ),
    );
  }
}
