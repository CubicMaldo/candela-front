import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../auth/widgets.dart' show PrimaryButton, GhostButton;
import 'widgets.dart';

/// Check-in entry point shown from the central FAB. Lists nearby places; tapping
/// one launches the anti-fraud [CaptureFlow]. For an in-context check-in (from a
/// map pin) call [CaptureFlow] directly with a known [Place].
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  late Future<List<Place>> _places;
  Place? _selected;

  @override
  void initState() {
    super.initState();
    _places = ApiService.nearbyPlaces();
  }

  void _startFlow(Place place) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CaptureFlow(place: place)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: kField, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.close_rounded, size: 22, color: kText),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('Check in',
                      style: jakartaSans(
                          size: 24, weight: FontWeight.w800, letterSpacing: -0.03 * 24)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
              child: Text(
                'Pick a place near you. You must be physically there to check in.',
                style: jakartaSans(size: 14.5, weight: FontWeight.w500, color: kMuted),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AsyncView<List<Place>>(
                future: _places,
                errorTitle: 'Could not find places',
                builder: (places) {
                  if (places.isEmpty) {
                    return const EmptyState(
                      icon: Icons.location_off_outlined,
                      title: 'No places nearby',
                      message: 'Move closer to a registered place to check in.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: places.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = places[i];
                      final sel = p.id == _selected?.id;
                      final near = (p.distanceMeters ?? 9999) <= 150;
                      return GestureDetector(
                        onTap: () => setState(() => _selected = p),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: sel ? kSoftRed : kBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: sel ? kRed : kBorder, width: sel ? 1.5 : 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                decoration: BoxDecoration(
                                    color: kField,
                                    borderRadius: BorderRadius.circular(13)),
                                child: Icon(Icons.place_rounded,
                                    color: sel ? kRed : kMuted, size: 23),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.name,
                                        style: jakartaSans(
                                            size: 15.5, weight: FontWeight.w700)),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        if (p.category != null)
                                          Text(p.category!,
                                              style: jakartaSans(
                                                  size: 12.5,
                                                  weight: FontWeight.w600,
                                                  color: kMuted)),
                                        if (p.distanceLabel != null) ...[
                                          Text('  •  ',
                                              style: jakartaSans(
                                                  size: 12.5, color: kMuted)),
                                          Text(p.distanceLabel!,
                                              style: jakartaSans(
                                                  size: 12.5,
                                                  weight: FontWeight.w600,
                                                  color: near ? kGreen : kMuted)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (near)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: kSoftGreen,
                                      borderRadius: BorderRadius.circular(999)),
                                  child: Text('In range',
                                      style: jakartaSans(
                                          size: 11,
                                          weight: FontWeight.w700,
                                          color: kGreen)),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: PrimaryButton(
                label: _selected == null
                    ? 'Select a place'
                    : 'Check in at ${_selected!.name}',
                color: _selected == null ? const Color(0xFFCBCDCA) : kRed,
                onTap: _selected == null ? null : () => _startFlow(_selected!),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Capture flow: initiate → live camera + 90s nonce → confirm → celebrate ────
enum _Stage { initiating, camera, confirming, done, error }

/// The full anti-fraud capture flow for a known [place]: location check, live
/// camera with a 90-second nonce window (gallery blocked), confirm, then a
/// celebratory points breakdown. Camera + GPS are device-specific and simulated
/// here; the two real API calls slot into [_initiate] and [_capture].
class CaptureFlow extends StatefulWidget {
  final Place place;
  const CaptureFlow({required this.place, super.key});

  @override
  State<CaptureFlow> createState() => _CaptureFlowState();
}

class _CaptureFlowState extends State<CaptureFlow> {
  _Stage _stage = _Stage.initiating;
  Timer? _timer;
  int _secondsLeft = 90;
  String _error = '';

  // Points breakdown surfaced in the celebration screen.
  static const _base = 10, _photo = 5, _firstOfDay = 5;
  int get _total => _base + _photo + _firstOfDay;

  @override
  void initState() {
    super.initState();
    _initiate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // POST /checkin/initiate with lat/lon — would request OS location first.
  Future<void> _initiate() async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _stage = _Stage.camera);
    _startCountdown();
  }

  void _startCountdown() {
    _secondsLeft = 90;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        t.cancel();
        setState(() {
          _stage = _Stage.error;
          _error = 'The 90-second window expired. Please start again.';
        });
      }
    });
  }

  // Upload photo to storage, then POST /checkin/confirm.
  Future<void> _capture() async {
    _timer?.cancel();
    setState(() => _stage = _Stage.confirming);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() => _stage = _Stage.done);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _stage == _Stage.camera ? const Color(0xFF090E0C) : kBg,
      body: switch (_stage) {
        _Stage.initiating => SafeArea(
            child: _centered(
              const CircularProgressIndicator(color: kRed, strokeWidth: 2.5),
              "Checking you're here…",
              'Verifying your location at ${widget.place.name}',
            ),
          ),
        _Stage.camera => _CameraView(
            place: widget.place,
            secondsLeft: _secondsLeft,
            onCapture: _capture,
            onCancel: () => Navigator.maybePop(context),
          ),
        _Stage.confirming => SafeArea(
            child: _centered(
              const CircularProgressIndicator(color: kGreen, strokeWidth: 2.5),
              'Confirming check-in…',
              'Uploading your live photo',
            ),
          ),
        _Stage.done => _CelebrationView(
            place: widget.place,
            base: _base,
            photo: _photo,
            firstOfDay: _firstOfDay,
            total: _total,
          ),
        _Stage.error => SafeArea(child: _errorView()),
      },
    );
  }

  Widget _centered(Widget top, String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          top,
          const SizedBox(height: 22),
          Text(title, style: jakartaSans(size: 18, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(sub,
              textAlign: TextAlign.center,
              style: jakartaSans(size: 14, weight: FontWeight.w500, color: kMuted)),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(color: kSoftRed, shape: BoxShape.circle),
              child: const Icon(Icons.timer_off_rounded, color: kRed, size: 34),
            ),
            const SizedBox(height: 20),
            Text('Check-in expired',
                style: jakartaSans(size: 22, weight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(_error,
                textAlign: TextAlign.center,
                style:
                    jakartaSans(size: 14.5, weight: FontWeight.w500, color: kMuted)),
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Try again',
              onTap: () {
                setState(() => _stage = _Stage.initiating);
                _initiate();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Live camera viewfinder (corner guides + nonce + anti-fraud notice) ───────
class _CameraView extends StatelessWidget {
  final Place place;
  final int secondsLeft;
  final VoidCallback onCapture;
  final VoidCallback onCancel;

  const _CameraView({
    required this.place,
    required this.secondsLeft,
    required this.onCapture,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final urgent = secondsLeft <= 20;
    final mm = secondsLeft ~/ 60;
    final ss = (secondsLeft % 60).toString().padLeft(2, '0');
    return SafeArea(
      child: Column(
        children: [
          // Top bar: close · title · nonce countdown
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: onCancel,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.close_rounded,
                        color: Colors.white.withValues(alpha: 0.72), size: 22),
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text('Live capture',
                          style: jakartaSans(
                              size: 15.5,
                              weight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.95))),
                      const SizedBox(height: 2),
                      Text(place.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: jakartaSans(
                              size: 11.5,
                              weight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.42))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: kRed.withValues(alpha: urgent ? 0.34 : 0.20),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: kRed.withValues(alpha: 0.32)),
                  ),
                  child: Column(
                    children: [
                      Text('$mm:$ss',
                          style: jakartaSans(
                              size: 18,
                              weight: FontWeight.w800,
                              color: urgent ? Colors.white : kRed,
                              letterSpacing: -0.02 * 18,
                              height: 1)),
                      const SizedBox(height: 2),
                      Text('EXPIRES',
                          style: jakartaSans(
                              size: 9,
                              weight: FontWeight.w600,
                              color: (urgent ? Colors.white : kRed)
                                  .withValues(alpha: 0.75),
                              letterSpacing: 0.04 * 9)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Viewfinder
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: Color(0xFF131A17)),
                    CustomPaint(painter: _ViewfinderPainter()),
                    // Centre hint
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_camera_rounded,
                              size: 54, color: Colors.white.withValues(alpha: 0.20)),
                          const SizedBox(height: 12),
                          Text('Point toward the place',
                              style: jakartaSans(
                                  size: 13,
                                  weight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.26))),
                        ],
                      ),
                    ),
                    // Anti-fraud notice
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 14,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.64),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: kRed.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(Icons.warning_amber_rounded,
                                  color: kRed, size: 14),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Live photos only. The gallery is locked.',
                                style: jakartaSans(
                                    size: 12,
                                    weight: FontWeight.w600,
                                    height: 1.3,
                                    color: Colors.white.withValues(alpha: 0.82)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Shutter
          Padding(
            padding: const EdgeInsets.only(top: 22, bottom: 24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onCapture,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.72), width: 3),
                    ),
                    child: Center(
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.90),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: onCancel,
                  child: Text('Cancel',
                      style: jakartaSans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.32))),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Faint diagonal texture + four corner guides for the viewfinder.
class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final texture = Paint()..color = Colors.white.withValues(alpha: 0.025);
    for (double x = -size.height; x < size.width; x += 14) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 2, size.height).shift(const Offset(0, 0)),
        texture,
      );
    }
    final guide = Paint()
      ..color = Colors.white.withValues(alpha: 0.42)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const m = 18.0, len = 24.0;
    final w = size.width, h = size.height;
    // top-left
    canvas.drawLine(const Offset(m, m), const Offset(m + len, m), guide);
    canvas.drawLine(const Offset(m, m), const Offset(m, m + len), guide);
    // top-right
    canvas.drawLine(Offset(w - m, m), Offset(w - m - len, m), guide);
    canvas.drawLine(Offset(w - m, m), Offset(w - m, m + len), guide);
    // bottom-left
    canvas.drawLine(Offset(m, h - m), Offset(m + len, h - m), guide);
    canvas.drawLine(Offset(m, h - m), Offset(m, h - m - len), guide);
    // bottom-right
    canvas.drawLine(Offset(w - m, h - m), Offset(w - m - len, h - m), guide);
    canvas.drawLine(Offset(w - m, h - m), Offset(w - m, h - m - len), guide);
  }

  @override
  bool shouldRepaint(_ViewfinderPainter old) => false;
}

