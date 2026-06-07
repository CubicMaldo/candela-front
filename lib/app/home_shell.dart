import 'package:flutter/material.dart';
import '../theme.dart';
import 'feed_screen.dart';
import 'rankings_screen.dart';
import 'friends_screen.dart';
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
  int _index = 0;

  final _screens = const [
    FeedScreen(),
    RankingsScreen(),
    FriendsScreen(),
    MyProfileScreen(),
  ];

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
      body: IndexedStack(index: _index, children: _screens),
      floatingActionButton: _CheckInFab(onTap: _openCheckIn),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
      ),
    );
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
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kRed, kGreen],
          ),
          boxShadow: [
            BoxShadow(
              color: kRed.withValues(alpha: 0.40),
              blurRadius: 20,
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
              _Item(icon: Icons.leaderboard_rounded, label: 'Ranks', i: 1, index: index, onChanged: onChanged),
              const Spacer(flex: 1), // space for the FAB
              _Item(icon: Icons.group_rounded, label: 'Friends', i: 2, index: index, onChanged: onChanged),
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
