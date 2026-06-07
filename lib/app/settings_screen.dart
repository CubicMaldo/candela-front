import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../auth/welcome_screen.dart';
import 'widgets.dart';

class SettingsScreen extends StatefulWidget {
  final MyProfile profile;
  const SettingsScreen({required this.profile, super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late PrivacyMode _privacy;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _privacy = widget.profile.privacy;
  }

  Future<void> _setPrivacy(PrivacyMode mode) async {
    // Guard: protected accounts cannot go PUBLIC (FRONTEND_GUIDE §5).
    if (mode == PrivacyMode.public && widget.profile.isProtected) {
      showToast(context, 'Protected accounts cannot be public.');
      return;
    }
    final previous = _privacy;
    setState(() {
      _privacy = mode;
      _saving = true;
    });
    try {
      await ApiService.updatePrivacy(mode);
      if (mounted) showToast(context, 'Privacy updated to ${mode.label}');
    } on ApiException catch (e) {
      setState(() => _privacy = previous);
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await TokenStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: kField, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.chevron_left_rounded, size: 26, color: kText),
                  ),
                ),
                const SizedBox(width: 14),
                Text('Settings',
                    style: jakartaSans(
                        size: 24, weight: FontWeight.w800, letterSpacing: -0.03 * 24)),
              ],
            ),
            const SizedBox(height: 24),

            // ── Account summary ──────────────────────────────────────────────
            AppCard(
              child: Row(
                children: [
                  UserAvatar(username: widget.profile.username, size: 50),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('@${widget.profile.username}',
                            style: jakartaSans(size: 16, weight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(widget.profile.email ?? 'No email on file',
                            style: jakartaSans(
                                size: 13, weight: FontWeight.w500, color: kMuted)),
                      ],
                    ),
                  ),
                  if (widget.profile.isProtected)
                    Icon(Icons.shield_rounded, color: kGreen, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 26),

            Text('Privacy',
                style: jakartaSans(size: 14, weight: FontWeight.w700, color: kMuted)),
            const SizedBox(height: 4),
            Text('Control who can see your profile and ranking.',
                style: jakartaSans(size: 13, weight: FontWeight.w500, color: kMuted)),
            const SizedBox(height: 14),
            ...PrivacyMode.values.map((m) {
              final disabled = m == PrivacyMode.public && widget.profile.isProtected;
              final selected = m == _privacy;
              return _PrivacyOption(
                mode: m,
                selected: selected,
                disabled: disabled,
                onTap: _saving || disabled ? null : () => _setPrivacy(m),
              );
            }),

            const SizedBox(height: 28),
            Text('Account',
                style: jakartaSans(size: 14, weight: FontWeight.w700, color: kMuted)),
            const SizedBox(height: 14),
            _ActionRow(
              icon: Icons.logout_rounded,
              label: 'Log out',
              color: kText,
              onTap: _logout,
            ),
            const SizedBox(height: 10),
            _ActionRow(
              icon: Icons.delete_outline_rounded,
              label: 'Delete account',
              color: kRed,
              onTap: () => showToast(context, 'Account deletion coming soon.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrivacyOption extends StatelessWidget {
  final PrivacyMode mode;
  final bool selected;
  final bool disabled;
  final VoidCallback? onTap;

  const _PrivacyOption({
    required this.mode,
    required this.selected,
    required this.disabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? kSoftRed : kBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: selected ? kRed : kBorder, width: selected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(
                switch (mode) {
                  PrivacyMode.public => Icons.public_rounded,
                  PrivacyMode.friends => Icons.group_rounded,
                  PrivacyMode.private => Icons.lock_rounded,
                },
                size: 22,
                color: selected ? kRed : kMuted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(mode.label,
                            style: jakartaSans(size: 15, weight: FontWeight.w700)),
                        if (disabled) ...[
                          const SizedBox(width: 8),
                          Text('(protected)',
                              style: jakartaSans(
                                  size: 12, weight: FontWeight.w600, color: kMuted)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(mode.blurb,
                        style: jakartaSans(
                            size: 12.5, weight: FontWeight.w500, color: kMuted)),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: kField,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(label,
                style: jakartaSans(size: 15, weight: FontWeight.w700, color: color)),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 20, color: kMuted),
          ],
        ),
      ),
    );
  }
}
