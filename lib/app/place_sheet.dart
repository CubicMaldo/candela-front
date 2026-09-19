import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models.dart';
import 'package:candela_front/services/api/api_client.dart';
import 'package:candela_front/services/api/auth_api.dart';
import 'package:candela_front/services/api/users_api.dart';
import 'package:candela_front/services/api/places_api.dart';
import 'package:candela_front/services/api/plans_api.dart';
import 'package:candela_front/services/api/feed_api.dart';
import 'package:candela_front/services/api/checkin_api.dart';
import 'package:candela_front/services/api/misc_api.dart';
import 'widgets.dart';
import 'checkin_screen.dart';
import 'photo_viewer.dart';
import 'report_dialog.dart';

/// Opens the place detail as a draggable bottom sheet — header info, follow
/// button, a horizontal strip of recent check-in photos, and (when eligible)
/// the check-in CTA.
Future<void> showPlaceSheet(BuildContext context, Place place) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: candelaNight.withValues(alpha: 0.6),
    builder: (_) => _PlaceSheet(place: place),
  );
}

class _PlaceSheet extends StatefulWidget {
  final Place place;
  const _PlaceSheet({required this.place});

  @override
  State<_PlaceSheet> createState() => _PlaceSheetState();
}

class _PlaceSheetState extends State<_PlaceSheet> {
  late Place _place;
  late Future<List<CheckInEvent>> _events;
  bool _followBusy = false;

  @override
  void initState() {
    super.initState();
    _place = widget.place;
    _events = FeedApi.getEventFeed(_place.placeId);
    // The map/list hand us the "nearby" shape, which lacks the live counters
    // (active_checkins_count, is_followed, follower_count) — refresh from the
    // detail endpoint so the sheet never shows "0 personas" on an active spot.
    PlacesApi.getPlaceDetail(_place.placeId)
        .then((detail) {
          if (mounted) setState(() => _place = detail);
        })
        .catchError((_) {});
  }

  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    HapticFeedback.lightImpact();
    setState(() => _followBusy = true);
    try {
      final (following, followerCount) = _place.isFollowed
          ? await PlacesApi.unfollowPlace(_place.placeId)
          : await PlacesApi.followPlace(_place.placeId);
      if (!mounted) return;
      setState(() {
        _place = _place.copyWith(
          isFollowed: following,
          followerCount: followerCount,
        );
      });
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) {
        // Theme-aware like every other sheet in the app — Sand in light mode,
        // Night in dark mode.
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(radiusCard),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              spacingScreen,
              12,
              spacingScreen,
              24,
            ),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderInactive.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _Header(
                place: _place,
                busy: _followBusy,
                onFollowTap: _toggleFollow,
              ),
              const SizedBox(height: 22),
              Text(
                'Actividad reciente',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 12),
              _EventStrip(future: _events),
              const SizedBox(height: 24),
              if (_place.isActive) _CheckInCta(place: _place),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: secondaryOn(context),
                  ),
                  onPressed: () => showReportDialog(
                    context,
                    targetType: 'PLACE',
                    targetId: _place.placeId,
                    targetName: _place.name,
                  ),
                  icon: const Icon(Icons.flag_outlined, size: 16),
                  label: const Text('Denunciar este lugar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final Place place;
  final bool busy;
  final VoidCallback onFollowTap;
  const _Header({
    required this.place,
    required this.busy,
    required this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.name, style: textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderInactive),
                      borderRadius: BorderRadius.circular(radiusPill),
                    ),
                    child: Text(
                      categoryLabel(place.category),
                      style: textTheme.bodySmall?.copyWith(
                        color: secondaryOn(context),
                      ),
                    ),
                  ),
                  Text(
                    'Radio ${place.geofenceMeters} m',
                    style: textTheme.bodySmall?.copyWith(
                      color: secondaryOn(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${place.activeCheckinsCount} personas ahora',
                style: textTheme.bodySmall?.copyWith(
                  color: candelaAmber,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _FollowButton(
          following: place.isFollowed,
          busy: busy,
          onTap: onFollowTap,
        ),
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  final bool following;
  final bool busy;
  final VoidCallback onTap;
  const _FollowButton({
    required this.following,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: following ? candelaAmber : Colors.transparent,
          borderRadius: BorderRadius.circular(radiusPill),
          border: following
              ? null
              : Border.all(color: candelaAmber, width: 1.5),
        ),
        child: busy
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: following ? Colors.white : candelaAmber,
                ),
              )
            : Text(
                following ? 'Siguiendo' : 'Seguir',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: following ? Colors.white : candelaAmber,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}

// ─── Event photo strip ────────────────────────────────────────────────────────
class _EventStrip extends StatelessWidget {
  final Future<List<CheckInEvent>> future;
  const _EventStrip({required this.future});

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<CheckInEvent>>(
      future: future,
      errorTitle: 'No se pudo cargar la actividad',
      builder: (events) {
        if (events.isEmpty) {
          return Text(
            'Sé el primero en llegar.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: secondaryOn(context)),
          );
        }
        return SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final event = events[i];
              final url = event.photoUrl;
              return GestureDetector(
                onTap: url == null
                    ? null
                    : () => showPhotoViewer(context, event),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(radiusMedium),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (url == null)
                          const ColoredBox(
                            color: candelaNight,
                            child: Icon(
                              Icons.local_fire_department_rounded,
                              color: textDarkSecondary,
                              size: 26,
                            ),
                          )
                        else
                          CachedNetworkImage(imageUrl: 
                            url,
                            fit: BoxFit.cover,
                            errorWidget: (_, _, _) => const ColoredBox(
                              color: candelaNight,
                              child: Icon(
                                Icons.local_fire_department_rounded,
                                color: textDarkSecondary,
                                size: 26,
                              ),
                            ),
                          ),
                        // Author overlay — who is there right now.
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Color(0xB3000000)],
                              ),
                            ),
                            child: Row(
                              children: [
                                if (event.user.isFriend) ...[
                                  const Icon(
                                    Icons.favorite_rounded,
                                    size: 10,
                                    color: candelaAmber,
                                  ),
                                  const SizedBox(width: 3),
                                ],
                                Expanded(
                                  child: Text(
                                    '@${event.user.username}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
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
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Check-in CTA ─────────────────────────────────────────────────────────────
class _CheckInCta extends StatelessWidget {
  final Place place;
  const _CheckInCta({required this.place});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: candelaAmber,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            SlideRightRoute(builder: (_) => CheckInScreen(initialPlace: place)),
          );
        },
        child: const Text('Hacer check-in aquí'),
      ),
    );
  }
}


