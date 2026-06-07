import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../auth/widgets.dart' show LokalLogo, GamificationChip;
import 'widgets.dart';
import 'friends_screen.dart';
import 'place_sheet.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late Future<List<FeedEvent>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.feed();
  }

  Future<void> _refresh() async {
    setState(() => _future = ApiService.feed());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                const LokalLogo(size: 32),
                const SizedBox(width: 10),
                Text(
                  'Lokal',
                  style: jakartaSans(
                    size: 22,
                    weight: FontWeight.w800,
                    letterSpacing: -0.03 * 22,
                  ),
                ),
                const Spacer(),
                _IconChip(
                  icon: Icons.group_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FriendsScreen()),
                  ),
                ),
                const SizedBox(width: 10),
                _IconChip(icon: Icons.notifications_none_rounded, onTap: () {}),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: _DailySnapshot(),
          ),
          Expanded(
            child: RefreshIndicator(
              color: kRed,
              onRefresh: _refresh,
              child: AsyncView<List<FeedEvent>>(
                future: _future,
                errorTitle: 'Could not load your feed',
                builder: (events) {
                  if (events.isEmpty) {
                    return ListView(
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.dynamic_feed_rounded,
                          title: 'Your feed is quiet',
                          message:
                              'Add friends and check in to places to see activity here.',
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _FeedCard(events[i]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconChip({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 21, color: kText),
      ),
    );
  }
}

// ─── Daily snapshot (points today + streak) ───────────────────────────────────
class _DailySnapshot extends StatelessWidget {
  const _DailySnapshot();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const GamificationChip('+25 pts today'),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(11, 7, 13, 7),
          decoration: BoxDecoration(
            color: kField,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_fire_department_rounded,
                  size: 15, color: kRed),
              const SizedBox(width: 6),
              Text('12-day streak',
                  style: jakartaSans(size: 12.5, weight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Feed card ────────────────────────────────────────────────────────────────
class _FeedCard extends StatelessWidget {
  final FeedEvent event;
  const _FeedCard(this.event);

  @override
  Widget build(BuildContext context) {
    return switch (event.type) {
      FeedType.checkin => _checkinCard(context),
      FeedType.challengeCompleted => _challengeCard(),
      FeedType.unknown => const SizedBox.shrink(),
    };
  }

  Widget _checkinCard(BuildContext context) {
    final u = event.user;
    final place = event.place;
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: place == null ? null : () => showPlaceSheet(context, place),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                UserAvatar(username: u?.username ?? '?', size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '@${u?.username ?? 'someone'}',
                              style: jakartaSans(size: 15.5, weight: FontWeight.w700),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (u != null) BadgeChip(u.badge, compact: true),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'checked in • ${timeAgo(event.createdAt)}',
                        style: jakartaSans(size: 13, weight: FontWeight.w500, color: kMuted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.place_rounded, size: 20, color: kRed),
              ],
            ),
          ),
          _PhotoArea(photoUrl: event.photoUrl, place: event.place?.name ?? 'A place'),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, size: 17, color: kText),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    event.place?.name ?? 'A place',
                    style: jakartaSans(size: 14.5, weight: FontWeight.w700),
                  ),
                ),
                if (event.place?.category != null)
                  Text(
                    event.place!.category!,
                    style: jakartaSans(size: 12.5, weight: FontWeight.w600, color: kMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _challengeCard() {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kSoftGreen,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: kGreen, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: jakartaSans(size: 14.5, weight: FontWeight.w500, color: kText, height: 1.35),
                    children: [
                      TextSpan(
                        text: '@${event.creator?.username ?? 'someone'}',
                        style: jakartaSans(size: 14.5, weight: FontWeight.w700),
                      ),
                      const TextSpan(text: ' completed a challenge by '),
                      TextSpan(
                        text: '@${event.target?.username ?? 'a friend'}',
                        style: jakartaSans(size: 14.5, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded, size: 15, color: kMuted),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        event.place?.name ?? 'a place',
                        style: jakartaSans(size: 13, weight: FontWeight.w600, color: kMuted),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '• ${timeAgo(event.createdAt)}',
                      style: jakartaSans(size: 13, weight: FontWeight.w500, color: kMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Photo area (handles null / expired photos gracefully) ────────────────────
class _PhotoArea extends StatelessWidget {
  final String? photoUrl;
  final String place;
  const _PhotoArea({required this.photoUrl, required this.place});

  @override
  Widget build(BuildContext context) {
    if (photoUrl != null) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: Image.network(
          photoUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _placeholder('Photo unavailable'),
        ),
      );
    }
    return _placeholder('Photo expired');
  }

  Widget _placeholder(String label) {
    return AspectRatio(
      aspectRatio: 16 / 7,
      child: Container(
        color: kField,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 26, color: kMuted),
            const SizedBox(height: 6),
            Text(
              label,
              style: jakartaSans(size: 12.5, weight: FontWeight.w600, color: kMuted),
            ),
          ],
        ),
      ),
    );
  }
}
