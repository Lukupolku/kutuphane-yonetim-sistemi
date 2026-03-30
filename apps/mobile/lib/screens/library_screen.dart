import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/library_provider.dart';
import '../providers/book_provider.dart';
import '../models/room.dart';
import '../models/bookshelf.dart';
import '../theme.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final libProv = context.watch<LibraryProvider>();
    final rooms = libProv.rooms;

    return Scaffold(
      appBar: AppBar(title: const Text('Kitapligim')),
      body: rooms.isEmpty
          ? _EmptyRooms(onAdd: () => _showAddRoomDialog(context, libProv))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rooms.length,
              itemBuilder: (context, i) =>
                  _RoomCard(room: rooms[i], libProv: libProv),
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addRoom',
        onPressed: () => _showAddRoomDialog(context, libProv),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showAddRoomDialog(BuildContext context, LibraryProvider prov) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Yeni Oda', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ornek: Salon, Calisma Odasi...',
            prefixIcon: Icon(Icons.room_outlined),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                prov.addRoom(name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}

class _EmptyRooms extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyRooms({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_outlined, size: 64, color: MebColors.textTertiary),
          const SizedBox(height: 16),
          Text('Henuz bir oda eklemediniz',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: MebColors.textSecondary,
              )),
          const SizedBox(height: 8),
          Text('Kitapliklarinizi odalara gore duzenleyin',
              style: TextStyle(color: MebColors.textTertiary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Oda Ekle'),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final LibraryProvider libProv;

  const _RoomCard({required this.room, required this.libProv});

  @override
  Widget build(BuildContext context) {
    final bookshelves = libProv.bookshelvesForRoom(room.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: MebColors.primaryLight,
          child: Icon(_roomIcon(room.icon), color: MebColors.primary, size: 22),
        ),
        title: Text(room.name,
            style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        subtitle: Text('${bookshelves.length} kitaplik',
            style: const TextStyle(fontSize: 12, color: MebColors.textTertiary)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_rounded, size: 20),
              tooltip: 'Kitaplik Ekle',
              onPressed: () => _showAddBookshelfDialog(context, room.id),
            ),
            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'edit') _showEditRoomDialog(context, room);
                if (val == 'delete') _confirmDeleteRoom(context, room);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Duzenle')),
                const PopupMenuItem(value: 'delete', child: Text('Sil')),
              ],
            ),
          ],
        ),
        children: bookshelves.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Bu odada kitaplik yok',
                      style: TextStyle(
                          color: MebColors.textTertiary, fontSize: 13)),
                ),
              ]
            : bookshelves.map((bs) => _BookshelfTile(bookshelf: bs, libProv: libProv)).toList(),
      ),
    );
  }

  IconData _roomIcon(String? icon) {
    switch (icon) {
      case 'bedroom':
        return Icons.bed_outlined;
      case 'study':
        return Icons.desk_outlined;
      case 'kids':
        return Icons.child_care_outlined;
      case 'living':
        return Icons.weekend_outlined;
      default:
        return Icons.room_outlined;
    }
  }

  void _showAddBookshelfDialog(BuildContext context, String roomId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Yeni Kitaplik', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ornek: Buyuk Kitaplik, Duvar Rafi...',
            prefixIcon: Icon(Icons.shelves),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                libProv.addBookshelf(roomId, name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  void _showEditRoomDialog(BuildContext context, Room room) {
    final controller = TextEditingController(text: room.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Oda Duzenle', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                libProv.updateRoom(room.copyWith(name: name));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteRoom(BuildContext context, Room room) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Oda Sil'),
        content: Text('"${room.name}" odasini ve icerisindeki tum kitapliklari silmek istediginize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: MebColors.error),
            onPressed: () {
              libProv.deleteRoom(room.id);
              Navigator.pop(ctx);
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}

class _BookshelfTile extends StatelessWidget {
  final Bookshelf bookshelf;
  final LibraryProvider libProv;

  const _BookshelfTile({required this.bookshelf, required this.libProv});

  @override
  Widget build(BuildContext context) {
    final shelves = libProv.shelvesForBookshelf(bookshelf.id);
    final bookProv = context.read<BookProvider>();

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: ExpansionTile(
        leading: const Icon(Icons.shelves, size: 20, color: MebColors.accent),
        title: Text(bookshelf.name,
            style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
        subtitle: Text('${shelves.length} raf',
            style: const TextStyle(fontSize: 11, color: MebColors.textTertiary)),
        trailing: IconButton(
          icon: const Icon(Icons.add_rounded, size: 18),
          tooltip: 'Raf Ekle',
          onPressed: () => _showAddShelfDialog(context, bookshelf.id),
        ),
        children: shelves.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text('Raf yok',
                      style: TextStyle(color: MebColors.textTertiary, fontSize: 12)),
                ),
              ]
            : shelves.map((shelf) {
                final books = bookProv.booksOnShelf(shelf.id);
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.only(left: 32, right: 16),
                  leading: const Icon(Icons.view_agenda_outlined,
                      size: 18, color: MebColors.textTertiary),
                  title: Text(shelf.name,
                      style: GoogleFonts.nunito(fontSize: 13, fontWeight: FontWeight.w600)),
                  trailing: Text('${books.length} kitap',
                      style: const TextStyle(fontSize: 11, color: MebColors.textTertiary)),
                  onTap: () => Navigator.pushNamed(context, '/shelf-detail',
                      arguments: shelf.id),
                );
              }).toList(),
      ),
    );
  }

  void _showAddShelfDialog(BuildContext context, String bookshelfId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Yeni Raf', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Ornek: Ust Raf, Raf 1...',
            prefixIcon: Icon(Icons.view_agenda_outlined),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                libProv.addShelf(bookshelfId, name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }
}
