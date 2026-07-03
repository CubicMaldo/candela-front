import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import 'widgets.dart';

/// Full check-in history for the current user. There is no dedicated
/// "my check-ins" endpoint, so — like the profile's recent strip — this derives
/// the list from the city feed filtered to the user.
class CheckInHistoryScreen extends StatefulWidget {
  final User profile;
  const CheckInHistoryScreen({required this.profile, super.key});

  @override
  State<CheckInHistoryScreen> createState() => _CheckInHistoryScreenState();
}

class _CheckInHistoryScreenState extends State<CheckInHistoryScreen> {
  late Future<List<CheckInEvent>> _history;

  @override
  void initState() {
    super.initState();
    _history = _load();
  }

  Future<List<CheckInEvent>> _load() async {
    final events = await ApiService.getFeed(limit: 100);
    return events.where((e) => e.user.userId == widget.profile.userId).toList();
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
              child: AsyncView<List<CheckInEvent>>(
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
                    itemBuilder: (_, i) => _HistoryRow(event: events[i]),
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
  final CheckInEvent event;
  const _HistoryRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: candelaAmber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(radiusMedium),
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: candelaAmber,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.place.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo(event.checkedInAt),
                  style: textTheme.bodySmall?.copyWith(color: textSecondary),
                ),
              ],
            ),
          ),
          if (event.photoIsPermanent)
            Icon(Icons.push_pin_rounded, size: 16, color: textSecondary),
        ],
      ),
    );
  }
}
