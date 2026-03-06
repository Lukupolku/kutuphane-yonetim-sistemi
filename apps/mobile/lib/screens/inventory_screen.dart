import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../providers/inventory_provider.dart';
import '../providers/school_provider.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
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
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Kitap Düzenle'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Başlık',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Zorunlu' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: authorsController,
                    decoration: const InputDecoration(
                      labelText: 'Yazar',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: publisherController,
                    decoration: const InputDecoration(
                      labelText: 'Yayınevi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final authors = authorsController.text
                    .split(',')
                    .map((a) => a.trim())
                    .where((a) => a.isNotEmpty)
                    .toList();
                final updatedBook = Book(
                  id: item.book.id,
                  isbn: item.book.isbn,
                  title: titleController.text.trim(),
                  authors: authors.isEmpty ? ['Bilinmiyor'] : authors,
                  publisher: publisherController.text.trim().isNotEmpty
                      ? publisherController.text.trim()
                      : null,
                  publishedDate: item.book.publishedDate,
                  pageCount: item.book.pageCount,
                  coverImageUrl: item.book.coverImageUrl,
                  language: item.book.language,
                  source: item.book.source,
                  createdAt: item.book.createdAt,
                );
                context.read<InventoryProvider>().updateBook(updatedBook);
                Navigator.pop(context);
              },
              child: const Text('Kaydet'),
            ),
          ],
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
                backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    final schoolProvider = context.watch<SchoolProvider>();
    final schoolName = schoolProvider.selectedSchool?.name ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(schoolName),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/school-selection');
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
                  Icon(Icons.library_books, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz kitap eklenmemiş',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kitap eklemek için + butonuna dokunun',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Row(
                  children: [
                    Text(
                      '${provider.items.length} kitap',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const Spacer(),
                    Text(
                      'Toplam: ${provider.items.fold<int>(0, (sum, i) => sum + i.holding.quantity)} adet',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: provider.items.length,
                  itemBuilder: (context, index) {
                    final item = provider.items[index];
                    return Dismissible(
                      key: Key(item.holding.id),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        _confirmDelete(item);
                        return false;
                      },
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child:
                            const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        child: InkWell(
                          onTap: () => _showEditBookDialog(item),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Book icon or cover
                                Container(
                                  width: 44,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: item.book.coverImageUrl != null
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          child: Image.network(
                                            item.book.coverImageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (_, __, ___) => Icon(
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
                                // Book info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (item.book.publisher != null)
                                        Text(
                                          item.book.publisher!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Quantity controls
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
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
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
}
