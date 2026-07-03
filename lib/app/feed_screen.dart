import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import 'widgets.dart';
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
    final events = await ApiService.getFeed();
    if (!mounted) return true;
    setState(() {
      _events
        ..clear()
        ..addAll(events);
      _hasMore = events.isNotEmpty;
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
    if (_events.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final cursor = _events.last.checkedInAt.toIso8601String();
      final more = await ApiService.getFeed(cursor: cursor);
      if (!mounted) return;
      setState(() {
        _events.addAll(more);
        _hasMore = more.isNotEmpty;
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
            padding: EdgeInsets.zero,
            itemCount: _events.length + (_loadingMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(height: 2),
            itemBuilder: (_, i) {
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
              return _FeedCard(_events[i]);
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
            const Icon(
              Icons.local_fire_department_rounded,
              size: 40,
              color: textSecondary,
            ),
            const SizedBox(height: 14),
            Text(
              'Todavía está tranquilo por aquí. La noche es joven.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feed card ────────────────────────────────────────────────────────────────
class _FeedCard extends StatelessWidget {
  final CheckInEvent event;
  const _FeedCard(this.event);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: () async {
        final place = await ApiService.getPlaceDetail(event.place.placeId);
        if (context.mounted) showPlaceSheet(context, place);
      },
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Photo(photoUrl: event.photoUrl),
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
                        Text(
                          event.place.name,
                          style: textTheme.bodySmall?.copyWith(
                            color: candelaAmber,
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
