import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/book_provider.dart';
import '../providers/library_provider.dart';
import '../models/user_book.dart';
import '../models/book_note.dart';
import '../theme.dart';
import '../widgets/rating_widget.dart';

class BookDetailScreen extends StatelessWidget {
  const BookDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userBookId = ModalRoute.of(context)!.settings.arguments as String;
    final bookProv = context.watch<BookProvider>();
    final libProv = context.watch<LibraryProvider>();

    final ubDetail = bookProv.userBooks
        .where((ub) => ub.userBook.id == userBookId)
        .firstOrNull;

    if (ubDetail == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Kitap bulunamadi')),
      );
    }

    final book = ubDetail.book;
    final ub = ubDetail.userBook;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── Cover + Title ───────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: MebColors.textOnDark,
                  )),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [MebColors.sidebarDark, MebColors.primary, MebColors.accent],
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 40, bottom: 60),
                    child: book.coverImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              book.coverImageUrl!,
                              height: 160,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _CoverPlaceholderLarge(title: book.title),
                            ),
                          )
                        : _CoverPlaceholderLarge(title: book.title),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(ub.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: ub.isFavorite ? Colors.red.shade300 : Colors.white),
                onPressed: () => bookProv.updateUserBook(
                    ub.copyWith(isFavorite: !ub.isFavorite)),
              ),
              PopupMenuButton<String>(
                onSelected: (val) {
                  if (val == 'delete') _confirmDelete(context, bookProv, ub.id);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'delete', child: Text('Kitabi Kaldir')),
                ],
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Authors ─────────────────────────
                  if (book.authors.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(book.authors.join(', '),
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: MebColors.textSecondary,
                          )),
                    ),

                  // ─── Meta Info Chips ─────────────────
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (book.publisher != null) _Chip(icon: Icons.business, label: book.publisher!),
                      if (book.publishedDate != null) _Chip(icon: Icons.calendar_today, label: book.publishedDate!),
                      if (book.pageCount != null) _Chip(icon: Icons.auto_stories, label: '${book.pageCount} sayfa'),
                      if (book.isbn != null) _Chip(icon: Icons.qr_code, label: book.isbn!),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // ─── Rating ──────────────────────────
                  _Section(
                    title: 'Puanlama',
                    child: RatingWidget(
                      rating: ub.rating ?? 0,
                      onChanged: (val) => bookProv.updateUserBook(ub.copyWith(rating: val)),
                    ),
                  ),

                  // ─── Status ──────────────────────────
                  _Section(
                    title: 'Okuma Durumu',
                    child: SegmentedButton<ReadingStatus>(
                      segments: const [
                        ButtonSegment(value: ReadingStatus.toRead, label: Text('Okunacak'), icon: Icon(Icons.bookmark_border, size: 16)),
                        ButtonSegment(value: ReadingStatus.reading, label: Text('Okunuyor'), icon: Icon(Icons.auto_stories, size: 16)),
                        ButtonSegment(value: ReadingStatus.read, label: Text('Okundu'), icon: Icon(Icons.done, size: 16)),
                        ButtonSegment(value: ReadingStatus.dropped, label: Text('Birakildi'), icon: Icon(Icons.close, size: 16)),
                      ],
                      selected: {ub.status},
                      onSelectionChanged: (set) {
                        final newStatus = set.first;
                        var updated = ub.copyWith(status: newStatus);
                        if (newStatus == ReadingStatus.reading && ub.startDate == null) {
                          updated = updated.copyWith(startDate: DateTime.now());
                        }
                        if (newStatus == ReadingStatus.read && ub.finishDate == null) {
                          updated = updated.copyWith(finishDate: DateTime.now());
                        }
                        bookProv.updateUserBook(updated);
                      },
                      style: ButtonStyle(
                        textStyle: WidgetStateProperty.all(
                            const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),

                  // ─── Location ────────────────────────
                  _Section(
                    title: 'Konum',
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 18, color: MebColors.textTertiary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ub.shelfId != null
                                ? libProv.shelfPath(ub.shelfId!)
                                : 'Raf atanmadi',
                            style: TextStyle(
                              color: ub.shelfId != null ? MebColors.textPrimary : MebColors.textTertiary,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showShelfPicker(context, bookProv, libProv, ub),
                          child: Text(ub.shelfId != null ? 'Degistir' : 'Ata'),
                        ),
                      ],
                    ),
                  ),

                  // ─── Lending ─────────────────────────
                  _Section(
                    title: 'Odunc Durumu',
                    child: ubDetail.activeLending != null
                        ? Row(
                            children: [
                              Icon(Icons.swap_horiz, color: MebColors.warning, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(ubDetail.activeLending!.borrowerName,
                                        style: const TextStyle(fontWeight: FontWeight.w700)),
                                    if (ubDetail.activeLending!.isOverdue)
                                      Text('Gecikti!', style: TextStyle(color: MebColors.error, fontSize: 12)),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () => bookProv.returnBook(ubDetail.activeLending!.id),
                                child: const Text('Iade Edildi'),
                              ),
                            ],
                          )
                        : OutlinedButton.icon(
                            onPressed: () => _showLendDialog(context, bookProv, ub.id),
                            icon: const Icon(Icons.swap_horiz, size: 18),
                            label: const Text('Odunc Ver'),
                          ),
                  ),

                  // ─── Description ─────────────────────
                  if (book.description != null && book.description!.isNotEmpty)
                    _Section(
                      title: 'Aciklama',
                      child: Text(book.description!,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: MebColors.textSecondary,
                          )),
                    ),

                  // ─── Notes ───────────────────────────
                  _Section(
                    title: 'Notlar (${ubDetail.notes.length})',
                    trailing: IconButton(
                      icon: const Icon(Icons.add_rounded, size: 20),
                      onPressed: () => _showAddNoteDialog(context, bookProv, ub.id),
                    ),
                    child: ubDetail.notes.isEmpty
                        ? Text('Henuz not eklenmedi',
                            style: TextStyle(color: MebColors.textTertiary, fontSize: 13))
                        : Column(
                            children: ubDetail.notes.take(5).map((note) => _NoteTile(note: note, bookProv: bookProv)).toList(),
                          ),
                  ),

                  // ─── Personal Notes ──────────────────
                  _Section(
                    title: 'Kisisel Not',
                    child: InkWell(
                      onTap: () => _showPersonalNoteEditor(context, bookProv, ub),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: MebColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: MebColors.border),
                        ),
                        child: Text(
                          ub.personalNotes?.isNotEmpty == true
                              ? ub.personalNotes!
                              : 'Dokunarak not ekleyin...',
                          style: TextStyle(
                            color: ub.personalNotes?.isNotEmpty == true
                                ? MebColors.textPrimary
                                : MebColors.textTertiary,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'addNote',
        onPressed: () => Navigator.pushNamed(context, '/note-capture', arguments: ub.id),
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Sayfa Fotola'),
      ),
    );
  }

  void _confirmDelete(BuildContext context, BookProvider prov, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kitabi Kaldir'),
        content: const Text('Bu kitabi kitapliginizdan kaldirmak istediginize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: MebColors.error),
            onPressed: () {
              prov.removeUserBook(id);
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Kaldir'),
          ),
        ],
      ),
    );
  }

  void _showShelfPicker(BuildContext context, BookProvider bookProv,
      LibraryProvider libProv, UserBook ub) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Raf Sec', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...libProv.rooms.expand((room) {
              return libProv.bookshelvesForRoom(room.id).expand((bs) {
                return libProv.shelvesForBookshelf(bs.id).map((shelf) {
                  final path = '${room.name} > ${bs.name} > ${shelf.name}';
                  return ListTile(
                    leading: const Icon(Icons.view_agenda_outlined, size: 18),
                    title: Text(path, style: const TextStyle(fontSize: 13)),
                    selected: ub.shelfId == shelf.id,
                    onTap: () {
                      bookProv.updateUserBook(ub.copyWith(shelfId: shelf.id));
                      Navigator.pop(ctx);
                    },
                  );
                });
              });
            }),
            if (ub.shelfId != null)
              ListTile(
                leading: const Icon(Icons.clear, size: 18, color: MebColors.error),
                title: const Text('Raftan Kaldir', style: TextStyle(color: MebColors.error)),
                onTap: () {
                  // Pass empty string then handle in provider — or we handle nullable
                  bookProv.updateUserBook(UserBook(
                    id: ub.id,
                    bookId: ub.bookId,
                    shelfId: null,
                    status: ub.status,
                    rating: ub.rating,
                    isFavorite: ub.isFavorite,
                    startDate: ub.startDate,
                    finishDate: ub.finishDate,
                    personalNotes: ub.personalNotes,
                    createdAt: ub.createdAt,
                    updatedAt: DateTime.now(),
                  ));
                  Navigator.pop(ctx);
                },
              ),
          ],
        );
      },
    );
  }

  void _showLendDialog(BuildContext context, BookProvider prov, String userBookId) {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Odunc Ver', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Kime',
                hintText: 'Adi Soyadi',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contactCtrl,
              decoration: const InputDecoration(
                labelText: 'Iletisim (opsiyonel)',
                hintText: 'Telefon veya e-posta',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                prov.lendBook(userBookId,
                    borrowerName: name,
                    contact: contactCtrl.text.trim().isNotEmpty ? contactCtrl.text.trim() : null);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Odunc Ver'),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, BookProvider prov, String userBookId) {
    final contentCtrl = TextEditingController();
    final pageCtrl = TextEditingController();
    NoteType selectedType = NoteType.note;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Not Ekle', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<NoteType>(
                segments: const [
                  ButtonSegment(value: NoteType.note, label: Text('Not')),
                  ButtonSegment(value: NoteType.highlight, label: Text('Alti Cizili')),
                  ButtonSegment(value: NoteType.quote, label: Text('Alinti')),
                ],
                selected: {selectedType},
                onSelectionChanged: (set) => setState(() => selectedType = set.first),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pageCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Sayfa No (opsiyonel)',
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Icerik',
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
            ElevatedButton(
              onPressed: () {
                final content = contentCtrl.text.trim();
                if (content.isNotEmpty) {
                  prov.addNote(
                    userBookId,
                    content: content,
                    pageNumber: int.tryParse(pageCtrl.text),
                    type: selectedType,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPersonalNoteEditor(BuildContext context, BookProvider prov, UserBook ub) {
    final ctrl = TextEditingController(text: ub.personalNotes ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kisisel Not', style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          decoration: const InputDecoration(hintText: 'Bu kitap hakkindaki dusunceleriniz...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Iptal')),
          ElevatedButton(
            onPressed: () {
              prov.updateUserBook(ub.copyWith(personalNotes: ctrl.text.trim()));
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Section({required this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: MebColors.textPrimary,
                  )),
              const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: MebColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: MebColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: MebColors.textTertiary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: MebColors.textSecondary)),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final BookNote note;
  final BookProvider bookProv;
  const _NoteTile({required this.note, required this.bookProv});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (note.type) {
      NoteType.highlight => (Icons.highlight, Colors.amber),
      NoteType.note => (Icons.note_outlined, MebColors.accent),
      NoteType.quote => (Icons.format_quote, MebColors.primary),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (note.pageNumber != null)
                  Text('s. ${note.pageNumber}',
                      style: TextStyle(fontSize: 11, color: MebColors.textTertiary)),
                Text(note.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverPlaceholderLarge extends StatelessWidget {
  final String title;
  const _CoverPlaceholderLarge({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(Icons.menu_book_rounded, size: 48, color: Colors.white.withAlpha(120)),
      ),
    );
  }
}
