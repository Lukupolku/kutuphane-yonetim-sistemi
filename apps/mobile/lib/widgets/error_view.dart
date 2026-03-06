import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// Reusable error view with icon, message, and retry action.
class ErrorView extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;
  final IconData icon;

  const ErrorView({
    super.key,
    this.title = 'Bir Hata Oluştu',
    this.message = 'Beklenmeyen bir hata meydana geldi. Lütfen tekrar deneyin.',
    this.onRetry,
    this.onGoHome,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: MebColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: MebColors.error),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: MebColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: MebColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            if (onRetry != null)
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tekrar Dene'),
                ),
              ),
            if (onGoHome != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: onGoHome,
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: const Text('Ana Sayfaya Dön'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: MebColors.textSecondary,
                    side: BorderSide(color: MebColors.textSecondary.withOpacity(0.3)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
