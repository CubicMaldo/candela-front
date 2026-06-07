import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../auth/widgets.dart' show SegToggle;
import 'widgets.dart';
import 'challenges_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  String _tab = 'Friends';
  late Future<List<UserRef>> _friends;
  late Future<List<FriendRequest>> _requests;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _friends = ApiService.friends();
    _requests = ApiService.incomingRequests();
  }

  Future<void> _accept(FriendRequest r) async {
    try {
      await ApiService.acceptRequest(r.user.id);
      if (!mounted) return;
      showToast(context, 'You and @${r.user.username} are now friends');
      setState(_reload);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  Future<void> _reject(FriendRequest r) async {
    try {
      await ApiService.rejectRequest(r.user.id);
      if (!mounted) return;
      setState(_reload);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: ScreenHeader(
              title: 'Friends',
              subtitle: 'Your circle',
              trailing: _IconBtn(
                icon: Icons.emoji_events_outlined,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChallengesScreen()),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FutureBuilder<List<FriendRequest>>(
              future: _requests,
              builder: (context, snap) {
                final n = snap.data?.length ?? 0;
                return SegToggle(
                  options: ['Friends', n > 0 ? 'Requests ($n)' : 'Requests'],
                  active: _tab.startsWith('Requests')
                      ? (n > 0 ? 'Requests ($n)' : 'Requests')
                      : 'Friends',
                  onChanged: (v) => setState(() => _tab = v),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _tab == 'Friends'
                ? _buildFriends()
                : _buildRequests(),
          ),
        ],
      ),
    );
  }

  Widget _buildFriends() {
    return AsyncView<List<UserRef>>(
      future: _friends,
      errorTitle: 'Could not load friends',
      builder: (friends) {
        if (friends.isEmpty) {
          return const EmptyState(
            icon: Icons.group_outlined,
            title: 'No friends yet',
            message: 'Find people and send a friend request to build your circle.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: friends.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _FriendRow(friends[i]),
        );
      },
    );
  }

  Widget _buildRequests() {
    return AsyncView<List<FriendRequest>>(
      future: _requests,
      errorTitle: 'Could not load requests',
      builder: (requests) {
        if (requests.isEmpty) {
          return const EmptyState(
            icon: Icons.mark_email_read_outlined,
            title: 'No pending requests',
            message: "When someone wants to be friends, you'll see them here.",
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r = requests[i];
            return AppCard(
              child: Row(
                children: [
                  UserAvatar(username: r.user.username, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('@${r.user.username}',
                            style: jakartaSans(size: 15, weight: FontWeight.w700)),
                        const SizedBox(height: 3),
                        BadgeChip(r.user.badge, compact: true),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _reject(r),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: kField,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.close_rounded, size: 19, color: kMuted),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _accept(r),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: kGreen,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.check_rounded, size: 19, color: Colors.white),
                    ),
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

class _FriendRow extends StatelessWidget {
  final UserRef friend;
  const _FriendRow(this.friend);

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          UserAvatar(username: friend.username, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${friend.username}',
                    style: jakartaSans(size: 15, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                BadgeChip(friend.badge, compact: true),
              ],
            ),
          ),
          PillButton(
            label: 'Challenge',
            icon: Icons.emoji_events_rounded,
            filled: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChallengesScreen(prefillFriend: friend),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: kField, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, size: 21, color: kText),
      ),
    );
  }
}