// ─── Celebration: animated check + points breakdown + streak ──────────────────
class _CelebrationView extends StatefulWidget {
  final Place place;
  final int base, photo, firstOfDay, total;
  const _CelebrationView({
    required this.place,
    required this.base,
    required this.photo,
    required this.firstOfDay,
    required this.total,
  });

  @override
  State<_CelebrationView> createState() => _CelebrationViewState();
}

class _CelebrationViewState extends State<_CelebrationView>
    with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(parent: _pop, curve: Curves.elasticOut);
    final fade = CurvedAnimation(parent: _pop, curve: const Interval(0.2, 1.0));
    return Stack(
      children: [
        // Confetti
        Positioned.fill(
          child: IgnorePointer(
            child: FadeTransition(
              opacity: fade,
              child: CustomPaint(painter: _ConfettiPainter()),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      ScaleTransition(
                        scale: pop,
                        child: Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kGreen,
                            boxShadow: [
                              BoxShadow(
                                color: kGreen.withValues(alpha: 0.36),
                                blurRadius: 40,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.check_rounded,
                              color: Colors.white, size: 44),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text('Check-in confirmed!',
                          textAlign: TextAlign.center,
                          style: jakartaSans(
                              size: 26,
                              weight: FontWeight.w800,
                              letterSpacing: -0.03 * 26)),
                      const SizedBox(height: 6),
                      Text(widget.place.name,
                          textAlign: TextAlign.center,
                          style: jakartaSans(
                              size: 14,
                              weight: FontWeight.w500,
                              color: kMuted)),
                      const SizedBox(height: 26),
                      FadeTransition(
                        opacity: fade,
                        child: Column(
                          children: [
                            _pointsCard(),
                            const SizedBox(height: 12),
                            _streakPill(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  children: [
                    PrimaryButton(
                      label: 'View my ranking',
                      color: kGreen,
                      onTap: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                    GhostButton(
                      label: 'Back to map',
                      onTap: () =>
                          Navigator.of(context).popUntil((r) => r.isFirst),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pointsCard() {
    Widget row(String label, int pts, {bool total = false}) => Padding(
          padding: EdgeInsets.only(top: total ? 10 : 0, bottom: total ? 0 : 0),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: total ? 0 : 7),
            decoration: total
                ? null
                : const BoxDecoration(
                    border: Border(bottom: BorderSide(color: kFaint))),
            child: Row(
              children: [
                Text(label,
                    style: jakartaSans(
                        size: total ? 15 : 13.5,
                        weight: total ? FontWeight.w800 : FontWeight.w500,
                        color: kText)),
                const Spacer(),
                Text(total ? '+$pts pts' : '+$pts',
                    style: jakartaSans(
                        size: total ? 24 : 13.5,
                        weight: total ? FontWeight.w800 : FontWeight.w700,
                        color: total ? kGreen : kMuted,
                        letterSpacing: total ? -0.03 * 24 : 0)),
              ],
            ),
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: kField,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('POINTS EARNED',
              style: jakartaSans(
                  size: 10.5,
                  weight: FontWeight.w700,
                  color: kMuted,
                  letterSpacing: 0.08 * 10.5)),
          const SizedBox(height: 11),
          row('Check-in base', widget.base),
          row('Live photo', widget.photo),
          row('First of the day', widget.firstOfDay),
          row('Total', widget.total, total: true),
        ],
      ),
    );
  }

  Widget _streakPill() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: kRed.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kRed.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: kRed, size: 22),
          ),
          const SizedBox(width: 11),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Active streak: 13 days',
                  style: jakartaSans(size: 14.5, weight: FontWeight.w800)),
              const SizedBox(height: 1),
              Text('+1 day · keep exploring tomorrow',
                  style: jakartaSans(
                      size: 12, weight: FontWeight.w500, color: kMuted)),
            ],
          ),
        ],
      ),
    );
  }
}

// Scattered confetti chips in the brand palette (static, faded in).
class _ConfettiPainter extends CustomPainter {
  static const _chips = [
    [0.11, 0.16, 12.0, 8.0, 45.0],
    [0.80, 0.10, 9.0, 9.0, 20.0],
    [0.68, 0.20, 14.0, 6.0, -30.0],
    [0.20, 0.28, 8.0, 8.0, 60.0],
    [0.88, 0.30, 10.0, 7.0, -20.0],
    [0.05, 0.40, 11.0, 9.0, 15.0],
    [0.74, 0.42, 8.0, 12.0, -45.0],
    [0.32, 0.12, 7.0, 10.0, 30.0],
    [0.55, 0.08, 10.0, 7.0, -15.0],
  ];
  static const _colors = [
    kRed,
    kGreen,
    Color(0xFFF2B705),
    Color(0xFF5C9CE8),
    Color(0xFF7C5CBF),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _chips.length; i++) {
      final c = _chips[i];
      final paint = Paint()..color = _colors[i % _colors.length].withValues(alpha: 0.70);
      canvas.save();
      canvas.translate(c[0] * size.width, c[1] * size.height);
      canvas.rotate(c[4] * math.pi / 180);
      final r = math.min(c[2], c[3]) / 4;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: c[2], height: c[3]),
          Radius.circular(r),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}
