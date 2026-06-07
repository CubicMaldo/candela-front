import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import 'widgets.dart';
import 'settings_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  late Future<MyProfile> _profile;
  late Future<List<CheckIn>> _checkIns;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _profile = ApiService.me();
    _checkIns = ApiService.myCheckIns();
  }

  Future<void> _refresh() async {
    setState(_load);
    await _profile;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: kRed,
        onRefresh: _refresh,
        child: AsyncView<MyProfile>(
          future: _profile,
          errorTitle: 'Could not load profile',
          builder: (p) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SettingsScreen(profile: p),
                        ),
                      );
                      if (mounted) setState(_load);
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                          color: kField, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.settings_outlined, size: 21, color: kText),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Center(
                child: Column(
                  children: [
                    UserAvatar(username: p.username, size: 96, imageUrl: p.avatarUrl),
                    const SizedBox(height: 14),
                    Text('@${p.username}',
                        style: jakartaSans(
                            size: 24, weight: FontWeight.w800, letterSpacing: -0.03 * 24)),
                    const SizedBox(height: 8),
                    BadgeChip(p.badge),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _PointsBanner(points: p.pointsTotal, badge: p.badge),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _StatTile(value: p.checkInCount, label: 'Check-ins', icon: Icons.place_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatTile(value: p.friendsCount, label: 'Friends', icon: Icons.group_rounded)),
                  const SizedBox(width: 12),
                  Expanded(child: _StatTile(value: p.completedChallengesCount, label: 'Challenges', icon: Icons.emoji_events_rounded)),
                ],
              ),
              const SizedBox(height: 26),
              Text('Recent check-ins',
                  style: jakartaSans(size: 18, weight: FontWeight.w800, letterSpacing: -0.02 * 18)),
              const SizedBox(height: 12),
              AsyncView<List<CheckIn>>(
                future: _checkIns,
                errorTitle: 'Could not load history',
                builder: (checkIns) {
                  if (checkIns.isEmpty) {
                    return const EmptyState(
                      icon: Icons.photo_camera_outlined,
                      title: 'No check-ins yet',
                      message: 'Tap the camera button to make your first one.',
                    );
                  }
                  return Column(
                    children: checkIns
                        .map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _CheckInRow(c),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Points banner ────────────────────────────────────────────────────────────
class _PointsBanner extends StatelessWidget {
  final int points;
  final BadgeLevel badge;
  const _PointsBanner({required this.points, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [kRed, kGreen],
        ),
        boxShadow: [
          BoxShadow(
            color: kRed.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -8,
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total points',
                  style: jakartaSans(
                      size: 13,
                      weight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85))),
              const SizedBox(height: 4),
              Text('$points',
                  style: jakartaSans(
                      size: 34, weight: FontWeight.w800, color: Colors.white)),
            ],
          ),
          const Spacer(),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}

// ─── Stat tile ────────────────────────────────────────────────────────────────
class _StatTile extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  const _StatTile({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: kField,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: kMuted),
          const SizedBox(height: 8),
          Text('$value',
              style: jakartaSans(size: 20, weight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(label,
              style: jakartaSans(size: 11.5, weight: FontWeight.w600, color: kMuted)),
        ],
      ),
    );
  }
}

// ─── Check-in history row ─────────────────────────────────────────────────────
class _CheckInRow extends StatelessWidget {
  final CheckIn checkIn;
  const _CheckInRow(this.checkIn);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: kField,
              borderRadius: BorderRadius.circular(12),
              image: checkIn.photoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(checkIn.photoUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: checkIn.photoUrl != null
                ? null
                : Icon(Icons.place_rounded, size: 22, color: kMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(checkIn.placeName,
                    style: jakartaSans(size: 14.5, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(timeAgo(checkIn.createdAt),
                    style: jakartaSans(size: 12.5, weight: FontWeight.w500, color: kMuted)),
              ],
            ),
          ),
          PointsPill(checkIn.pointsAwarded, large: true),
        ],
      ),
    );
  }
}
