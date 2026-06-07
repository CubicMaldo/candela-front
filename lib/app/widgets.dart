import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';

// ─── Deterministic avatar colour from a username ──────────────────────────────
const _avatarPalette = [
  Color(0xFFF2B705),
  Color(0xFFE86A5C),
  Color(0xFF5C9CE8),
  Color(0xFF7FB069),
  Color(0xFFB07FD0),
  Color(0xFF53B6A8),
];

Color avatarColor(String seed) {
  if (seed.isEmpty) return _avatarPalette.first;
  final code = seed.codeUnits.fold<int>(0, (a, b) => a + b);
  return _avatarPalette[code % _avatarPalette.length];
}

// ─── Circular initials avatar ─────────────────────────────────────────────────
class UserAvatar extends StatelessWidget {
  final String username;
  final double size;
  final String? imageUrl;
  final bool ring;

  const UserAvatar({
    required this.username,
    this.size = 44,
    this.imageUrl,
    this.ring = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final initial =
        username.isNotEmpty ? username.characters.first.toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatarColor(username),
        border: ring ? Border.all(color: kBg, width: 2.5) : null,
        image: imageUrl != null
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: imageUrl != null
          ? null
          : Text(
              initial,
              style: jakartaSans(
                size: size * 0.40,
                weight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
    );
  }
}

// ─── Badge level pill ─────────────────────────────────────────────────────────
class BadgeChip extends StatelessWidget {
  final BadgeLevel badge;
  final bool compact;

  const BadgeChip(this.badge, {this.compact = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 5),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 7,
            height: compact ? 6 : 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: badge.color),
          ),
          SizedBox(width: compact ? 5 : 6),
          Text(
            badge.label,
            style: jakartaSans(
              size: compact ? 11 : 12.5,
              weight: FontWeight.w700,
              color: badge.color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Points pill (spark + number) ─────────────────────────────────────────────
class PointsPill extends StatelessWidget {
  final int points;
  final bool large;
  const PointsPill(this.points, {this.large = false, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.bolt_rounded, size: large ? 18 : 15, color: kGreen),
        const SizedBox(width: 2),
        Text(
          '$points',
          style: jakartaSans(
            size: large ? 16 : 14,
            weight: FontWeight.w800,
            color: kText,
          ),
        ),
      ],
    );
  }
}

// ─── Card container ───────────────────────────────────────────────────────────
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

// ─── Screen title header ──────────────────────────────────────────────────────
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const ScreenHeader({required this.title, this.subtitle, this.trailing, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: jakartaSans(
                  size: 28,
                  weight: FontWeight.w800,
                  letterSpacing: -0.03 * 28,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: jakartaSans(size: 14, weight: FontWeight.w500, color: kMuted),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

// ─── Empty / error states ─────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Widget? action;
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kField,
              ),
              child: Icon(icon, size: 32, color: kMuted),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: jakartaSans(size: 18, weight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: jakartaSans(size: 14, weight: FontWeight.w500, color: kMuted),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

// ─── Async loader: FutureBuilder with loading / error / data ──────────────────
class AsyncView<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) builder;
  final String errorTitle;
  const AsyncView({
    required this.future,
    required this.builder,
    this.errorTitle = 'Could not load',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: kRed, strokeWidth: 2.5),
            ),
          );
        }
        if (snap.hasError) {
          return EmptyState(
            icon: Icons.cloud_off_rounded,
            title: errorTitle,
            message: snap.error.toString(),
          );
        }
        return builder(snap.data as T);
      },
    );
  }
}

// ─── Small pill button (secondary action) ─────────────────────────────────────
class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final bool filled;
  final IconData? icon;

  const PillButton({
    required this.label,
    this.onTap,
    this.color = kRed,
    this.filled = true,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: filled ? null : Border.all(color: kBorder, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: filled ? Colors.white : kText),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: jakartaSans(
                size: 13.5,
                weight: FontWeight.w700,
                color: filled ? Colors.white : kText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Toast helper ─────────────────────────────────────────────────────────────
void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: jakartaSans(size: 14, weight: FontWeight.w600, color: Colors.white),
      ),
      backgroundColor: kText,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}
