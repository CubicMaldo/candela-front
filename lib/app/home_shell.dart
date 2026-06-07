import 'package:flutter/material.dart';
import '../theme.dart';
import 'feed_screen.dart';
import 'map_screen.dart';
import 'rankings_screen.dart';
import 'profile_screen.dart';
import 'checkin_screen.dart';

/// Root of the authenticated app: a five-slot bottom bar with a raised central
/// check-in action, matching the Lokal design language.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _controller = PageController();
  int _index = 0;

  final _screens = const [
    FeedScreen(),
    MapScreen(),
    RankingsScreen(),
    MyProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onPageScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_onPageScroll);
    _controller.dispose();
    super.dispose();
  }

  // Highlight the bottom-bar item as soon as the swipe crosses the halfway
  // point, so the indicator tracks the gesture instead of snapping at the end.
  void _onPageScroll() {
    final page = _controller.page;
    if (page == null) return;
    final rounded = page.round();
    if (rounded != _index) setState(() => _index = rounded);
  }

  void _goToTab(int i) {
    if (i == _index) return;
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
    );
  }

  void _openCheckIn() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckInScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: PageView(
        controller: _controller,
        // Page snapping + iOS-style overscroll bounce for a premium feel.
        physics: const BouncingScrollPhysics(),
        children: [
          for (final screen in _screens) _KeepAlivePage(child: screen),
        ],
      ),
      floatingActionButton: _CheckInFab(onTap: _openCheckIn),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        index: _index,
        onChanged: _goToTab,
      ),
    );
  }
}

// Keeps each tab's state alive while swiping between pages (so feeds, scroll
// offsets and fetched data survive when a page scrolls out of the viewport).
class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// ─── Raised central check-in button ───────────────────────────────────────────
class _CheckInFab extends StatelessWidget {
  final VoidCallback onTap;
  const _CheckInFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: kRed,
          boxShadow: [
            BoxShadow(
              color: kRed.withValues(alpha: 0.40),
              blurRadius: 10,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: const Icon(Icons.add_a_photo_rounded, color: Colors.white, size: 26),
      ),
    );
  }
}

// ─── Bottom navigation bar ────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _BottomBar({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: kBg,
        border: Border(top: BorderSide(color: kBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _Item(icon: Icons.dynamic_feed_rounded, label: 'Feed', i: 0, index: index, onChanged: onChanged),
              _Item(icon: Icons.map_rounded, label: 'Map', i: 1, index: index, onChanged: onChanged),
              const Spacer(flex: 1), // space for the FAB
              _Item(icon: Icons.leaderboard_rounded, label: 'Ranks', i: 2, index: index, onChanged: onChanged),
              _Item(icon: Icons.person_rounded, label: 'Profile', i: 3, index: index, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final int i;
  final int index;
  final ValueChanged<int> onChanged;

  const _Item({
    required this.icon,
    required this.label,
    required this.i,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final on = i == index;
    final color = on ? kRed : kMuted;
    return Expanded(
      flex: 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: jakartaSans(
                size: 11,
                weight: on ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
