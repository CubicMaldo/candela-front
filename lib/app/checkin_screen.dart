import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../auth/widgets.dart' show PrimaryButton, LokalLogo;
import 'widgets.dart';

/// Check-in entry point. The real product flow is:
/// initiate (GPS) → in-app camera → 90s nonce countdown → confirm → points.
/// Camera + GPS are device-specific; this screen drives the UI of that flow
/// and the two API calls, with a simulated capture step for now.
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
      MaterialPageRoute(builder: (_) => _CaptureFlow(place: place)),
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

// ─── Capture flow: initiate → camera + 90s countdown → confirm ────────────────
enum _Stage { initiating, camera, confirming, done, error }

class _CaptureFlow extends StatefulWidget {
  final Place place;
  const _CaptureFlow({required this.place});

  @override
  State<_CaptureFlow> createState() => _CaptureFlowState();
}

class _CaptureFlowState extends State<_CaptureFlow> {
  _Stage _stage = _Stage.initiating;
  Timer? _timer;
  int _secondsLeft = 90;
  String _error = '';
  int _pointsAwarded = 20;

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

  // Step 2 in the guide: POST /checkin/initiate with lat/lon.
  Future<void> _initiate() async {
    // Real impl would request OS location permission then call the API.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _stage = _Stage.camera);
    _startCountdown();
  }

  void _startCountdown() {
    _secondsLeft = 90;
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

  // Step 5+6: upload photo to storage, then POST /checkin/confirm.
  Future<void> _capture() async {
    _timer?.cancel();
    setState(() => _stage = _Stage.confirming);
    await Future.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    setState(() {
      _pointsAwarded = 20; // base 10 + first-of-day 5 + photo 5
      _stage = _Stage.done;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _stage == _Stage.camera ? Colors.black : kBg,
      body: SafeArea(
        child: switch (_stage) {
          _Stage.initiating => _centered(
              const CircularProgressIndicator(color: kRed, strokeWidth: 2.5),
              'Checking you\'re here…',
              'Verifying your location at ${widget.place.name}',
            ),
          _Stage.camera => _cameraView(),
          _Stage.confirming => _centered(
              const CircularProgressIndicator(color: kGreen, strokeWidth: 2.5),
              'Confirming check-in…',
              'Uploading your photo',
            ),
          _Stage.done => _successView(),
          _Stage.error => _errorView(),
        },
      ),
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

  Widget _cameraView() {
    final urgent = _secondsLeft <= 20;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: urgent ? kRed : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text('0:${_secondsLeft.toString().padLeft(2, '0')}',
                        style: jakartaSans(
                            size: 14, weight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.photo_camera_rounded,
                    color: Colors.white.withValues(alpha: 0.5), size: 64),
                const SizedBox(height: 16),
                Text('Capture proof you\'re at',
                    style: jakartaSans(
                        size: 14,
                        weight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7))),
                const SizedBox(height: 4),
                Text(widget.place.name,
                    style: jakartaSans(
                        size: 18, weight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 8),
                Text('No gallery — real presence only',
                    style: jakartaSans(
                        size: 12.5,
                        weight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.5))),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 36, top: 12),
          child: GestureDetector(
            onTap: _capture,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _successView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LokalLogo(size: 60),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                  color: kSoftGreen, borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, color: kGreen, size: 22),
                  const SizedBox(width: 6),
                  Text('+$_pointsAwarded points',
                      style: jakartaSans(
                          size: 18, weight: FontWeight.w800, color: kGreen)),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Checked in! 🎉',
                style: jakartaSans(
                    size: 26, weight: FontWeight.w800, letterSpacing: -0.03 * 26)),
            const SizedBox(height: 8),
            Text('You checked in at ${widget.place.name}.\nFirst of the day — bonus points added.',
                textAlign: TextAlign.center,
                style:
                    jakartaSans(size: 15, weight: FontWeight.w500, color: kMuted)),
            const SizedBox(height: 32),
            PrimaryButton(
              label: 'Done',
              color: kGreen,
              onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
            ),
          ],
        ),
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
