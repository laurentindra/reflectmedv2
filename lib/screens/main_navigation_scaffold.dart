import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme/app_theme.dart';
import 'home_dashboard_screen.dart';
import 'reflective_chat_screen.dart';
import 'gibbs_form_screen.dart';
import 'progress_analytics_screen.dart';
import 'eportfolio_sync_screen.dart';

class MainNavigationScaffold extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScaffold({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  late int _currentIndex;
  int _navVersion = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _navVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(key: ValueKey('home_$_navVersion')),
      const ReflectiveChatScreen(), // Mempertahankan riwayat aktif dan animasi avatar
      GibbsFormScreen(key: ValueKey('form_$_navVersion')),
      ProgressAnalyticsScreen(key: ValueKey('analytics_$_navVersion')),
      EPortfolioSyncScreen(key: ValueKey('portfolio_$_navVersion')),
    ];

    return Scaffold(
      backgroundColor: AppTheme.parchmentBg,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        height: 74,
        decoration: const BoxDecoration(
          color: AppTheme.surfaceWarm,
          border: Border(
            top: BorderSide(color: Color(0xFFE5DDD1), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tab 0: BERANDA
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              label: 'BERANDA',
            ),

            // Tab 1: AI
            _buildNavItem(
              index: 1,
              icon: Icons.chat_bubble_outline_rounded,
              activeIcon: Icons.chat_bubble_rounded,
              label: 'AI',
            ),

            // Tab 2: REFLEKSI (Center Raised Deep Teal Squircle Button)
            GestureDetector(
              onTap: () => _onTabTapped(2),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryTeal,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryTeal.withValues(alpha: 0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.draw_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'REFLEKSI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppTheme.primaryTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tab 3: PROGRES
            _buildNavItem(
              index: 3,
              icon: Icons.show_chart_rounded,
              activeIcon: Icons.show_chart_rounded,
              label: 'PROGRES',
            ),

            // Tab 4: ARSIP
            _buildNavItem(
              index: 4,
              icon: Icons.folder_outlined,
              activeIcon: Icons.folder_rounded,
              label: 'ARSIP',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;
    final color = isActive ? AppTheme.textInk : AppTheme.textLight;

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: color,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.8,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            // Active dot indicator
            Container(
              width: 3.5,
              height: 3.5,
              decoration: BoxDecoration(
                color: isActive ? AppTheme.textInk : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
