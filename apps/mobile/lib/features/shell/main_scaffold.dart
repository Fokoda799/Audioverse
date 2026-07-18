import 'package:Audioverse/features/content/widgets/mini_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:Audioverse/core/theme/theme.dart';

// Main Scaffold
//
// The persistent shell around all 4 bottom-nav tabs: Home, Search,
// Library, Profile. This widget itself never rebuilds when switching
// tabs — go_router's StatefulShellRoute keeps each tab's navigation
// stack and scroll position alive in the background, which is exactly
// what a Larq-Player-style app needs (e.g. you don't want the home
// feed's scroll position to reset every time you check Search and
// come back).
//
// This file ONLY owns the bottom nav bar UI. Each tab's actual screen
// (HomeScreen, SearchScreen, etc.) is a separate file/route.
//
// main_scaffold.dart

class MainScaffold extends StatelessWidget {
  const MainScaffold({super.key, required this.navigationShell});

  // Provided by go_router's StatefulShellRoute.indexedStack builder.
  // Represents the currently active tab's navigator.
  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _NavTab(icon: Icons.home_rounded, outlineIcon: Icons.home_outlined, label: 'Home'),
    _NavTab(icon: Icons.search_rounded, outlineIcon: Icons.search_outlined, label: 'Search'),
    _NavTab(icon: Icons.library_music_rounded, outlineIcon: Icons.library_music_outlined, label: 'Library'),
    _NavTab(icon: Icons.person_rounded, outlineIcon: Icons.person_outline_rounded, label: 'Profile'),
  ];

  void _onTap(int index) {
    // goBranch with initialLocation: true resets that tab's stack to its
    // root if the user taps the SAME tab they're already on — standard
    // "tap Home again to scroll to top / reset" behavior.
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      backgroundColor: AppColors.darkBackground,
      // The active tab's screen — go_router swaps this via IndexedStack
      // under the hood, so inactive tabs stay mounted (preserving state).
      body: navigationShell,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          _BottomNavBar(
            currentIndex: navigationShell.currentIndex,
            tabs: _tabs,
            onTap: _onTap,
          ),
        ],
      ),
    );

    if (kIsWeb) return scaffold;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      child: scaffold,
    );
  }
}

class _NavTab {
  const _NavTab({required this.icon, required this.outlineIcon, required this.label});
  final IconData icon;
  final IconData outlineIcon;
  final String label;
}

// ── Bottom Nav Bar ────────────────────────────────────────────────────────
//
// Custom-built rather than a stock BottomNavigationBar — gives us the
// frosted/elevated dark-surface look consistent with AppCard, plus a
// pill-shaped active-tab indicator (the Larq Player signature touch)
// instead of Material's default label-under-icon style.
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({
    required this.currentIndex,
    required this.tabs,
    required this.onTap,
  });

  final int currentIndex;
  final List<_NavTab> tabs;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(
          top: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.6)),
        ),
        boxShadow: AppShadows.cardDark,
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(tabs.length, (index) {
              final isActive = index == currentIndex;
              final tab = tabs[index];

              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      key: ValueKey(isActive),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Pill background appears only behind the active icon —
                        // this is the signature touch that reads as "Larq Player"
                        // rather than generic Material bottom nav.
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary.withValues(alpha: 0.16)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Icon(
                            isActive ? tab.icon : tab.outlineIcon,
                            size: 24,
                            color: isActive
                                ? AppColors.primaryLight
                                : AppColors.textSecondaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tab.label,
                          style: AppTextStyles.labelSmall(
                            isActive
                                ? AppColors.primaryLight
                                : AppColors.textSecondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
