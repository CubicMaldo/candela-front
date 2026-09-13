import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart' show ApiException;
import 'widgets.dart';
import 'plans_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late Future<List<FeedUser>> _friends;
  late Future<List<FriendRequest>> _requests;
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  Future<List<UserSearchResult>>? _searchResults;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reload();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _reload() {
    _friends = ApiService.getFriends();
    _requests = ApiService.getIncomingRequests();
  }

  Future<void> _accept(FriendRequest r) async {
    HapticFeedback.lightImpact();
    try {
      await ApiService.acceptFriendRequest(r.user.userId);
      if (!mounted) return;
      showToast(context, 'Tú y @${r.user.username} ahora son amigos');
      setState(_reload);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  Future<void> _reject(FriendRequest r) async {
    HapticFeedback.lightImpact();
    try {
      await ApiService.rejectFriendRequest(r.user.userId);
      if (!mounted) return;
      showToast(context, 'Solicitud rechazada.');
      setState(_reload);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  Future<void> _removeFriend(FeedUser friend) async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Dejar de ser amigos'),
        content: Text('¿Quieres quitar a @${friend.username} de tus amigos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: candelaDanger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    HapticFeedback.lightImpact();
    try {
      await ApiService.removeFriend(friend.userId);
      if (!mounted) return;
      showToast(context, 'Ya no son amigos.');
      setState(_reload);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  /// Live search-as-you-type, debounced so we don't hit the API per keystroke.
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _runSearch(value),
    );
  }

  void _runSearch(String value) {
    if (!mounted) return;
    final query = value.trim();
    setState(() {
      _searchResults = query.length < 2 ? null : ApiService.searchUsers(query);
    });
  }

  Future<void> _addFriend(UserSearchResult user) async {
    try {
      await ApiService.sendFriendRequest(user.userId);
      if (!mounted) return;
      showToast(context, 'Solicitud enviada a @${user.username}');
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  // Open the propose-plan sheet directly — no intermediate screen.
  void _openPlanFor(FeedUser friend) {
    showProposePlanSheet(context, friend: friend);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            ScreenHeader(
              title: 'Amigos',
              showBack: true,
              trailing: SquareIconButton(
                icon: _searching ? Icons.close_rounded : Icons.search_rounded,
                onTap: () => setState(() {
                  _searching = !_searching;
                  if (!_searching) {
                    _searchCtrl.clear();
                    _searchDebounce?.cancel();
                    _searchResults = null;
                  }
                }),
              ),
            ),
            if (_searching) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  spacingScreen,
                  12,
                  spacingScreen,
                  0,
                ),
                child: _SearchField(
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                  onSubmitted: _runSearch,
                ),
              ),
              if (_searchResults != null)
                // Flexible + scroll so a full page of matches never overflows.
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      spacingScreen,
                      10,
                      spacingScreen,
                      0,
                    ),
                    child: _SearchResults(
                      future: _searchResults!,
                      onAdd: _addFriend,
                    ),
                  ),
                ),
            ],
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: spacingScreen,
                vertical: 14,
              ),
              child: FutureBuilder<List<FriendRequest>>(
                future: _requests,
                builder: (context, snap) {
                  final n = snap.data?.length ?? 0;
                  return TabBar(
                    controller: _tabController,
                    labelColor: candelaAmber,
                    unselectedLabelColor: secondaryOn(context),
                    indicatorColor: candelaAmber,
                    dividerColor: Colors.transparent,
                    tabs: [
                      const Tab(text: 'Amigos'),
                      Tab(text: n > 0 ? 'Solicitudes ($n)' : 'Solicitudes'),
                    ],
                  );
                },
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildFriends(), _buildRequests()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriends() {
    return AsyncView<List<FeedUser>>(
      future: _friends,
      errorTitle: 'No se pudieron cargar tus amigos',
      loading: const ListSkeleton(),
      builder: (friends) {
        if (friends.isEmpty) {
          return EmptyState(
            icon: Icons.group_outlined,
            title: 'Trae a tu gente',
            message:
                'Busca personas y envía una solicitud para armar tu círculo.',
            action: PillButton(
              label: 'Buscar amigos',
              icon: Icons.search_rounded,
              onTap: () => setState(() => _searching = true),
            ),
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            spacingScreen,
            0,
            spacingScreen,
            bottomListGap(context),
          ),
          itemCount: friends.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) => _FriendRow(
            friend: friends[i],
            onProposePlan: () => _openPlanFor(friends[i]),
            onRemove: () => _removeFriend(friends[i]),
          ),
        );
      },
    );
  }

  Widget _buildRequests() {
    return AsyncView<List<FriendRequest>>(
      future: _requests,
      errorTitle: 'No se pudieron cargar las solicitudes',
      loading: const ListSkeleton(),
      builder: (requests) {
        if (requests.isEmpty) {
          return const EmptyState(
            icon: Icons.mark_email_read_outlined,
            title: 'No tienes solicitudes pendientes',
            message: 'Cuando alguien quiera ser tu amigo, lo verás aquí.',
          );
        }
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(
            spacingScreen,
            0,
            spacingScreen,
            bottomListGap(context),
          ),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final r = requests[i];
            final textTheme = Theme.of(context).textTheme;
            return AppCard(
              child: Row(
                children: [
                  UserAvatar(username: r.user.username, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: textTheme.bodyMedium,
                        children: [
                          TextSpan(
                            text: '@${r.user.username} ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: 'quiere ser tu amigo'),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: secondaryOn(context),
                    ),
                    onPressed: () => _reject(r),
                    child: const Text('Rechazar'),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: candelaAmber,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(radiusPill),
                      ),
                    ),
                    onPressed: () => _accept(r),
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── Friend row ───────────────────────────────────────────────────────────────
class _FriendRow extends StatelessWidget {
  final FeedUser friend;
  final VoidCallback onProposePlan;
  final VoidCallback onRemove;
  const _FriendRow({
    required this.friend,
    required this.onProposePlan,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      child: Row(
        children: [
          UserAvatar(username: friend.username, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${friend.username}', style: textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  friend.badgeLevel.label,
                  style: textTheme.bodySmall?.copyWith(
                    color: secondaryOn(context),
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: candelaAmber,
              side: const BorderSide(color: candelaAmber),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radiusPill),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            onPressed: onProposePlan,
            child: const Text('Proponer plan'),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: secondaryOn(context),
            ),
            onSelected: (_) => onRemove(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'remove', child: Text('Dejar de ser amigo')),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Search field & result ────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Buscar por nombre de usuario',
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

/// Live results for the username search: any user whose name starts with the
/// query, with an add button (or an "Amigos" tag when already connected).
class _SearchResults extends StatelessWidget {
  final Future<List<UserSearchResult>> future;
  final ValueChanged<UserSearchResult> onAdd;
  const _SearchResults({required this.future, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserSearchResult>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(
                color: candelaAmber,
                strokeWidth: 2,
              ),
            ),
          );
        }
        final users = snap.data ?? const <UserSearchResult>[];
        if (users.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              'No encontramos a nadie con ese nombre.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: secondaryOn(context)),
            ),
          );
        }
        final textTheme = Theme.of(context).textTheme;
        return Column(
          children: [
            for (final user in users)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  child: Row(
                    children: [
                      UserAvatar(username: user.username, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '@${user.username}',
                              style: textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.badgeLevel.label,
                              style: textTheme.bodySmall?.copyWith(
                                color: secondaryOn(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (user.isFriend)
                        Text(
                          'Amigos',
                          style: textTheme.bodySmall?.copyWith(
                            color: candelaSage,
                            fontWeight: FontWeight.w700,
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
                          onPressed: () => onAdd(user),
                          child: const Text('Agregar'),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
