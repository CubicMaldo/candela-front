import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'widgets.dart';

/// Full check-in history for the current user, from GET /api/me/check-ins.
/// While a photo's event is still active it can be pinned as permanent
/// (PATCH /api/checkins/:id/permanent); once the event closes the API rejects
/// the change and the decision is final.
class CheckInHistoryScreen extends StatefulWidget {
  final User profile;
  const CheckInHistoryScreen({required this.profile, super.key});

  @override
  State<CheckInHistoryScreen> createState() => _CheckInHistoryScreenState();
}

class _CheckInHistoryScreenState extends State<CheckInHistoryScreen> {
  late Future<List<MyCheckIn>> _history;

  @override
  void initState() {
    super.initState();
    _history = ApiService.getMyCheckIns(limit: 50);
  }

  Future<void> _togglePermanent(MyCheckIn checkIn) async {
    try {
      final permanent = await ApiService.setPhotoPermanent(
        checkIn.checkinId,
        !checkIn.photoIsPermanent,
      );
      if (!mounted) return;
      showToast(
        context,
        permanent
            ? 'Foto guardada en tu historial.'
            : 'La foto vuelve a ser efímera.',
      );
      setState(() {
        _history = ApiService.getMyCheckIns(limit: 50);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ScreenHeader(title: 'Tu historial', showBack: true),
            Expanded(
              child: AsyncView<List<MyCheckIn>>(
                future: _history,
                errorTitle: 'No se pudo cargar tu historial',
                loading: const ListSkeleton(),
                builder: (events) {
                  if (events.isEmpty) {
                    return const EmptyState(
                      icon: Icons.local_fire_department_outlined,
                      title: 'Aún no tienes check-ins',
                      message: 'Cuando te prendas en un lugar, lo verás aquí.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      spacingScreen,
                      8,
                      spacingScreen,
                      24,
                    ),
                    itemCount: events.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: spacingCardGap),
                    itemBuilder: (_, i) => _HistoryRow(
                      checkIn: events[i],
                      onTogglePermanent: () => _togglePermanent(events[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final MyCheckIn checkIn;
  final VoidCallback onTogglePermanent;
  const _HistoryRow({required this.checkIn, required this.onTogglePermanent});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final photoUrl = checkIn.photoUrl;
    return AppCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(radiusMedium),
            child: SizedBox(
              width: 44,
              height: 44,
              child: photoUrl != null
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _FlameTile(),
                    )
                  : const _FlameTile(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkIn.place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${timeAgo(checkIn.checkedInAt)} · +${checkIn.pointsAwarded} pts',
                  style: textTheme.bodySmall?.copyWith(
                    color: secondaryOn(context),
                  ),
                ),
              ],
            ),
          ),
          if (photoUrl != null)
            IconButton(
              onPressed: onTogglePermanent,
              tooltip: checkIn.photoIsPermanent
                  ? 'Quitar de permanentes'
                  : 'Guardar como permanente',
              icon: Icon(
                checkIn.photoIsPermanent
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                size: 18,
                color: checkIn.photoIsPermanent
                    ? candelaAmber
                    : secondaryOn(context),
              ),
            ),
        ],
      ),
    );
  }
}

class _FlameTile extends StatelessWidget {
  const _FlameTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: candelaAmber.withValues(alpha: 0.12),
      child: const Icon(
        Icons.local_fire_department_rounded,
        color: candelaAmber,
        size: 22,
      ),
    );
  }
}
