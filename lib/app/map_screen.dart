import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import 'widgets.dart';
import 'place_sheet.dart';

/// Discovery map — the explore surface. A stylized, pannable map of the city with
/// place pins (visited = green, new = red), friends nearby, activity heat zones,
/// a search affordance, live "exploring" count and category filters. Tapping a
/// pin opens the place check-in sheet.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late Future<List<Place>> _places;
  final _categories = const ['All', 'Food', 'Cafés', 'Art', 'Nightlife'];
  String _category = 'All';

  // Fixed map placement + state per pin, paired to fetched places by index.
  static const _spots = [
    (x: 0.29, y: 0.37, pts: 25, visited: true, friends: 2),
    (x: 0.54, y: 0.50, pts: 15, visited: false, friends: 0),
    (x: 0.19, y: 0.63, pts: 20, visited: false, friends: 1),
    (x: 0.46, y: 0.25, pts: 10, visited: true, friends: 0),
    (x: 0.37, y: 0.74, pts: 18, visited: false, friends: 0),
  ];
  static const _friendDots = [
    (x: 0.41, y: 0.44, seed: 'alex'),
    (x: 0.58, y: 0.32, seed: 'mira'),
  ];

  @override
  void initState() {
    super.initState();
    _places = ApiService.nearbyPlaces();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return ColoredBox(
      color: const Color(0xFFEAEAE5),
      child: Stack(
        children: [
          // ── Pannable map ──
          Positioned.fill(
            child: AsyncView<List<Place>>(
              future: _places,
              errorTitle: 'Could not load the map',
              builder: (places) => _MapBody(
                places: places,
                spots: _spots,
                friendDots: _friendDots,
                onPinTap: (place, friends) => showPlaceSheet(
                  context,
                  place,
                  friendsHere: friends > 0
                      ? _friendDots.take(friends).map((f) => f.seed).toList()
                      : const [],
                ),
              ),
            ),
          ),

          // ── Top overlay ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.only(top: topInset + 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: Row(
                      children: [
                        _GlassButton(
                          child: const Icon(Icons.search_rounded,
                              size: 20, color: kText),
                          onTap: () {},
                        ),
                        const Spacer(),
                        _ExploringPill(),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: _categories.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 7),
                      itemBuilder: (_, i) {
                        final label = _categories[i];
                        final active = label == _category;
                        return GestureDetector(
                          onTap: () => setState(() => _category = label),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            padding: const EdgeInsets.symmetric(horizontal: 13),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: active
                                  ? kRed
                                  : Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.10),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(label,
                                style: jakartaSans(
                                    size: 12.5,
                                    weight: FontWeight.w700,
                                    color: active ? Colors.white : kText)),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Bottom-left list pill (FAB is provided by the shell) ──
          Positioned(
            left: 14,
            bottom: 14,
            child: _GlassPill(
              icon: Icons.format_list_bulleted_rounded,
              label: 'List',
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Map body: painted backdrop + interactive pins ────────────────────────────
class _MapBody extends StatelessWidget {
  final List<Place> places;
  final List<({double x, double y, int pts, bool visited, int friends})> spots;
  final List<({double x, double y, String seed})> friendDots;
  final void Function(Place place, int friends) onPinTap;

  const _MapBody({
    required this.places,
    required this.spots,
    required this.friendDots,
    required this.onPinTap,
  });

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 1,
      maxScale: 2.8,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth, h = c.maxHeight;
          final children = <Widget>[
            Positioned.fill(child: CustomPaint(painter: _MapPainter())),
          ];

          // Friend dots (behind pins)
          for (final f in friendDots) {
            children.add(_positioned(
              f.x * w,
              f.y * h,
              _FriendDot(seed: f.seed),
            ));
          }

          // Place pins
          for (var i = 0; i < spots.length && i < places.length; i++) {
            final s = spots[i];
            final place = places[i];
            children.add(_positioned(
              s.x * w,
              s.y * h,
              _PlacePin(
                name: place.name,
                pts: s.pts,
                visited: s.visited,
                friends: s.friends,
                delayMs: 60 * i,
                onTap: () => onPinTap(place, s.friends),
              ),
            ));
          }

          return Stack(clipBehavior: Clip.none, children: children);
        },
      ),
    );
  }

  // Anchor a marker by its bottom-centre (tip), like a real map pin.
  Widget _positioned(double dx, double dy, Widget child) {
    return Positioned(
      left: dx,
      top: dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -1.0),
        child: child,
      ),
    );
  }
}

// ─── Place pin ────────────────────────────────────────────────────────────────
class _PlacePin extends StatelessWidget {
  final String name;
  final int pts;
  final bool visited;
  final int friends;
  final int delayMs;
  final VoidCallback onTap;

  const _PlacePin({
    required this.name,
    required this.pts,
    required this.visited,
    required this.friends,
    required this.delayMs,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dot = visited ? kGreen : kRed;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + delayMs),
      curve: Curves.easeOutBack,
      builder: (_, t, child) => Transform.scale(
        scale: t.clamp(0, 1),
        alignment: Alignment.bottomCenter,
        child: child,
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border:
                    visited ? Border.all(color: kGreen, width: 1.5) : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: dot),
                  ),
                  const SizedBox(width: 6),
                  Text(name,
                      style: jakartaSans(
                          size: 11,
                          weight: FontWeight.w700,
                          color: const Color(0xFF14171A))),
                  const SizedBox(width: 6),
                  Text('+$pts',
                      style: jakartaSans(
                          size: 10, weight: FontWeight.w800, color: dot)),
                  if (friends > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, color: dot),
                      child: Text('$friends',
                          style: jakartaSans(
                              size: 9,
                              weight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
            // tail
            CustomPaint(size: const Size(14, 8), painter: _PinTail(Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _PinTail extends CustomPainter {
  final Color color;
  _PinTail(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PinTail old) => old.color != color;
}

// ─── Friend marker (avatar with presence dot) ─────────────────────────────────
class _FriendDot extends StatelessWidget {
  final String seed;
  const _FriendDot({required this.seed});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              UserAvatar(username: seed, size: 35),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kGreen,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        CustomPaint(size: const Size(12, 7), painter: _PinTail(Colors.white)),
      ],
    );
  }
}

// ─── Glass affordances ────────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _GlassButton({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _GlassPill(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: kText),
            const SizedBox(width: 8),
            Text(label,
                style: jakartaSans(size: 14, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ExploringPill extends StatelessWidget {
  static const _seeds = ['alex', 'mira', 'june'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 8, right: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24.0 + (_seeds.length - 1) * 16.0,
            height: 24,
            child: Stack(
              children: [
                for (var i = 0; i < _seeds.length; i++)
                  Positioned(
                    left: i * 16.0,
                    child: UserAvatar(username: _seeds[i], size: 24, ring: true),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Text('48 exploring',
              style: jakartaSans(size: 13, weight: FontWeight.w700)),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: kMuted),
        ],
      ),
    );
  }
}

// ─── Stylized city map backdrop ───────────────────────────────────────────────
class _MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFEAEAE5));

    // Street grid
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..strokeWidth = 1;
    for (double y = 0; y < h; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }
    for (double x = 0; x < w; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }

    // Major roads
    final roadL = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 3;
    final roadM = Paint()
      ..color = Colors.white.withValues(alpha: 0.92)
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(0.17 * w, 0), Offset(0.17 * w, h), roadL);
    canvas.drawLine(Offset(0.48 * w, 0), Offset(0.48 * w, h), roadM);
    canvas.drawLine(Offset(0, 0.43 * h), Offset(0.81 * w, 0.43 * h), roadL);
    canvas.drawLine(Offset(0, 0.65 * h), Offset(0.79 * w, 0.65 * h), roadM);

    // River (right edge)
    final river = RRect.fromRectAndCorners(
      Rect.fromLTWH(w - 72, 0, 72, h),
      topLeft: const Radius.circular(22),
      bottomLeft: const Radius.circular(8),
    );
    canvas.drawRRect(
        river, Paint()..color = const Color(0xFF93C2D8).withValues(alpha: 0.85));

    // Park
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(0.54 * w, 0.14 * h, 58, 38), const Radius.circular(12)),
      Paint()..color = const Color(0xFFBDD9A8).withValues(alpha: 0.55),
    );

    // Activity heat zones
    final zones = [
      (0.29, 0.37, 100.0, 70.0, kRed),
      (0.54, 0.50, 80.0, 55.0, kRed),
      (0.19, 0.63, 65.0, 46.0, kGreen),
    ];
    for (final z in zones) {
      final paint = Paint()..color = (z.$5).withValues(alpha: 0.10);
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(z.$1 * w, z.$2 * h), width: z.$3, height: z.$4),
        paint,
      );
    }

    // City label
    _text(canvas, 'Barranquilla', Offset(0.20 * w, 0.74 * h),
        size: 19,
        weight: FontWeight.w800,
        color: const Color(0xFF14171A).withValues(alpha: 0.16),
        spacing: -0.02 * 19);

    // Neighborhood labels
    const hoods = [
      ('EL PRADO', 0.20, 0.18),
      ('ZONA NORTE', 0.46, 0.12),
      ('RIOMAR', 0.38, 0.30),
      ('EL CENTRO', 0.20, 0.55),
    ];
    for (final n in hoods) {
      _text(canvas, n.$1, Offset(n.$2 * w, n.$3 * h),
          size: 9,
          weight: FontWeight.w700,
          color: const Color(0xFF14171A).withValues(alpha: 0.20),
          spacing: 0.06 * 9);
    }
  }

  void _text(Canvas canvas, String text, Offset at,
      {required double size,
      required FontWeight weight,
      required Color color,
      double spacing = 0}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: jakartaSans(
            size: size, weight: weight, color: color, letterSpacing: spacing),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(_MapPainter old) => false;
}
