import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart' show ApiException;
import '../services/location_service.dart';
import 'widgets.dart';

part 'plan_widgets.dart';

/// Opens the "propose a plan" bottom sheet from anywhere in the app (e.g. the
/// check-in flow, where it's offered as an alternative to marking a place).
/// Returns true when a plan was created.
Future<bool?> showProposePlanSheet(BuildContext context, {FeedUser? friend}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProposePlanSheet(friend: friend),
  );
}

/// Plans — propose to meet a friend at a place. Replaces the old "Challenges"
/// concept entirely; the word does not appear anywhere in this surface.
class PlansScreen extends StatefulWidget {
  final FeedUser? prefillFriend;
  const PlansScreen({this.prefillFriend, super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<Plan>> _incoming;
  late Future<List<Plan>> _outgoing;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reload();
    if (widget.prefillFriend != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openCreate(widget.prefillFriend),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _reload() {
    _incoming = ApiService.getIncomingPlans();
    _outgoing = ApiService.getOutgoingPlans();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait([_incoming, _outgoing]);
  }

  Future<void> _accept(Plan p) async {
    HapticFeedback.lightImpact();
    try {
      await ApiService.acceptPlan(p.planId);
      if (!mounted) return;
      showToast(context, 'Plan aceptado con @${p.creator.username}');
      setState(_reload);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  Future<void> _decline(Plan p) async {
    HapticFeedback.lightImpact();
    try {
      await ApiService.declinePlan(p.planId);
      if (!mounted) return;
      showToast(context, 'Plan declinado.');
      setState(_reload);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  Future<void> _cancel(Plan p) async {
    HapticFeedback.lightImpact();
    try {
      await ApiService.cancelPlan(p.planId);
      if (!mounted) return;
      showToast(context, 'Plan cancelado.');
      setState(_reload);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  Future<void> _openCreate([FeedUser? friend]) async {
    final created = await showProposePlanSheet(context, friend: friend);
    if (created == true && mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Planes',
              trailing: _AddPlanButton(onTap: () => _openCreate()),
            ),
            TabBar(
              controller: _tabController,
              labelColor: candelaAmber,
              unselectedLabelColor: textSecondary,
              indicatorColor: candelaAmber,
              tabs: const [
                Tab(text: 'Recibidos'),
                Tab(text: 'Enviados'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PlanList(
                    future: _incoming,
                    received: true,
                    onAccept: _accept,
                    onDecline: _decline,
                    onCancel: _cancel,
                    onRefresh: _refresh,
                    onPropose: _openCreate,
                  ),
                  _PlanList(
                    future: _outgoing,
                    received: false,
                    onAccept: _accept,
                    onDecline: _decline,
                    onCancel: _cancel,
                    onRefresh: _refresh,
                    onPropose: _openCreate,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Amber circular "+" used in the Planes header to propose a new plan.
class _AddPlanButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPlanButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: candelaAmber,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}
