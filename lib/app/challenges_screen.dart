import 'dart:async';
import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../auth/widgets.dart' show SegToggle, PrimaryButton;
import 'widgets.dart';

class ChallengesScreen extends StatefulWidget {
  final UserRef? prefillFriend;
  const ChallengesScreen({this.prefillFriend, super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  String _tab = 'Active';
  late Future<List<Challenge>> _active;
  late Future<List<Challenge>> _incoming;

  @override
  void initState() {
    super.initState();
    _reload();
    if (widget.prefillFriend != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _openCreate(widget.prefillFriend));
    }
  }

  void _reload() {
    _active = ApiService.activeChallenges();
    _incoming = ApiService.incomingChallenges();
  }

  Future<void> _accept(Challenge c) async {
    try {
      await ApiService.acceptChallenge(c.id);
      if (!mounted) return;
      showToast(context, 'Challenge accepted — the clock is ticking!');
      setState(_reload);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  Future<void> _reject(Challenge c) async {
    try {
      await ApiService.rejectChallenge(c.id);
      if (!mounted) return;
      setState(_reload);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  Future<void> _openCreate([UserRef? friend]) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateChallengeSheet(friend: friend),
    );
    if (created == true && mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kField,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.chevron_left_rounded, size: 26, color: kText),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Challenges',
                    style: jakartaSans(
                      size: 24,
                      weight: FontWeight.w800,
                      letterSpacing: -0.03 * 24,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _openCreate(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kRed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_rounded, size: 24, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SegToggle(
                options: const ['Active', 'Invites'],
                active: _tab,
                onChanged: (v) => setState(() => _tab = v),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _tab == 'Active' ? _buildActive() : _buildIncoming(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActive() {
    return AsyncView<List<Challenge>>(
      future: _active,
      errorTitle: 'Could not load challenges',
      builder: (list) {
        if (list.isEmpty) {
          return EmptyState(
            icon: Icons.emoji_events_outlined,
            title: 'No active challenges',
            message: 'Challenge a friend to meet you at a place before the clock runs out.',
            action: PillButton(label: 'New challenge', icon: Icons.add_rounded, onTap: _openCreate),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) => _ActiveChallengeCard(list[i]),
        );
      },
    );
  }

  Widget _buildIncoming() {
    return AsyncView<List<Challenge>>(
      future: _incoming,
      errorTitle: 'Could not load invites',
      builder: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.mail_outline_rounded,
            title: 'No invites',
            message: 'Challenge invitations from friends will appear here.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
          itemCount: list.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final c = list[i];
            return AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      UserAvatar(username: c.creator?.username ?? '?', size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('@${c.creator?.username ?? 'someone'} challenged you',
                                style: jakartaSans(size: 14.5, weight: FontWeight.w700)),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.location_on_rounded, size: 14, color: kMuted),
                                const SizedBox(width: 3),
                                Flexible(
                                  child: Text(c.place?.name ?? 'a place',
                                      style: jakartaSans(size: 13, weight: FontWeight.w600, color: kMuted)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (c.timeLeft != null) ...[
                    const SizedBox(height: 10),
                    GamificationChipLike(text: countdownLabel(c.timeLeft!)),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _reject(c),
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: kField,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Text('Decline',
                                style: jakartaSans(size: 14.5, weight: FontWeight.w700, color: kText)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _accept(c),
                          child: Container(
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: kGreen,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Text('Accept',
                                style: jakartaSans(size: 14.5, weight: FontWeight.w700, color: Colors.white)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Active challenge card with live countdown ────────────────────────────────
class _ActiveChallengeCard extends StatefulWidget {
  final Challenge challenge;
  const _ActiveChallengeCard(this.challenge);

  @override
  State<_ActiveChallengeCard> createState() => _ActiveChallengeCardState();
}

class _ActiveChallengeCardState extends State<_ActiveChallengeCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;
    final iAmCreator = c.role == 'creator';
    final other = iAmCreator ? c.target : c.creator;
    final left = c.timeLeft;
    final urgent = left != null && left.inHours < 6;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(username: other?.username ?? '?', size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      iAmCreator
                          ? 'You challenged @${other?.username ?? 'a friend'}'
                          : '@${other?.username ?? 'a friend'} vs you',
                      style: jakartaSans(size: 14.5, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_rounded, size: 14, color: kMuted),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(c.place?.name ?? 'a place',
                              style: jakartaSans(size: 13, weight: FontWeight.w600, color: kMuted)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: urgent ? kSoftRed : kSoftGreen,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 14, color: urgent ? kRed : kGreen),
                    const SizedBox(width: 4),
                    Text(
                      left == null ? '—' : countdownLabel(left),
                      style: jakartaSans(
                        size: 12.5,
                        weight: FontWeight.w700,
                        color: urgent ? kRed : kGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kField,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: kMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Check in at this place before the timer ends to complete the challenge.',
                    style: jakartaSans(size: 12.5, weight: FontWeight.w500, color: kMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable little chip ─────────────────────────────────────────────────────
class GamificationChipLike extends StatelessWidget {
  final String text;
  const GamificationChipLike({required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(color: kSoftRed, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: kRed),
          const SizedBox(width: 6),
          Text(text, style: jakartaSans(size: 12.5, weight: FontWeight.w700, color: kRed)),
        ],
      ),
    );
  }
}

// ─── Create challenge bottom sheet ────────────────────────────────────────────
class _CreateChallengeSheet extends StatefulWidget {
  final UserRef? friend;
  const _CreateChallengeSheet({this.friend});

  @override
  State<_CreateChallengeSheet> createState() => _CreateChallengeSheetState();
}

class _CreateChallengeSheetState extends State<_CreateChallengeSheet> {
  UserRef? _friend;
  Place? _place;
  int _hours = 24;
  bool _loading = false;

  late Future<List<UserRef>> _friends;
  late Future<List<Place>> _places;

  @override
  void initState() {
    super.initState();
    _friend = widget.friend;
    _friends = ApiService.friends();
    _places = ApiService.nearbyPlaces();
  }

  bool get _canSubmit => _friend != null && _place != null && !_loading;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _loading = true);
    try {
      await ApiService.createChallenge(
        targetUserId: _friend!.id,
        placeId: _place!.id,
        deadlineHours: _hours,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      showToast(context, 'Challenge sent to @${_friend!.username}');
    } on ApiException catch (e) {
      setState(() => _loading = false);
      if (mounted) showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: kBorder, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Text('New challenge',
              style: jakartaSans(size: 22, weight: FontWeight.w800, letterSpacing: -0.03 * 22)),
          const SizedBox(height: 4),
          Text('Dare a friend to meet you at a place.',
              style: jakartaSans(size: 14, weight: FontWeight.w500, color: kMuted)),
          const SizedBox(height: 20),

          _label('Challenge a friend'),
          const SizedBox(height: 8),
          FutureBuilder<List<UserRef>>(
            future: _friends,
            builder: (context, snap) {
              final friends = snap.data ?? [];
              return SizedBox(
                height: 84,
                child: friends.isEmpty
                    ? Center(child: Text('No friends to challenge yet',
                        style: jakartaSans(size: 13, color: kMuted)))
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: friends.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 14),
                        itemBuilder: (_, i) {
                          final f = friends[i];
                          final sel = f.id == _friend?.id;
                          return GestureDetector(
                            onTap: () => setState(() => _friend = f),
                            child: Column(
                              children: [
                                Stack(
                                  children: [
                                    UserAvatar(username: f.username, size: 52),
                                    if (sel)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: kGreen,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: kBg, width: 2),
                                          ),
                                          child: const Icon(Icons.check_rounded,
                                              size: 12, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                SizedBox(
                                  width: 56,
                                  child: Text('@${f.username}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: jakartaSans(
                                        size: 11.5,
                                        weight: sel ? FontWeight.w700 : FontWeight.w500,
                                        color: sel ? kText : kMuted,
                                      )),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              );
            },
          ),
          const SizedBox(height: 18),

          _label('At which place'),
          const SizedBox(height: 8),
          FutureBuilder<List<Place>>(
            future: _places,
            builder: (context, snap) {
              final places = snap.data ?? [];
              return Column(
                children: places.take(4).map((p) {
                  final sel = p.id == _place?.id;
                  return GestureDetector(
                    onTap: () => setState(() => _place = p),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? kSoftRed : kField,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: sel ? kRed : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.place_rounded, size: 19, color: sel ? kRed : kMuted),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(p.name,
                                style: jakartaSans(size: 14.5, weight: FontWeight.w600)),
                          ),
                          if (p.distanceLabel != null)
                            Text(p.distanceLabel!,
                                style: jakartaSans(size: 12.5, weight: FontWeight.w600, color: kMuted)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 10),

          _label('Deadline'),
          const SizedBox(height: 8),
          Row(
            children: [24, 48, 72].map((h) {
              final sel = h == _hours;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _hours = h),
                  child: Container(
                    margin: EdgeInsets.only(right: h != 72 ? 10 : 0),
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: sel ? kText : kField,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text('${h}h',
                        style: jakartaSans(
                          size: 15,
                          weight: FontWeight.w700,
                          color: sel ? Colors.white : kText,
                        )),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'Send challenge',
            color: _canSubmit ? kRed : const Color(0xFFCBCDCA),
            loading: _loading,
            onTap: _canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t,
      style: jakartaSans(size: 13, weight: FontWeight.w700, color: kMuted));
}
