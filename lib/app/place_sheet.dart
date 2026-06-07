import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../auth/widgets.dart' show PrimaryButton, BrandStripes;
import 'widgets.dart';
import 'checkin_screen.dart';

/// Presents the place-detail check-in sheet (step 1 of the capture flow): photo,
/// distance, who's been here, and the points breakdown — then launches the live
/// [CaptureFlow]. Opened from a map pin or any place reference.
Future<void> showPlaceSheet(BuildContext context, Place place,
    {List<String> friendsHere = const []}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xFF0E100F).withValues(alpha: 0.52),
    builder: (_) => _PlaceSheet(place: place, friendsHere: friendsHere),
  );
}

class _PlaceSheet extends StatelessWidget {
  final Place place;
  final List<String> friendsHere;
  const _PlaceSheet({required this.place, required this.friendsHere});

  bool get _inRange => (place.distanceMeters ?? 9999) <= 100;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(color: Color(0x3D000000), blurRadius: 40, offset: Offset(0, -8)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: kBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            // Photo strip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 96,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const BrandStripes(stripeWidth: 26),
                      Positioned(
                        top: 9,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: kGreen.withValues(alpha: 0.88),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 3),
                              Text('+20 pts',
                                  style: jakartaSans(
                                      size: 11,
                                      weight: FontWeight.w700,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place.name,
                                style: jakartaSans(
                                    size: 22,
                                    weight: FontWeight.w800,
                                    letterSpacing: -0.03 * 22,
                                    height: 1.1)),
                            const SizedBox(height: 3),
                            Text(
                              [
                                if (place.category != null) place.category!,
                                'Barranquilla'
                              ].join(' · '),
                              style: jakartaSans(
                                  size: 13.5,
                                  weight: FontWeight.w500,
                                  color: kMuted),
                            ),
                          ],
                        ),
                      ),
                      if (place.distanceLabel != null)
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                size: 14, color: _inRange ? kGreen : kMuted),
                            const SizedBox(width: 3),
                            Text(place.distanceLabel!,
                                style: jakartaSans(
                                    size: 12.5,
                                    weight: FontWeight.w700,
                                    color: _inRange ? kGreen : kMuted)),
                          ],
                        ),
                    ],
                  ),
                  if (friendsHere.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _friendsStrip(),
                  ],
                  const SizedBox(height: 10),
                  _pointsRow(Icons.location_on_rounded, 'Check-in base', 10),
                  _pointsRow(Icons.photo_camera_rounded, 'Live photo', 5),
                  _pointsRow(Icons.bolt_rounded, 'First check-in of the day', 5),
                  const SizedBox(height: 14),
                  PrimaryButton(
                    label: 'Start check-in',
                    color: _inRange ? kRed : const Color(0xFFCBCDCA),
                    onTap: _inRange
                        ? () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => CaptureFlow(place: place)),
                            );
                          }
                        : null,
                  ),
                  const SizedBox(height: 7),
                  Center(
                    child: Text(
                      _inRange
                          ? 'You\'re in range — proof photo required'
                          : 'Get within 100 m of the place to check in',
                      style: jakartaSans(
                          size: 12, weight: FontWeight.w500, color: kMuted),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _friendsStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: kField,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24.0 + (friendsHere.length - 1) * 17.0,
            height: 24,
            child: Stack(
              children: [
                for (var i = 0; i < friendsHere.length; i++)
                  Positioned(
                    left: i * 17.0,
                    child: UserAvatar(
                        username: friendsHere[i], size: 24, ring: true),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: jakartaSans(
                    size: 12.5, weight: FontWeight.w500, color: kMuted),
                children: [
                  TextSpan(text: '@${friendsHere.first} '),
                  const TextSpan(text: 'was here '),
                  TextSpan(
                      text: '3h ago',
                      style:
                          jakartaSans(size: 12.5, weight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pointsRow(IconData icon, String label, int pts) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: kFaint)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
                color: kField, borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, size: 16, color: kMuted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: jakartaSans(size: 14, weight: FontWeight.w500)),
          ),
          Text('+$pts',
              style: jakartaSans(
                  size: 14, weight: FontWeight.w800, color: kGreen)),
        ],
      ),
    );
  }
}
