import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../providers/school_provider.dart';
import '../theme.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const WelcomeScreen({super.key, required this.onContinue});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _neverShowAgain = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _skip() async {
    if (_neverShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('skip_welcome', true);
    }
    widget.onContinue();
  }

  Future<void> _finish() async {
    if (_neverShowAgain) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('skip_welcome', true);
    }
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final school = context.read<SchoolProvider>().selectedSchool;
    final userName = auth.user?.fullName ?? '';
    final schoolName = school?.name ?? '';

    final pages = [
      // Page 1: Welcome
      _WelcomePage(
        userName: userName,
        schoolName: schoolName,
      ),
      // Page 2: Features
      const _FeaturesPage(),
      // Page 3: Get started
      _GetStartedPage(onStart: _finish),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: skip button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skip,
                    child: Text(
                      'Atla',
                      style: GoogleFonts.nunito(
                        color: MebColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: pages,
              ),
            ),
            // Dots + controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  final active = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: active ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: active
                          ? MebColors.primary
                          : MebColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            // "Don't show again" checkbox + next/finish
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _neverShowAgain = !_neverShowAgain),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            value: _neverShowAgain,
                            onChanged: (v) =>
                                setState(() => _neverShowAgain = v ?? false),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bir daha gösterme',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: MebColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_currentPage < pages.length - 1)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: const Text('Devam'),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _finish,
                        child: const Text('Başlayalım'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Page 1: Welcome ─────────────────────────────────

class _WelcomePage extends StatelessWidget {
  final String userName;
  final String schoolName;

  const _WelcomePage({required this.userName, required this.schoolName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/meb-logo-icon.png',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 28),
          Text(
            'Hoş Geldiniz!',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: MebColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            userName,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: MebColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: MebColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school_outlined,
                    color: MebColors.primary, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    schoolName,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: MebColors.primaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Kütüphane yönetim sistemine hoş geldiniz.\nOkulunuzun kitap envanterini buradan yönetebilirsiniz.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: MebColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page 2: Features ─────────────────────────────────

class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Neler Yapabilirsiniz?',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: MebColors.textPrimary,
            ),
          ),
          const SizedBox(height: 28),
          _FeatureRow(
            icon: Icons.qr_code_scanner,
            title: 'Barkod Tara',
            subtitle: 'ISBN barkodunu okutarak kitap ekleyin',
          ),
          _FeatureRow(
            icon: Icons.camera_alt_outlined,
            title: 'Kapak / Raf OCR',
            subtitle: 'Kitap kapağını veya raf sırtlarını fotoğraflayın',
          ),
          _FeatureRow(
            icon: Icons.table_chart_outlined,
            title: 'Excel ile Toplu Yükleme',
            subtitle: 'Mevcut listenizi Excel dosyasından aktarın',
          ),
          _FeatureRow(
            icon: Icons.edit_outlined,
            title: 'Manuel Giriş',
            subtitle: 'Kitap bilgilerini elle girin',
          ),
          _FeatureRow(
            icon: Icons.library_books_outlined,
            title: 'Envanter Yönetimi',
            subtitle: 'Nüsha sayılarını güncelleyin, düzenleyin',
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: MebColors.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: MebColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: MebColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: MebColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page 3: Get Started ──────────────────────────────

class _GetStartedPage extends StatelessWidget {
  final VoidCallback onStart;
  const _GetStartedPage({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: MebColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.rocket_launch_outlined,
                color: MebColors.primary, size: 36),
          ),
          const SizedBox(height: 28),
          Text(
            'Hazırsınız!',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: MebColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Kitap eklemek için ana ekrandaki + butonuna dokunun.\n\nBarkod tarama, kapak fotoğrafı veya manuel giriş ile kolayca kitap ekleyebilirsiniz.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: MebColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
