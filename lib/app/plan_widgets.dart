part of 'plans_screen.dart';

// ─── Plan list ────────────────────────────────────────────────────────────────
class _PlanList extends StatelessWidget {
  final Future<List<Plan>> future;
  final bool received;
  final ValueChanged<Plan> onAccept;
  final ValueChanged<Plan> onDecline;
  final ValueChanged<Plan> onCancel;
  final Future<void> Function() onRefresh;
  final VoidCallback onPropose;

  const _PlanList({
    required this.future,
    required this.received,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
    required this.onRefresh,
    required this.onPropose,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<Plan>>(
      future: future,
      errorTitle: 'No se pudieron cargar los planes',
      loading: const ListSkeleton(),
      builder: (plans) {
        final child = plans.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 90),
                  EmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: received
                        ? 'Sin planes recibidos'
                        : 'Sin planes enviados',
                    message: received
                        ? 'Cuando alguien te proponga un plan, aparecerá aquí.'
                        : 'Proponle un plan a un amigo para verlo aquí.',
                    action: received
                        ? null
                        : PillButton(
                            label: 'Proponer plan',
                            icon: Icons.add_rounded,
                            onTap: onPropose,
                          ),
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  spacingScreen,
                  16,
                  spacingScreen,
                  bottomListGap(context),
                ),
                itemCount: plans.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: spacingCardGap),
                itemBuilder: (_, i) => _PlanCard(
                  plan: plans[i],
                  received: received,
                  onAccept: onAccept,
                  onDecline: onDecline,
                  onCancel: onCancel,
                ),
              );
        return RefreshIndicator(
          color: candelaAmber,
          onRefresh: onRefresh,
          child: child,
        );
      },
    );
  }
}

// ─── Open plans nearby ("Cerca" tab) ──────────────────────────────────────────
class _OpenPlanList extends StatelessWidget {
  final Future<List<OpenPlan>> future;
  final ValueChanged<OpenPlan> onJoin;
  final Future<void> Function() onRefresh;

  const _OpenPlanList({
    required this.future,
    required this.onJoin,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return AsyncView<List<OpenPlan>>(
      future: future,
      errorTitle: 'No se pudieron cargar los planes cercanos',
      loading: const ListSkeleton(),
      builder: (plans) {
        final child = plans.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 90),
                  EmptyState(
                    icon: Icons.explore_outlined,
                    title: 'Nada abierto cerca',
                    message:
                        'Cuando alguien publique un plan cerca de ti, aparecerá aquí.',
                  ),
                ],
              )
            : ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  spacingScreen,
                  16,
                  spacingScreen,
                  bottomListGap(context),
                ),
                itemCount: plans.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: spacingCardGap),
                itemBuilder: (_, i) => OpenPlanCard(
                  plan: plans[i],
                  showPlace: true,
                  onJoin: () => onJoin(plans[i]),
                ),
              );
        return RefreshIndicator(
          color: candelaAmber,
          onRefresh: onRefresh,
          child: child,
        );
      },
    );
  }
}

// ─── Plan card ────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final Plan plan;
  final bool received;
  final ValueChanged<Plan> onAccept;
  final ValueChanged<Plan> onDecline;
  final ValueChanged<Plan> onCancel;

  const _PlanCard({
    required this.plan,
    required this.received,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final other = received ? plan.creator : plan.target;
    final isPending = plan.status == PlanStatus.pending;
    // Open plans have no single counterpart: show how many are going instead of
    // "Con @x". Accept/decline only applies to direct invitations.
    final subtitle = plan.isOpen
        ? _peopleGoingLabel(plan.participantCount)
        : 'Con @${other?.username ?? '—'}';

    return AppCard(
      onTap: () => _showDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.place.name, style: textTheme.titleSmall),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: secondaryOn(context),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(status: plan.status),
            ],
          ),
          if (received && isPending && !plan.isOpen) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: secondaryOn(context),
                      side: const BorderSide(color: borderInactive),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radiusPill),
                      ),
                    ),
                    onPressed: () => onDecline(plan),
                    child: const Text('Declinar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: candelaAmber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radiusPill),
                      ),
                    ),
                    onPressed: () => onAccept(plan),
                    child: const Text('Aceptar'),
                  ),
                ),
              ],
            ),
          ] else if (!received && isPending) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: secondaryOn(context),
                ),
                onPressed: () => onCancel(plan),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _peopleGoingLabel(int count) {
    final n = count < 1 ? 1 : count;
    return n == 1 ? 'Plan abierto · 1 va' : 'Plan abierto · $n van';
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusCard)),
      ),
      builder: (_) => _PlanDetailSheet(
        plan: plan,
        other: received ? plan.creator : plan.target,
      ),
    );
  }
}

