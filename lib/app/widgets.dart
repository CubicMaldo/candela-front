import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import '../theme.dart';
import '../models.dart';

// ─── Shared loading spinner ───────────────────────────────────────────────────
/// The single amber spinner used across the app. Use [CandelaLoader.centered]
/// to drop it into the middle of a screen or sheet.
class CandelaLoader extends StatelessWidget {
  const CandelaLoader({
    super.key,
    this.size,
    this.color,
    this.strokeWidth = 2.5,
  });

  /// A loader centered with comfortable padding — the common full-area case.
  const CandelaLoader.centered({super.key})
    : size = null,
      color = null,
      strokeWidth = 2.5;

  final double? size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final indicator = CircularProgressIndicator(
      color: color ?? candelaAmber,
      strokeWidth: strokeWidth,
    );
    final sized = size == null
        ? indicator
        : SizedBox(width: size, height: size, child: indicator);
    return Center(
      child: Padding(padding: const EdgeInsets.all(40), child: sized),
    );
  }
}

// ─── Skeleton loading placeholders ────────────────────────────────────────────
/// Wraps skeleton placeholders with a subtle pulsing animation. Build the
/// child out of [SkeletonBox]es that mirror the target layout.
class Skeleton extends StatefulWidget {
  final Widget child;
  const Skeleton({required this.child, super.key});

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(
        begin: 0.45,
        end: 0.9,
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut)),
      child: widget.child,
    );
  }
}

