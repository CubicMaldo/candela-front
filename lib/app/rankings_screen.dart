import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../auth/widgets.dart' show SegToggle;
import 'widgets.dart';

class RankingsScreen extends StatefulWidget {
  const RankingsScreen({super.key});

  @override
  State<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends State<RankingsScreen> {
  String _mode = 'Global';
  String? _meId;

  late Future<(List<RankingEntry>, int?)> _global;
  late Future<List<RankingEntry>> _friends;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _global = ApiService.me().then((p) {
      _meId = p.id;
      return ApiService.globalRanking(_meId);
    });
    _friends = ApiService.me().then((p) {
      _meId = p.id;
      return ApiService.friendsRanking(_meId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: const ScreenHeader(
              title: 'Rankings',
              subtitle: 'See where you stand',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SegToggle(
              options: const ['Global', 'Friends'],
              active: _mode,
              onChanged: (v) => setState(() => _mode = v),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _mode == 'Global'
                ? AsyncView<(List<RankingEntry>, int?)>(
                    future: _global,
                    errorTitle: 'Could not load ranking',
                    builder: (data) => _RankingList(
                      entries: data.$1,
                      myRank: data.$2,
                      note: 'Global ranking shows public profiles only.',
                    ),
                  )
                : AsyncView<List<RankingEntry>>(
                    future: _friends,
                    errorTitle: 'Could not load ranking',
                    builder: (entries) => _RankingList(
                      entries: entries,
                      myRank: null,
                      note: 'You and your friends, ranked by points.',
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  final List<RankingEntry> entries;
  final int? myRank;
  final String note;
  const _RankingList({required this.entries, this.myRank, required this.note});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const EmptyState(
        icon: Icons.leaderboard_rounded,
        title: 'No ranking yet',
        message: 'Earn points by checking in to climb the board.',
      );
    }

    final podium = entries.take(3).toList();
    final rest = entries.skip(3).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            children: [
              _Podium(podium),
              const SizedBox(height: 18),
              ...rest.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RankRow(e),
                  )),
              const SizedBox(height: 8),
              Text(
                note,
                style: jakartaSans(size: 12.5, weight: FontWeight.w500, color: kMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        if (myRank != null && !entries.any((e) => e.isMe))
          _MyRankPin(rank: myRank!),
      ],
    );
  }
}

// ─── Podium (top 3) ───────────────────────────────────────────────────────────
class _Podium extends StatelessWidget {
  final List<RankingEntry> top;
  const _Podium(this.top);

  @override
  Widget build(BuildContext context) {
    RankingEntry? at(int i) => i < top.length ? top[i] : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _Pillar(entry: at(1), height: 96, place: 2)),
        const SizedBox(width: 10),
        Expanded(child: _Pillar(entry: at(0), height: 124, place: 1)),
        const SizedBox(width: 10),
        Expanded(child: _Pillar(entry: at(2), height: 78, place: 3)),
      ],
    );
  }
}

class _Pillar extends StatelessWidget {
  final RankingEntry? entry;
  final double height;
  final int place;
  const _Pillar({required this.entry, required this.height, required this.place});

  static const _medal = {1: Color(0xFFF2B705), 2: Color(0xFFB8BCC2), 3: Color(0xFFCD9B6A)};

  @override
  Widget build(BuildContext context) {
    if (entry == null) return const SizedBox.shrink();
    final color = _medal[place]!;
    return Column(
      children: [
        UserAvatar(username: entry!.user.username, size: place == 1 ? 60 : 50),
        const SizedBox(height: 6),
        Text(
          '@${entry!.user.username}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: jakartaSans(size: 13, weight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        PointsPill(entry!.pointsTotal),
        const SizedBox(height: 8),
        Container(
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.10)],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
          ),
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            '$place',
            style: jakartaSans(size: 24, weight: FontWeight.w800, color: color),
          ),
        ),
      ],
    );
  }
}

// ─── Standard rank row ────────────────────────────────────────────────────────
class _RankRow extends StatelessWidget {
  final RankingEntry e;
  const _RankRow(this.e);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: e.isMe ? kSoftRed : kBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: e.isMe ? kRed.withValues(alpha: 0.3) : kBorder, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '${e.rank}',
              style: jakartaSans(size: 15, weight: FontWeight.w800, color: kMuted),
            ),
          ),
          const SizedBox(width: 6),
          UserAvatar(username: e.user.username, size: 38),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.isMe ? 'You' : '@${e.user.username}',
                  style: jakartaSans(size: 14.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                BadgeChip(e.user.badge, compact: true),
              ],
            ),
          ),
          PointsPill(e.pointsTotal, large: true),
        ],
      ),
    );
  }
}

// ─── Pinned "your rank" footer (when outside the visible list) ────────────────
class _MyRankPin extends StatelessWidget {
  final int rank;
  const _MyRankPin({required this.rank});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 90),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: kText,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Text(
            'Your position',
            style: jakartaSans(size: 14, weight: FontWeight.w600, color: Colors.white),
          ),
          const Spacer(),
          Text(
            '#$rank',
            style: jakartaSans(size: 18, weight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
