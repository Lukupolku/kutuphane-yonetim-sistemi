import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/book_provider.dart';
import '../theme.dart';

class BookCard extends StatelessWidget {
  final UserBookWithDetails userBook;
  final VoidCallback? onTap;

  const BookCard({super.key, required this.userBook, this.onTap});

  @override
  Widget build(BuildContext context) {
    final book = userBook.book;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: book.coverImageUrl != null
                  ? Image.network(
                      book.coverImageUrl!,
                      width: 130,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _CoverPlaceholder(title: book.title),
                    )
                  : _CoverPlaceholder(title: book.title),
            ),
            const SizedBox(height: 6),
            // Title
            Text(book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                )),
            // Author
            if (book.authors.isNotEmpty)
              Text(book.authors.first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: MebColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  final String title;
  const _CoverPlaceholder({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MebColors.primaryLight, MebColors.primary.withAlpha(40)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MebColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
