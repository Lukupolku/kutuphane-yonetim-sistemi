import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/book_provider.dart';
import '../providers/library_provider.dart';
import '../models/user_book.dart';
import '../theme.dart';
import '../widgets/book_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bookProv = context.watch<BookProvider>();
    final libProv = context.watch<LibraryProvider>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── App Bar ─────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Rafta',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: MebColors.textOnDark,
                  )),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [MebColors.sidebarDark, MebColors.primary, MebColors.accent],
                  ),
                ),
              ),
            ),
          ),

          // ─── Stats Row ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _StatCard(
                    icon: Icons.menu_book_rounded,
                    label: 'Toplam',
                    value: '${bookProv.totalBooks}',
                    color: MebColors.primary,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.auto_stories_rounded,
                    label: 'Okunuyor',
                    value: '${bookProv.currentlyReading.length}',
                    color: MebColors.accent,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.done_all_rounded,
                    label: 'Bu Yil',
                    value: '${bookProv.totalReadThisYear}',
                    color: MebColors.success,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Odunc',
                    value: '${bookProv.lentOut.length}',
                    color: MebColors.warning,
                  ),
                ],
              ),
            ),
          ),

          // ─── Quick Actions ───────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Barkod Tara',
                      onTap: () => Navigator.pushNamed(context, '/scan'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.search_rounded,
                      label: 'Kitap Ara',
                      onTap: () => Navigator.pushNamed(context, '/search'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.edit_note_rounded,
                      label: 'Manuel Ekle',
                      onTap: () => Navigator.pushNamed(context, '/add-manual'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Currently Reading ───────────────────────
          if (bookProv.currentlyReading.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text('Okumaya Devam Et',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: MebColors.textPrimary,
                    )),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: bookProv.currentlyReading.length,
                  itemBuilder: (context, i) {
                    final ub = bookProv.currentlyReading[i];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: BookCard(
                        userBook: ub,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/book-detail',
                          arguments: ub.userBook.id,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // ─── Recently Added ──────────────────────────
          if (bookProv.userBooks.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text('Son Eklenenler',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: MebColors.textPrimary,
                    )),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final ub = bookProv.userBooks[i];
                  return _BookListTile(
                    userBook: ub,
                    libraryProvider: libProv,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/book-detail',
                      arguments: ub.userBook.id,
                    ),
                  );
                },
                childCount: bookProv.userBooks.length.clamp(0, 10),
              ),
            ),
          ],

          // ─── Empty State ─────────────────────────────
          if (bookProv.userBooks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.library_books_outlined,
                        size: 64, color: MebColors.textTertiary),
                    const SizedBox(height: 16),
                    Text(
                      'Kitapliginiz bos',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: MebColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Barkod tarayarak veya arama yaparak\nilk kitabinizi ekleyin!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MebColors.textTertiary),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/scan'),
                      icon: const Icon(Icons.qr_code_scanner_rounded),
                      label: const Text('Barkod Tara'),
                    ),
                  ],
                ),
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(40)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                )),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withAlpha(180),
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MebColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: MebColors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: MebColors.primary, size: 26),
              const SizedBox(height: 6),
              Text(label,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: MebColors.textPrimary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookListTile extends StatelessWidget {
  final UserBookWithDetails userBook;
  final LibraryProvider libraryProvider;
  final VoidCallback onTap;

  const _BookListTile({
    required this.userBook,
    required this.libraryProvider,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final book = userBook.book;
    final ub = userBook.userBook;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: book.coverImageUrl != null
            ? Image.network(
                book.coverImageUrl!,
                width: 45,
                height: 65,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _CoverPlaceholder(title: book.title),
              )
            : _CoverPlaceholder(title: book.title),
      ),
      title: Text(book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w700, fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (book.authors.isNotEmpty)
            Text(book.authors.join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: MebColors.textSecondary)),
          Row(
            children: [
              _StatusBadge(status: ub.status),
              if (ub.rating != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade700),
                Text(' ${ub.rating!.toStringAsFixed(1)}',
                    style: TextStyle(fontSize: 11, color: Colors.amber.shade700)),
              ],
              if (userBook.activeLending != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.swap_horiz, size: 14, color: MebColors.warning),
              ],
            ],
          ),
        ],
      ),
      trailing: ub.isFavorite
          ? const Icon(Icons.favorite, size: 18, color: MebColors.primary)
          : null,
      onTap: onTap,
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final String title;
  const _CoverPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 45,
      height: 65,
      decoration: BoxDecoration(
        color: MebColors.primaryLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          title.isNotEmpty ? title[0].toUpperCase() : '?',
          style: GoogleFonts.outfit(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: MebColors.primary,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ReadingStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ReadingStatus.toRead => ('Okunacak', MebColors.textTertiary),
      ReadingStatus.reading => ('Okunuyor', MebColors.accent),
      ReadingStatus.read => ('Okundu', MebColors.success),
      ReadingStatus.dropped => ('Birakildi', MebColors.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
