import 'package:flutter/material.dart';
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
import 'settings_screen.dart';
import 'friends_screen.dart';
import 'history_screen.dart';

part 'profile_widgets.dart';

/// Own profile — privacy-first by design. Points are collapsed and rankings
/// are opt-in; the weekly streak is the one number we celebrate by default.
class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  late Future<User> _profile;
  late Future<List<MyCheckIn>> _recent;
  bool _pointsExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _profile = UsersApi.getMyProfile();
    _recent = CheckInApi.getMyCheckIns(limit: 5);
  }

  Future<void> _refresh() async {
    setState(_load);
    await _profile;
  }

  Future<void> _openSettings(User profile) async {
    await Navigator.push(
      context,
      SlideRightRoute(builder: (_) => SettingsScreen(profile: profile)),
    );
    if (mounted) setState(_load);
  }

  Future<void> _optIntoRankings() async {
    try {
      await UsersApi.updateRankingOptIn(true);
      if (mounted) setState(_load);
    } catch (_) {
      if (mounted) showToast(context, 'No se pudo activar los rankings.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: candelaAmber,
        onRefresh: _refresh,
        child: AsyncView<User>(
          future: _profile,
          errorTitle: 'No se pudo cargar tu perfil',
          onRetry: _refresh,
          loading: const _ProfileSkeleton(),
          builder: (p) => ListView(
            padding: EdgeInsets.fromLTRB(
              spacingScreen,
              8,
              spacingScreen,
              bottomListGap(context),
            ),
            children: [
              ScreenHeader(
                title: 'Perfil',
                padded: false,
                trailing: SquareIconButton(
                  icon: Icons.settings_outlined,
                  onTap: () => _openSettings(p),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    UserAvatar(username: p.username, size: 96),
                    const SizedBox(height: 14),
                    Text('@${p.username}', style: textTheme.titleMedium),
                    const SizedBox(height: 8),
                    BadgeChip(p.badgeLevel),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatItem(value: p.checkInCount, label: 'Check-ins'),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        SlideRightRoute(builder: (_) => const FriendsScreen()),
                      ),
                      child: _StatItem(value: p.friendsCount, label: 'Amigos'),
                    ),
                  ),
                  Expanded(
                    child: _StatItem(
                      value: p.completedPlansCount,
                      label: 'Planes concretados',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: spacingCardGap),
              _StreakCard(
                weeks: p.streakWeeksCurrent,
                weekCheckins: p.streakWeekCheckins,
              ),
              const SizedBox(height: spacingCardGap),
              _PointsSection(
                expanded: _pointsExpanded,
                pointsTotal: p.pointsTotal,
                pointsSeason: p.pointsSeason,
                onToggle: () =>
                    setState(() => _pointsExpanded = !_pointsExpanded),
              ),
              const SizedBox(height: spacingCardGap),
              _RankingsSection(
                optedIn: p.rankingOptIn,
                onOptIn: _optIntoRankings,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Check-ins recientes', style: textTheme.titleSmall),
                  TextButton(
                    style: TextButton.styleFrom(foregroundColor: candelaAmber),
                    onPressed: () => Navigator.push(
                      context,
                      SlideRightRoute(
                        builder: (_) => CheckInHistoryScreen(profile: p),
                      ),
                    ),
                    child: const Text('Ver historial'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _RecentCheckIns(future: _recent),
            ],
          ),
        ),
      ),
    );
  }
}
