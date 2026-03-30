import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;
  final IconData icon;

  const ErrorView({
    super.key,
    this.title = 'Bir Hata Olustu',
    this.message = 'Beklenmeyen bir hata meydana geldi. Lutfen tekrar deneyin.',
    this.onRetry,
    this.onGoHome,
    this.icon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: MebColors.error.withAlpha(25),
              child: Icon(icon, size: 36, color: MebColors.error),
            ),
            const SizedBox(height: 20),
            Text(title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: MebColors.textPrimary,
                )),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: MebColors.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            if (onGoHome != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onGoHome,
                icon: const Icon(Icons.home_outlined),
                label: const Text('Ana Sayfaya Don'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