class PlanStatusPill extends StatelessWidget {
  final PlanStatus status;
  const PlanStatusPill({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final mutedBg = onSurface.withValues(alpha: 0.08);
    final mutedFg = onSurface.withValues(alpha: 0.6);
    final (label, bg, fg, outline) = switch (status) {
      PlanStatus.pending => (
        'Pendiente',
        Colors.transparent,
        candelaAmber,
        candelaAmber,
      ),
      PlanStatus.accepted => ('Aceptado', candelaSage, Colors.white, null),
      PlanStatus.completed => ('Concretado', candelaSage, Colors.white, null),
      PlanStatus.failed => ('No concretado', mutedBg, mutedFg, null),
      PlanStatus.declined => ('Declinado', mutedBg, mutedFg, null),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radiusPill),
        border: outline != null ? Border.all(color: outline) : null,
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: fg, fontWeight: FontWeight.w700),
      ),
    );
  }
}

typedef _StatusPill = PlanStatusPill;

// ─── Plan detail sheet ────────────────────────────────────────────────────────
class _PlanDetailSheet extends StatelessWidget {
  final Plan plan;
  final PlanUser? other;
  const _PlanDetailSheet({required this.plan, required this.other});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          spacingScreen,
          20,
          spacingScreen,
          28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.place.name, style: textTheme.titleSmall),
            const SizedBox(height: 6),
            Text(
              plan.isOpen
                  ? _PlanCard._peopleGoingLabel(plan.participantCount)
                  : 'Con @${other?.username ?? '—'}',
              style: textTheme.bodyMedium?.copyWith(
                color: secondaryOn(context),
              ),
            ),
            const SizedBox(height: 14),
            _StatusPill(status: plan.status),
            if (plan.message.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(plan.message, style: textTheme.bodyMedium),
            ],
            const SizedBox(height: 14),
            // Live countdown while the plan can still happen; the original
            // deadline once it's settled.
            Text(
              plan.status == PlanStatus.pending ||
                      plan.status == PlanStatus.accepted
                  ? countdownLabel(plan.timeLeft)
                  : 'Plazo: ${plan.deadlineHours}h',
              style: textTheme.bodySmall?.copyWith(color: secondaryOn(context)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Propose plan sheet ───────────────────────────────────────────────────────
class _ProposePlanSheet extends StatefulWidget {
  final FeedUser? friend;
  const _ProposePlanSheet({this.friend});

  @override
  State<_ProposePlanSheet> createState() => _ProposePlanSheetState();
}

class _ProposePlanSheetState extends State<_ProposePlanSheet> {
  FeedUser? _friend;
  Place? _place;
  int _hours = 24;
  PlanVisibility _visibility = PlanVisibility.invite;
  bool _loading = false;
  final _messageCtrl = TextEditingController();

  late Future<List<FeedUser>> _friends;
  late Future<List<Place>> _places;

  @override
  void initState() {
    super.initState();
    _friend = widget.friend;
    // Opened from a friend (e.g. their profile) → default to a direct invite.
    // Otherwise default to an open, friends-visible plan.
    _visibility = widget.friend != null
        ? PlanVisibility.invite
        : PlanVisibility.friends;
    _friends = UsersApi.getFriends();
    _places = _loadPlaces();
  }

  Future<List<Place>> _loadPlaces() async {
    final position = await LocationService.getCurrentPosition();
    return PlacesApi.getNearbyPlaces(
      lat: position?.latitude ?? fallbackLat,
      lon: position?.longitude ?? fallbackLon,
    );
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  bool get _isInvite => _visibility == PlanVisibility.invite;

  bool get _canSubmit =>
      _place != null && !_loading && (!_isInvite || _friend != null);

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _loading = true);
    try {
      await PlansApi.createPlan(
        targetUserId: _isInvite ? _friend!.userId : null,
        placeId: _place!.placeId,
        message: _messageCtrl.text.trim(),
        deadlineHours: _hours,
        visibility: _visibility,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      showToast(
        context,
        _isInvite
            ? 'Plan enviado a @${_friend!.username}'
            : 'Plan publicado. ¡Que se una la gente!',
      );
    } on ApiException catch (e) {
      setState(() => _loading = false);
      if (mounted) showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.only(
        left: spacingScreen,
        right: spacingScreen,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(radiusCard),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: borderInactive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Proponer plan', style: textTheme.titleSmall),
            const SizedBox(height: 18),

            _label(context, 'Quién puede verlo'),
            const SizedBox(height: 8),
            _VisibilitySelector(
              value: _visibility,
              onChanged: (v) => setState(() => _visibility = v),
            ),
            const SizedBox(height: 18),

            if (_isInvite) ...[
              _label(context, 'Con quién'),
              const SizedBox(height: 8),
              FutureBuilder<List<FeedUser>>(
                future: _friends,
                builder: (context, snap) {
                  final friends = snap.data ?? const [];
                  return SizedBox(
                    height: 84,
                    child: friends.isEmpty
                        ? Center(
                            child: Text(
                              'Aún no tienes amigos para proponer un plan',
                              style: textTheme.bodySmall?.copyWith(
                                color: secondaryOn(context),
                              ),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: friends.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 14),
                            itemBuilder: (_, i) {
                              final f = friends[i];
                              final sel = f.userId == _friend?.userId;
                              return GestureDetector(
                                onTap: () => setState(() => _friend = f),
                                child: Column(
                                  children: [
                                    Stack(
                                      children: [
                                        UserAvatar(
                                          username: f.username,
                                          size: 52,
                                        ),
                                        if (sel)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 20,
                                              height: 20,
                                              decoration: BoxDecoration(
                                                color: candelaSage,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Theme.of(
                                                    context,
                                                  ).scaffoldBackgroundColor,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.check_rounded,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    SizedBox(
                                      width: 56,
                                      child: Text(
                                        '@${f.username}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: textTheme.bodySmall?.copyWith(
                                          fontWeight: sel
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: sel
                                              ? null
                                              : secondaryOn(context),
                                        ),
                                      ),
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
            ],

            _label(context, 'Dónde'),
            const SizedBox(height: 8),
            FutureBuilder<List<Place>>(
              future: _places,
              builder: (context, snap) {
                final places = snap.data ?? const [];
                return Column(
                  children: places.take(4).map((p) {
                    final sel = p.placeId == _place?.placeId;
                    return GestureDetector(
                      onTap: () => setState(() => _place = p),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: sel
                              ? candelaAmber.withValues(alpha: 0.12)
                              : null,
                          borderRadius: BorderRadius.circular(radiusMedium),
                          border: Border.all(
                            color: sel ? candelaAmber : borderInactive,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.place_rounded,
                              size: 19,
                              color: sel ? candelaAmber : secondaryOn(context),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(p.name, style: textTheme.bodyMedium),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 18),

            _label(context, 'Plazo'),
            const SizedBox(height: 8),
            Row(
              children: [24, 48, 72].map((h) {
                final sel = h == _hours;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _hours = h),
                    child: Container(
                      margin: EdgeInsets.only(right: h != 72 ? 10 : 0),
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel ? candelaAmber : null,
                        borderRadius: BorderRadius.circular(radiusMedium),
                        border: Border.all(
                          color: sel ? candelaAmber : borderInactive,
                        ),
                      ),
                      child: Text(
                        '${h}h',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : null,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            _label(context, 'Mensaje (opcional)'),
            const SizedBox(height: 8),
            TextField(
              controller: _messageCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Ej: ¿Nos vemos por allá?',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: candelaAmber,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(radiusPill),
                  ),
                ),
                onPressed: _canSubmit ? _submit : null,
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Proponer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext context, String t) => Text(
    t,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: secondaryOn(context),
      fontWeight: FontWeight.w700,
    ),
  );
}

// ─── Visibility selector ──────────────────────────────────────────────────────
/// Three segmented options — Público / Amigos / Con invitación — mirroring the
/// "Plazo" row's styling. Selecting "Con invitación" reveals the friend picker.
class _VisibilitySelector extends StatelessWidget {
  final PlanVisibility value;
  final ValueChanged<PlanVisibility> onChanged;
  const _VisibilitySelector({required this.value, required this.onChanged});

  static const _options = [
    (PlanVisibility.public, 'Público', Icons.public_rounded),
    (PlanVisibility.friends, 'Amigos', Icons.group_rounded),
    (PlanVisibility.invite, 'Invitación', Icons.person_add_alt_1_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: _options.map((o) {
        final (visibility, label, icon) = o;
        final sel = visibility == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(visibility),
            child: Container(
              margin: EdgeInsets.only(
                right: visibility != _options.last.$1 ? 10 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? candelaAmber : null,
                borderRadius: BorderRadius.circular(radiusMedium),
                border: Border.all(color: sel ? candelaAmber : borderInactive),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 19,
                    color: sel ? Colors.white : secondaryOn(context),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    label,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : secondaryOn(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
