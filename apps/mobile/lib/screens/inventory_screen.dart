import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/scan/barcode');
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Kapak Fotografla'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/scan/cover');
                },
              ),
              ListTile(
                leading: const Icon(Icons.shelves),
                title: const Text('Raf Fotografla'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/scan/shelf');
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Manuel Giris'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/book/confirm');
                },
              ),
            ],
          ),
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
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (provider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.library_books,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henuz kitap eklenmemis',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kitap eklemek icin + butonuna dokunun',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final item = provider.items[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: ListTile(
                  leading: const Icon(Icons.book),
                  title: Text(item.book.title),
                  subtitle: Text(item.book.authors.join(', ')),
                  trailing: Chip(
                    label: Text('${item.holding.quantity}'),
                  ),
                ),
              );
            },
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
