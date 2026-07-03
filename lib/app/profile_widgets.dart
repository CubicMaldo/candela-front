part of 'profile_screen.dart';

// ─── Loading skeleton ─────────────────────────────────────────────────────────
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          spacingScreen,
          24,
          spacingScreen,
          24,
        ),
        children: [
          const Center(child: SkeletonBox(height: 96, circle: true)),
          const SizedBox(height: 14),
          const Center(child: SkeletonBox(width: 120)),
          const SizedBox(height: 10),
          const Center(
            child: SkeletonBox(width: 90, height: 24, radius: radiusPill),
          ),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              SkeletonBox(width: 60, height: 36),
              SkeletonBox(width: 60, height: 36),
              SkeletonBox(width: 60, height: 36),
            ],
          ),
          const SizedBox(height: spacingCardGap),
          const SkeletonBox(
            width: double.infinity,
            height: 72,
            radius: radiusCard,
          ),
          const SizedBox(height: spacingCardGap),
          const SkeletonBox(
            width: double.infinity,
            height: 48,
            radius: radiusCard,
          ),
        ],
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────
class _AvatarCircle extends StatelessWidget {
  final String username;
  final double size;
  const _AvatarCircle({required this.username, required this.size});

  @override
  Widget build(BuildContext context) {
    final initial = username.isNotEmpty ? username[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: candelaAmber,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Badge pill ───────────────────────────────────────────────────────────────
class _BadgePill extends StatelessWidget {
  final BadgeLevel badge;
  const _BadgePill(this.badge);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: candelaAmber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      child: Text(
        badge.label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: candelaAmber,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Stat item ────────────────────────────────────────────────────────────────
class _StatItem extends StatelessWidget {
  final int value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text('$value', style: textTheme.titleSmall),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.labelSmall?.copyWith(color: textSecondary),
        ),
      ],
    );
  }
}

// ─── Streak card — the hero ───────────────────────────────────────────────────
class _StreakCard extends StatelessWidget {
  final int weeks;
  final int weekCheckins;
  const _StreakCard({required this.weeks, required this.weekCheckins});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final surface = Theme.of(context).brightness == Brightness.dark
        ? surfaceDark
        : Theme.of(context).colorScheme.surface;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(spacingCard),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 20,
                color: candelaAmber,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  weeks > 0 ? '$weeks semanas seguidas' : 'Sin racha activa',
                  style: textTheme.titleSmall?.copyWith(color: candelaAmber),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            weeks > 0
                ? '$weekCheckins check-ins esta semana'
                : 'Empieza tu racha esta semana.',
            style: textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }
}

// ─── Points section — collapsed by default, never the hero ───────────────────
class _PointsSection extends StatelessWidget {
  final bool expanded;
  final int pointsTotal;
  final int pointsSeason;
  final VoidCallback onToggle;
  const _PointsSection({
    required this.expanded,
    required this.pointsTotal,
    required this.pointsSeason,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: textSecondary,
            padding: EdgeInsets.zero,
          ),
          onPressed: onToggle,
          icon: Icon(
            expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
            size: 18,
          ),
          label: const Text('Ver mis puntos'),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                Text(
                  'Puntos totales: $pointsTotal',
                  style: textTheme.bodySmall?.copyWith(color: textSecondary),
                ),
                const SizedBox(width: 16),
                Text(
                  'Esta temporada: $pointsSeason',
                  style: textTheme.bodySmall?.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Rankings section — opt-in only ───────────────────────────────────────────
class _RankingsSection extends StatefulWidget {
  final bool optedIn;
  final VoidCallback onOptIn;
  const _RankingsSection({required this.optedIn, required this.onOptIn});

  @override
  State<_RankingsSection> createState() => _RankingsSectionState();
}

class _RankingsSectionState extends State<_RankingsSection> {
  Future<RankingResponse>? _ranking;

  @override
  void didUpdateWidget(covariant _RankingsSection old) {
    super.didUpdateWidget(old);
    if (widget.optedIn != old.optedIn) _ranking = null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (!widget.optedIn) {
      return TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: textSecondary,
          padding: EdgeInsets.zero,
        ),
        onPressed: widget.onOptIn,
        icon: const Icon(Icons.leaderboard_outlined, size: 18),
        label: const Text('Participar en rankings'),
      );
    }
    _ranking ??= ApiService.getFriendsRanking();
    return FutureBuilder<RankingResponse>(
      future: _ranking,
      builder: (context, snap) {
        final rank = snap.data?.userRank;
        return Row(
          children: [
            const Icon(
              Icons.leaderboard_rounded,
              size: 18,
              color: candelaAmber,
            ),
            const SizedBox(width: 8),
            Text(
              rank != null
                  ? 'Estás en el puesto #$rank del ranking de amigos'
                  : 'Aún no tienes posición en el ranking de amigos',
              style: textTheme.bodySmall?.copyWith(color: textSecondary),
            ),
          ],
        );
      },
    );
  }
}

// ─── Recent check-ins strip ───────────────────────────────────────────────────
class _RecentCheckIns extends StatelessWidget {
  final Future<List<CheckInEvent>> future;
  const _RecentCheckIns({required this.future});

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<CheckInEvent>>(
      future: future,
      errorTitle: 'No se pudo cargar tu historial',
      builder: (events) {
        if (events.isEmpty) {
          return const EmptyState(
            icon: Icons.local_fire_department_outlined,
            title: 'Aún no tienes check-ins',
            message: 'Tus visitas recientes van a aparecer aquí.',
          );
        }
        final textTheme = Theme.of(context).textTheme;
        return SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(width: spacingCardGap),
            itemBuilder: (_, i) {
              final e = events[i];
              return Container(
                width: 160,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(radiusCard),
                  border: Border.all(
                    color: borderInactive.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      e.place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgo(e.checkedInAt),
                      style: textTheme.bodySmall?.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: borderInactive.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        child: Icon(icon, size: 20, color: textSecondary),
      ),
    );
  }
}
