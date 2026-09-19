import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import 'checkin_screen.dart';
import 'map/map_screen.dart';
import 'feed_screen.dart';
import 'plans_screen.dart';
import 'profile_screen.dart';
import 'widgets.dart' show SlideRightRoute;

/// Root of the authenticated app — a 4-tab bottom bar (Map, Feed, Plans,
/// Profile) plus a floating check-in button that stays visible above the bar
/// on every tab.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Broadcasts the active tab so tabs kept alive in the IndexedStack (e.g. the
  // map) can refresh their live data when they become visible again.
  final _tabIndex = ValueNotifier<int>(0);

  late final List<Widget> _tabs = [
    MapScreen(activeTab: _tabIndex),
    const FeedScreen(),
    const PlansScreen(),
    const MyProfileScreen(),
  ];

  @override
  void dispose() {
    _tabIndex.dispose();
    super.dispose();
  }

  void _openCheckIn() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      SlideRightRoute(builder: (_) => const CheckInScreen()),
    );
  }

  void _onTab(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
    _tabIndex.value = i;
  }

  @override
  Widget build(BuildContext context) {
    // extendBody lets the active tab scroll *behind* the frosted nav bar — the
    // iOS hallmark of depth and translucency.
    return PopScope(
      // Android back on a secondary tab returns to the map (the app's home)
      // instead of closing the app; on the map it exits as usual.
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onTab(0);
      },
      child: Scaffold(
        extendBody: true,
        // A cross-fade is layered over the IndexedStack (which keeps each tab's
        // state and avoids re-fetching on every switch).
        body: TweenAnimationBuilder<double>(
          key: ValueKey(_index),
          tween: Tween(begin: 0.65, end: 1),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          builder: (context, opacity, child) =>
              Opacity(opacity: opacity, child: child),
          child: IndexedStack(index: _index, children: _tabs),
        ),
        // The FAB lives in the Scaffold slot so it paints *above* the frosted bar
        // (in the body Stack it was hidden behind it). centerDocked raises it onto
        // the bar's top edge.
        floatingActionButton: _CheckInFab(onTap: _openCheckIn),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _NavBar(index: _index, onChanged: _onTab),
      ),
    );
  }
}

// ─── Floating check-in button ────────────────────────────────────────────────
class _CheckInFab extends StatefulWidget {
  final VoidCallback onTap;
  const _CheckInFab({required this.onTap});

  @override
  State<_CheckInFab> createState() => _CheckInFabState();
}

class _CheckInFabState extends State<_CheckInFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Hacer check-in',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: candelaAmber,
              boxShadow: [
                BoxShadow(
                  color: candelaAmber.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(child: _FlameIcon(size: 28)),
          ),
        ),
      ),
    );
  }
}

/// Candela's check-in icon — a stylised flame, drawn as a vector path so it
/// renders crisply at any size without bundling an SVG asset.
class _FlameIcon extends StatelessWidget {
  final double size;
  const _FlameIcon({this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _FlamePainter()),
    );
  }
}

class _FlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.50, h * 0.02)
      ..cubicTo(w * 0.30, h * 0.32, w * 0.18, h * 0.46, w * 0.18, h * 0.66)
      ..cubicTo(w * 0.18, h * 0.90, w * 0.34, h * 1.02, w * 0.50, h * 1.02)
      ..cubicTo(w * 0.66, h * 1.02, w * 0.82, h * 0.90, w * 0.82, h * 0.66)
      ..cubicTo(w * 0.82, h * 0.54, w * 0.76, h * 0.45, w * 0.68, h * 0.40)
      ..cubicTo(w * 0.70, h * 0.54, w * 0.62, h * 0.62, w * 0.54, h * 0.62)
      ..cubicTo(w * 0.46, h * 0.62, w * 0.40, h * 0.55, w * 0.42, h * 0.44)
      ..cubicTo(w * 0.44, h * 0.32, w * 0.50, h * 0.20, w * 0.50, h * 0.02)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_FlamePainter oldDelegate) => false;
}

// ─── Bottom navigation bar ───────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _NavBar({required this.index, required this.onChanged});

  static const _outlined = [
    Icons.map_outlined,
    Icons.image_outlined,
    Icons.calendar_today_outlined,
    Icons.person_outline_rounded,
  ];

  static const _filled = [
    Icons.map_rounded,
    Icons.image_rounded,
    Icons.calendar_today_rounded,
    Icons.person_rounded,
  ];

  static const _labels = ['Mapa', 'Feed', 'Planes', 'Perfil'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark ? candelaNight : Colors.white;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            // Translucent so the content shows faintly through the frost.
            color: background.withValues(alpha: 0.82),
            border: Border(
              top: BorderSide(
                color: borderInactive.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: kNavBarHeight,
              child: Row(
                children: [
                  _tab(context, 0),
                  _tab(context, 1),
                  // Clearance under the docked check-in FAB so no tab's hit
                  // area hides beneath it.
                  const SizedBox(width: 72),
                  _tab(context, 2),
                  _tab(context, 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int i) {
    final active = i == index;
    final color = active ? candelaAmber : secondaryOn(context);
    return Expanded(
      child: Semantics(
        button: true,
        selected: active,
        label: _labels[i],
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(i),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(active ? _filled[i] : _outlined[i], size: 24, color: color),
              const SizedBox(height: 3),
              Text(
                _labels[i],
                style: jakartaSans(
                  size: 10.5,
                  weight: active ? FontWeight.w700 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
