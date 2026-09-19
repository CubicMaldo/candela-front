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
import '../services/auth_service.dart' show ApiException;
import 'widgets.dart';
import 'report_dialog.dart';

/// Shows a public or partial profile for another user per FRONTEND_GUIDE.md §7.2
/// Respects points privacy (only shown if ranking_opt_in = true) and handles
/// mutual blocking transparently (404 -> "Usuario no encontrado").
void showUserProfileSheet(BuildContext context, String username) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(radiusCard)),
    ),
    builder: (_) => _UserProfileSheet(username: username),
  );
}

class _UserProfileSheet extends StatefulWidget {
  final String username;
  const _UserProfileSheet({required this.username});

  @override
  State<_UserProfileSheet> createState() => _UserProfileSheetState();
}

class _UserProfileSheetState extends State<_UserProfileSheet> {
  late Future<PublicProfile> _profileFuture;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = UsersApi.getPublicProfile(widget.username);
  }

  Future<void> _toggleBlock(PublicProfile profile) async {
    final willBlock = !_blocked;
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog.adaptive(
        title: Text(willBlock ? 'Bloquear usuario' : 'Desbloquear usuario'),
        content: Text(
          willBlock
              ? '¿Seguro que quieres bloquear a @${profile.username}? Ya no podrán ver tu actividad ni interactuar.'
              : '¿Quieres desbloquear a @${profile.username}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: willBlock ? candelaDanger : candelaAmber,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(willBlock ? 'Bloquear' : 'Desbloquear'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    HapticFeedback.lightImpact();
    try {
      if (willBlock) {
        await UsersApi.blockUser(profile.userId);
        if (!mounted) return;
        setState(() => _blocked = true);
        showToast(context, '@${profile.username} ha sido bloqueado.');
      } else {
        await UsersApi.unblockUser(profile.userId);
        if (!mounted) return;
        setState(() => _blocked = false);
        showToast(context, '@${profile.username} ha sido desbloqueado.');
      }
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  void _openReport(PublicProfile profile) {
    showReportDialog(
      context,
      targetType: 'USER',
      targetId: profile.userId,
      targetName: profile.username,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          spacingScreen,
          10,
          spacingScreen,
          24,
        ),
        child: FutureBuilder<PublicProfile>(
          future: _profileFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: CandelaLoader.centered(),
              );
            }
            if (snap.hasError) {
              // 404 or error handling per FRONTEND_GUIDE.md §7.2 / §7.4:
              // Never reveal whether a 404 is due to private profile or a block.
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_off_outlined,
                        size: 36,
                        color: textDarkSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Usuario no encontrado',
                        style: textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'El perfil no está disponible.',
                        style: textTheme.bodySmall?.copyWith(
                          color: secondaryOn(context),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final p = snap.data!;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    UserAvatar(username: p.username, size: 72),
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert_rounded,
                        color: secondaryOn(context),
                      ),
                      onSelected: (action) {
                        if (action == 'report') _openReport(p);
                        if (action == 'block') _toggleBlock(p);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'report',
                          child: Row(
                            children: const [
                              Icon(Icons.flag_outlined, size: 18),
                              SizedBox(width: 10),
                              Text('Denunciar usuario'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'block',
                          child: Row(
                            children: [
                              Icon(
                                _blocked
                                    ? Icons.lock_open_rounded
                                    : Icons.block_rounded,
                                size: 18,
                                color: _blocked ? null : candelaDanger,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _blocked
                                    ? 'Desbloquear usuario'
                                    : 'Bloquear usuario',
                                style: TextStyle(
                                  color: _blocked ? null : candelaDanger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('@${p.username}', style: textTheme.titleMedium),
                const SizedBox(height: 6),
                BadgeChip(p.badgeLevel),
                const SizedBox(height: 20),

                // Stats: Check-ins, Streak, Points (if opted in)
                Row(
                  children: [
                    Expanded(
                      child: _ProfileStat(
                        value: '${p.checkInCount}',
                        label: 'Check-ins',
                      ),
                    ),
                    Expanded(
                      child: _ProfileStat(
                        value: '${p.streakWeeksCurrent}',
                        label: 'Sem. racha',
                      ),
                    ),
                    if (p.pointsTotal != null)
                      Expanded(
                        child: _ProfileStat(
                          value: '${p.pointsTotal}',
                          label: 'Puntos',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  const _ProfileStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(value, style: textTheme.titleSmall),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: secondaryOn(context)),
        ),
      ],
    );
  }
}