/// A single grey block used to compose [Skeleton] layouts.
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final bool circle;
  const SkeletonBox({
    this.width,
    this.height = 14,
    this.radius = radiusMedium,
    this.circle = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.10);
    return Container(
      width: circle ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: base,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Skeleton for a list of cards (plans, friends, nearby places).
class ListSkeleton extends StatelessWidget {
  final int items;
  const ListSkeleton({this.items = 5, super.key});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          spacingScreen,
          16,
          spacingScreen,
          16,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items,
        separatorBuilder: (_, _) => const SizedBox(height: spacingCardGap),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(spacingCard),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(radiusCard),
          ),
          child: Row(
            children: [
              const SkeletonBox(height: 44, circle: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 140),
                    SizedBox(height: 8),
                    SkeletonBox(width: 90, height: 11),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for the full-width photo feed.
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: SkeletonBox(
                height: double.infinity,
                radius: 0,
                width: double.infinity,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
    final initial = username.isNotEmpty
        ? username.characters.first.toUpperCase()
        : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: avatarColor(username),
        border: ring
            ? Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 2.5,
              )
            : null,
        image: imageUrl != null
            ? DecorationImage(image: CachedNetworkImageProvider(imageUrl!), fit: BoxFit.cover)
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
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: candelaAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 6 : 7,
            height: compact ? 6 : 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: candelaAmber,
            ),
          ),
          SizedBox(width: compact ? 5 : 6),
          Text(
            badge.label,
            style: jakartaSans(
              size: compact ? 11 : 12.5,
              weight: FontWeight.w700,
              color: candelaAmber,
            ),
          ),
        ],
      ),
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
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(radiusCard),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.11),
          width: 1,
        ),
        boxShadow: isDark
            ? null
            : [
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
/// iOS-style large-title header: optional back chevron, a big bold title (and
/// optional subtitle), and an optional trailing action. `padded` wraps it with
/// the standard screen margins so callers can drop it straight into a column.
class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showBack;
  final bool padded;
  const ScreenHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.showBack = false,
    this.padded = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showBack) ...[const CandelaBackButton(), const SizedBox(width: 12)],
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
                  color: onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: jakartaSans(
                    size: 14,
                    weight: FontWeight.w500,
                    color: secondaryOn(context),
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
    if (!padded) return row;
    return Padding(
      padding: const EdgeInsets.fromLTRB(spacingScreen, 8, spacingScreen, 8),
      child: row,
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
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurface.withValues(alpha: 0.5);
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
                color: scheme.onSurface.withValues(alpha: 0.06),
              ),
              child: Icon(icon, size: 32, color: muted),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: jakartaSans(
                size: 18,
                weight: FontWeight.w700,
                color: scheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: jakartaSans(
                size: 14,
                weight: FontWeight.w500,
                color: muted,
              ),
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
String _friendlyErrorMessage(dynamic error) {
  if (error == null) return 'Ha ocurrido un error inesperado.';
  final errStr = error.toString().toLowerCase();
  if (errStr.contains('socketexception') ||
      errStr.contains('connection refused') ||
      errStr.contains('connection closed') ||
      errStr.contains('clientexception') ||
      errStr.contains('failed host lookup') ||
      errStr.contains('network is unreachable')) {
    return 'No pudimos conectar con Candela. Revisa tu conexión a internet o intenta de nuevo.';
  }
  if (errStr.contains('timeout')) {
    return 'La respuesta tardó demasiado. Por favor, intenta de nuevo.';
  }
  if (errStr.contains('401') || errStr.contains('unauthorized')) {
    return 'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
  }
  if (errStr.contains('404') || errStr.contains('not found')) {
    return 'No pudimos encontrar la información solicitada.';
  }
  if (errStr.contains('500') || errStr.contains('server error')) {
    return 'El servidor tuvo un problema temporal. Intenta en un momento.';
  }
  final raw = error.toString().replaceFirst('Exception: ', '').trim();
  if (raw.isNotEmpty &&
      !raw.contains('\n') &&
      !raw.contains('ClientException') &&
      !raw.contains('Instance of')) {
    return raw;
  }
  return 'Ha ocurrido un problema al obtener los datos. Intenta nuevamente.';
}

class AsyncView<T> extends StatelessWidget {
  final Future<T> future;
  final Widget Function(T data) builder;
  final String errorTitle;

  /// Optional placeholder shown while loading (e.g. a skeleton). Defaults to
  /// the shared amber spinner.
  final Widget? loading;

  /// Optional callback to retry the operation when an error occurs.
  final VoidCallback? onRetry;

  /// Label for the retry button.
  final String retryLabel;

  const AsyncView({
    required this.future,
    required this.builder,
    this.errorTitle = 'No se pudo cargar',
    this.loading,
    this.onRetry,
    this.retryLabel = 'Reintentar',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return loading ?? const CandelaLoader.centered();
        }
        if (snap.hasError) {
          return EmptyState(
            icon: Icons.cloud_off_rounded,
            title: errorTitle,
            message: _friendlyErrorMessage(snap.error),
            action: onRetry != null
                ? PillButton(
                    label: retryLabel,
                    icon: Icons.refresh_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onRetry!();
                    },
                  )
                : null,
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
    this.color = candelaAmber,
    this.filled = true,
    this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: filled ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: filled
              ? null
              : Border.all(color: onSurface.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: filled ? Colors.white : onSurface),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: jakartaSans(
                size: 13.5,
                weight: FontWeight.w700,
                color: filled ? Colors.white : onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Open plan card ───────────────────────────────────────────────────────────
/// Card for an open plan the user can join — shared by the map's plan sheet
/// and the Plans tab's "Cerca" list. When [showPlace] is true the place name
/// leads the card (list context); otherwise the creator does (the sheet is
/// already scoped to one place). The user's own plans show a "Tuyo" pill
/// instead of the join button — the API rejects joining your own plan.
class OpenPlanCard extends StatelessWidget {
  final OpenPlan plan;
  final VoidCallback onJoin;
  final bool showPlace;
  const OpenPlanCard({
    required this.plan,
    required this.onJoin,
    this.showPlace = false,
    super.key,
  });

  static String _goingLabel(int count) {
    final n = count < 1 ? 1 : count;
    return n == 1 ? '1 va' : '$n van';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final title = plan.isMine
        ? 'Tu plan'
        : showPlace
        ? plan.placeName
        : 'Con @${plan.creator.username}';
    final details = [
      if (showPlace && !plan.isMine) 'Con @${plan.creator.username}',
      if (showPlace && plan.isMine) plan.placeName,
      _goingLabel(plan.participantCount),
      countdownLabel(plan.timeLeft),
    ].join(' · ');
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.bodyLarge),
                const SizedBox(height: 3),
                Text(
                  details,
                  style: textTheme.bodySmall?.copyWith(
                    color: secondaryOn(context),
                  ),
                ),
                if (plan.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    plan.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (plan.isMine)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: candelaAmber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(radiusPill),
              ),
              child: Text(
                'Tuyo',
                style: textTheme.bodySmall?.copyWith(
                  color: candelaAmber,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: candelaAmber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusPill),
                ),
              ),
              onPressed: onJoin,
              child: const Text('Unirme'),
            ),
        ],
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
        style: jakartaSans(
          size: 14,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      backgroundColor: surfaceDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ),
  );
}

// ─── Consistent page transitions ──────────────────────────────────────────────
/// Push navigation: an iOS-style slide-in with interactive edge-swipe-back on
/// every platform. Same call-site API as before (`SlideRightRoute(builder:)`).
class SlideRightRoute<T> extends CupertinoPageRoute<T> {
  SlideRightRoute({required super.builder});
}

// ─── Shared header & back button ──────────────────────────────────────────────
/// The single "chevron in a rounded square" back affordance, shared across every
/// pushed screen (Settings, Friends, History, Check-in…). [dark] forces the
/// dark-flow styling used by the auth screens, which always sit on Candela
/// Night regardless of the ambient theme.
class CandelaBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool dark;
  const CandelaBackButton({this.onTap, this.dark = false, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.maybePop(context),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: dark ? surfaceDark : borderInactive.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        child: Icon(
          Icons.chevron_left_rounded,
          size: dark ? 26 : 24,
          color: dark ? textDarkPrimary : textSecondary,
        ),
      ),
    );
  }
}

/// 40×40 rounded-square icon button used for header actions (settings, search,
/// close…). Same footprint and styling as [CandelaBackButton].
class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  const SquareIconButton({
    required this.icon,
    required this.onTap,
    this.size = 40,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        child: Center(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: borderInactive.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            child: Icon(icon, size: 20, color: secondaryOn(context)),
          ),
        ),
      ),
    );
  }
}

