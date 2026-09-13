import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import 'widgets.dart';
import 'photo_viewer.dart';
import 'place_sheet.dart';

/// The "city scroll" — a near-seamless vertical feed of recent check-in photos
/// across the city (priority layer 1 = friends, 2 = followed places, 3 = city).
/// No likes, comments, or shares: Candela's feed is purely ambient discovery.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _scrollCtrl = ScrollController();
  final _events = <CheckInEvent>[];

  late Future<bool> _initial;
  bool _loadingMore = false;
  String? _nextCursor;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _initial = _load();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<bool> _load() async {
    final page = await ApiService.getFeed();
    if (!mounted) return true;
    setState(() {
      _events
        ..clear()
        ..addAll(page.events);
      _nextCursor = page.nextCursor;
      _hasMore = page.hasMore;
    });
    return true;
  }

  Future<void> _refresh() async {
    await _load();
  }

  void _onScroll() {
    if (_loadingMore || !_hasMore) return;
    if (_scrollCtrl.position.pixels >
        _scrollCtrl.position.maxScrollExtent - 400) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    final cursor = _nextCursor;
    if (cursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ApiService.getFeed(cursor: cursor);
      if (!mounted) return;
      setState(() {
        // Guard against a stale page arriving after a pull-to-refresh reset
        // the list: appending it would duplicate what is already on screen.
        final seen = _events.map((e) => e.checkinId).toSet();
        _events.addAll(page.events.where((e) => seen.add(e.checkinId)));
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
      });
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        Positioned.fill(child: _buildFeed(context)),
        // Subtle top scrim so the status bar stays legible over bright photos.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: topInset + 16,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeed(BuildContext context) {
    return AsyncView<bool>(
      future: _initial,
      errorTitle: 'No se pudo cargar el feed',
      loading: const FeedSkeleton(),
      builder: (_) {
        if (_events.isEmpty) {
          return RefreshIndicator(
            color: candelaAmber,
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [SizedBox(height: 140), _EmptyFeed()],
            ),
          );
        }
        return RefreshIndicator(
          color: candelaAmber,
          onRefresh: _refresh,
          child: ListView.separated(
            controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(),
            // Photos slide under the frosted nav bar while scrolling (the
            // premium translucency), but the last card must be able to rise
            // fully above it — otherwise its @user/place metadata stays hidden
            // behind the bar at rest.
            padding: EdgeInsets.only(bottom: bottomListGap(context)),
            itemCount: _events.length + (_loadingMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 2),
            itemBuilder: (context, i) {
              if (i >= _events.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: candelaAmber,
                        strokeWidth: 2.5,
                      ),
                    ),
                  ),
                );
              }
              final event = _events[i];
              final layer = event.priorityLayer;
              final previousLayer = i > 0 ? _events[i - 1].priorityLayer : null;
              // The list is edge-to-edge (photos slide under the status bar),
              // so a header at the very top needs the inset or the clock
              // overlaps its text.
              final topInset = i == 0
                  ? MediaQuery.of(context).padding.top
                  : 0.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (layer != null && layer != previousLayer)
                    Padding(
                      padding: EdgeInsets.only(top: topInset),
                      child: _LayerHeader(layer),
                    ),
                  _FeedCard(event),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department_rounded,
              size: 40,
              color: secondaryOn(context),
            ),
            const SizedBox(height: 14),
            Text(
              'Todavía está tranquilo por aquí. La noche es joven.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: secondaryOn(context)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Layer header ─────────────────────────────────────────────────────────────
/// Subtle separator between the feed's priority layers (spec §9.3): friends,
/// followed places, then the rest of the city.
class _LayerHeader extends StatelessWidget {
  final int layer;
  const _LayerHeader(this.layer);

  static const _labels = {
    1: 'Tu gente',
    2: 'Lugares que sigues',
    3: 'La ciudad',
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[layer];
    if (label == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(spacingScreen, 14, spacingScreen, 8),
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: secondaryOn(context),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(thickness: 0.5)),
        ],
      ),
    );
  }
}

// ─── Feed card ────────────────────────────────────────────────────────────────
class _FeedCard extends StatelessWidget {
  final CheckInEvent event;
  const _FeedCard(this.event);

  Future<void> _openPlace(BuildContext context) async {
    final place = await ApiService.getPlaceDetail(event.place.placeId);
    if (context.mounted) showPlaceSheet(context, place);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      // Photo tap opens the full-screen viewer; the place name below goes to
      // the event screen (spec §9.2). Cards without a photo go to the place.
      onTap: () => event.photoUrl != null
          ? showPhotoViewer(context, event)
          : _openPlace(context),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: 'checkin-photo-${event.checkinId}',
              child: _Photo(photoUrl: event.photoUrl),
            ),
            // Bottom gradient: transparent at top 60%, fades to dark at bottom
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.6, 1.0],
                    colors: [Colors.transparent, Color(0x99000000)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '@${event.user.username}',
                              style: textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                            if (event.user.isFriend) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: candelaAmber.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(
                                    radiusPill,
                                  ),
                                ),
                                child: Text(
                                  'Amigo',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: candelaAmber,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () => _openPlace(context),
                          child: Text(
                            event.place.name,
                            style: textTheme.bodySmall?.copyWith(
                              color: candelaAmber,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (!event.photoIsPermanent) ...[
                    Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    timeAgo(event.checkedInAt),
                    style: textTheme.bodySmall?.copyWith(
                      color: textDarkSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Photo (handles expired / missing photos) ────────────────────────────────
class _Photo extends StatelessWidget {
  final String? photoUrl;
  const _Photo({required this.photoUrl});

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null) {
      return const ColoredBox(
        color: candelaNight,
        child: Center(
          child: Icon(
            Icons.local_fire_department_rounded,
            size: 32,
            color: textDarkSecondary,
          ),
        ),
      );
    }
    return Image.network(
      photoUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: candelaNight,
        child: Center(
          child: Icon(
            Icons.local_fire_department_rounded,
            size: 32,
            color: textDarkSecondary,
          ),
        ),
      ),
    );
  }
}
