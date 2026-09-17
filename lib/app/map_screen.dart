import 'dart:ui' show ImageFilter;
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../config.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart' show ApiException;
import '../services/location_service.dart';
import 'widgets.dart';
import 'place_sheet.dart';

/// The primary discovery surface — a full-screen map of nearby places. Active
/// places (recent check-in activity) glow amber; everything else fades into
/// the background. Category chips and a list-view toggle float above the map.
class MapScreen extends StatefulWidget {
  /// Current tab index of the surrounding shell. When it flips back to the
  /// map tab, live data (active friends, open plans) is refreshed.
  final ValueListenable<int>? activeTab;
  const MapScreen({this.activeTab, super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

const _bquillaCenter = ll.LatLng(fallbackLat, fallbackLon);

/// Gestures the Candela map accepts: pan and zoom, never rotation.
///
/// North stays up so place labels — which are drawn as horizontal text — stay
/// readable, and so a stray two-finger twist can't leave the user with a
/// tilted map and no way to straighten it: there is no reset-north control.
///
/// Both rotation paths have to be closed. [InteractiveFlag.rotate] covers the
/// two-finger twist; cursor/keyboard rotation (Ctrl+drag on desktop and web)
/// is a separate option that defaults to *enabled*, so clearing the flag alone
/// would leave the map rotatable there.
///
/// Not a `const`: [CursorKeyboardRotationOptions.disabled] builds a closure.
InteractionOptions candelaMapInteractions() => InteractionOptions(
  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
  cursorKeyboardRotationOptions: CursorKeyboardRotationOptions.disabled(),
);

class _MapScreenState extends State<MapScreen> {
  static const _categories = [
    ('Todos', null),
    ('Cafés', 'CAFE'),
    ('Comida', 'RESTAURANT'),
    ('Bares', 'BAR'),
    ('Rumba', 'NIGHTCLUB'),
    ('Parques', 'PARK'),
    ('Universidades', 'UNIVERSITY'),
  ];

  Future<List<Place>>? _places;
  String? _category;
  final _mapController = MapController();

  ll.LatLng? _userLatLng;
  bool _showLocationBanner = false;
  bool _listView = false;
  late Future<List<CheckInEvent>> _activeFriends;

  // Open plans nearby the user can join, rendered as pins over the map.
  List<OpenPlan> _openPlans = const [];

  @override
  void initState() {
    super.initState();
    _loadLocation(animate: false);
    _activeFriends = _loadActiveFriends();
    widget.activeTab?.addListener(_onShellTabChanged);
  }

  @override
  void dispose() {
    widget.activeTab?.removeListener(_onShellTabChanged);
    super.dispose();
  }

  void _onShellTabChanged() {
    if (widget.activeTab?.value == 0) _refreshLiveData();
  }

  /// Re-fetches the live layers (friends currently checked in, open plans)
  /// without touching the heavier places load.
  void _refreshLiveData() {
    if (!mounted) return;
    // Braces, not an arrow: the closure must not return the assigned Future.
    setState(() {
      _activeFriends = _loadActiveFriends();
    });
    final c = _referenceCenter;
    _loadOpenPlans(c.latitude, c.longitude);
  }

  Future<void> _loadOpenPlans(double lat, double lon) async {
    try {
      // Discover excludes the user's own plans, so merge in their pending open
      // plans from "outgoing" — otherwise a freshly created plan is invisible
      // on the map and re-creating it hits the API's duplicate error.
      final results = await Future.wait([
        ApiService.discoverOpenPlans(lat: lat, lon: lon),
        ApiService.getOutgoingPlans(),
      ]);
      final discovered = results[0] as List<OpenPlan>;
      final outgoing = results[1] as List<Plan>;
      final places = await (_places ?? Future.value(const <Place>[]));
      final placesById = {for (final p in places) p.placeId: p};
      final own = <OpenPlan>[
        for (final plan in outgoing)
          if (plan.isOpen && plan.status == PlanStatus.pending)
            if (placesById[plan.place.placeId] case final place?)
              OpenPlan(
                planId: plan.planId,
                visibility: plan.visibility,
                message: plan.message,
                deadlineHours: plan.deadlineHours,
                deadlineAt: plan.deadlineAt,
                creator: plan.creator,
                placeId: place.placeId,
                placeName: place.name,
                placeCategory: place.category,
                lat: place.lat,
                lon: place.lon,
                participantCount: plan.participantCount,
                isMine: true,
              ),
      ];
      if (mounted) setState(() => _openPlans = [...own, ...discovered]);
    } catch (_) {
      // Non-fatal: the map still works without plan pins.
    }
  }

  Future<void> _joinOpenPlan(OpenPlan p) async {
    HapticFeedback.lightImpact();
    try {
      await ApiService.joinPlan(p.planId);
      if (!mounted) return;
      Navigator.pop(context); // close the sheet
      showToast(context, 'Te uniste al plan en ${p.placeName}');
      final c = _referenceCenter;
      _loadOpenPlans(c.latitude, c.longitude);
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  void _showOpenPlansAtPlace(List<OpenPlan> plans) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusCard)),
      ),
      builder: (_) => _OpenPlansSheet(plans: plans, onJoin: _joinOpenPlan),
    );
  }

  /// Friends with a live check-in right now, derived from the city feed
  /// (one entry per friend, most recent first). There is no dedicated
  /// "active friends" endpoint, so we reuse the feed like the profile does.
  Future<List<CheckInEvent>> _loadActiveFriends() async {
    // 50 is the server's ceiling on this endpoint; asking for more is silently
    // clamped, so request what we can actually get.
    final page = await ApiService.getFeed(limit: 50);
    final seen = <String>{};
    final result = <CheckInEvent>[];
    for (final e in page.events) {
      if (!e.user.isFriend) continue;
      if (seen.add(e.user.userId)) result.add(e);
    }
    return result;
  }

  Future<void> _loadLocation({bool animate = true}) async {
    final position = await LocationService.getCurrentPosition();
    if (!mounted) return;
    if (position != null) {
      final latLng = ll.LatLng(position.latitude, position.longitude);
      setState(() {
        _userLatLng = latLng;
        _showLocationBanner = false;
        _places = ApiService.getNearbyPlaces(
          lat: latLng.latitude,
          lon: latLng.longitude,
        );
      });
      _loadOpenPlans(latLng.latitude, latLng.longitude);
      if (animate) _mapController.move(latLng, 15);
    } else {
      setState(() {
        _userLatLng = null;
        _showLocationBanner = true;
        _places ??= ApiService.getNearbyPlaces(
          lat: _bquillaCenter.latitude,
          lon: _bquillaCenter.longitude,
        );
      });
      _loadOpenPlans(_bquillaCenter.latitude, _bquillaCenter.longitude);
    }
  }

  Future<void> _onMyLocationTap() async {
    final position = await LocationService.getCurrentPosition();
    if (!mounted) return;
    if (position == null) {
      await LocationService.showLocationDisabledDialog(context);
      return;
    }
    final latLng = ll.LatLng(position.latitude, position.longitude);
    setState(() {
      _userLatLng = latLng;
      _showLocationBanner = false;
    });
    _loadOpenPlans(latLng.latitude, latLng.longitude);
    _mapController.move(latLng, 15);
  }

  ll.LatLng get _referenceCenter => _userLatLng ?? _bquillaCenter;

  void _showActiveFriends(List<CheckInEvent> friends) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusCard)),
      ),
      builder: (_) => _ActiveFriendsSheet(
        friends: friends,
        onTapPlace: (placeId) async {
          Navigator.pop(context);
          final place = await ApiService.getPlaceDetail(placeId);
          if (mounted) showPlaceSheet(context, place);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final places = _places;
    if (places == null) {
      return const Scaffold(body: CandelaLoader.centered());
    }
    return Scaffold(
      body: AsyncView<List<Place>>(
        future: places,
        errorTitle: 'No se pudo cargar el mapa',
        builder: (places) {
          final filtered = _category == null
              ? places
              : places.where((p) => p.category == _category).toList();
          return Stack(
            children: [
              Positioned.fill(
                child: _listView
                    ? _PlacesListView(
                        places: filtered,
                        reference: _referenceCenter,
                      )
                    : _Map(
                        places: filtered,
                        openPlans: _openPlans,
                        controller: _mapController,
                        userLatLng: _userLatLng,
                        onTapPlans: _showOpenPlansAtPlace,
                      ),
              ),
              // The category filter applies to both views (spec §7.3/7.5).
              Positioned(
                top: topInset + 8,
                left: 0,
                right: 0,
                child: _FilterBar(
                  categories: _categories,
                  active: _category,
                  onChanged: (cat) => setState(() => _category = cat),
                ),
              ),
              if (!_listView) ...[
                if (_showLocationBanner)
                  Positioned(
                    top: topInset + 60,
                    left: spacingScreen,
                    right: spacingScreen,
                    child: _LocationBanner(
                      onTap: () =>
                          LocationService.showLocationDisabledDialog(context),
                    ),
                  ),
                Positioned(
                  right: spacingScreen,
                  bottom: navBarClearance(context),
                  child: _MyLocationButton(onTap: _onMyLocationTap),
                ),
                Positioned(
                  right: spacingScreen,
                  bottom: navBarClearance(context) + 52,
                  child: FutureBuilder<List<CheckInEvent>>(
                    future: _activeFriends,
                    builder: (context, snap) {
                      final friends = snap.data ?? const <CheckInEvent>[];
                      if (friends.isEmpty) return const SizedBox.shrink();
                      return _ActiveFriendsButton(
                        friends: friends,
                        onTap: () => _showActiveFriends(friends),
                      );
                    },
                  ),
                ),
              ],
              // Bottom-left, per spec §7.5.
              Positioned(
                left: spacingScreen,
                bottom: navBarClearance(context),
                child: _ListToggleButton(
                  active: _listView,
                  onTap: () => setState(() => _listView = !_listView),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Map body ─────────────────────────────────────────────────────────────────
class _Map extends StatelessWidget {
  final List<Place> places;
  final List<OpenPlan> openPlans;
  final MapController controller;
  final ll.LatLng? userLatLng;
  final void Function(List<OpenPlan>) onTapPlans;
  const _Map({
    required this.places,
    required this.openPlans,
    required this.controller,
    required this.userLatLng,
    required this.onTapPlans,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Group open plans by place so each location shows a single plan pin.
    final plansByPlace = <String, List<OpenPlan>>{};
    for (final p in openPlans) {
      (plansByPlace[p.placeId] ??= []).add(p);
    }
    // Minimalist Carto basemaps — Positron (light) / Dark Matter (dark) — so the
    // map follows the app theme and keeps the focus on places and events.
    final basemap = isDark ? 'dark_all' : 'light_all';
    final cartoKeyQuery = cartoApiKey.isNotEmpty ? '?key=$cartoApiKey' : '';
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: userLatLng ?? _bquillaCenter,
        initialZoom: userLatLng != null ? 15 : 14,
        interactionOptions: candelaMapInteractions(),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/$basemap/{z}/{x}/{y}{r}.png$cartoKeyQuery',
          subdomains: const ['a', 'b', 'c', 'd'],
          retinaMode: RetinaMode.isHighDensity(context),
          userAgentPackageName: 'com.candela.app',
        ),
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomLeft,
          attributions: [
            TextSourceAttribution('OpenStreetMap'),
            TextSourceAttribution('CARTO'),
          ],
        ),
        MarkerLayer(
          markers: [
            // One combined marker per place: the label carries both the place
            // name and (when there are open plans) a sage plan chip, so the
            // two never overlap each other on the map.
            for (final place in places)
              Marker(
                point: ll.LatLng(place.lat, place.lon),
                width:
                    (place.isActive || plansByPlace.containsKey(place.placeId))
                    ? 176
                    : 14,
                height:
                    (place.isActive || plansByPlace.containsKey(place.placeId))
                    ? 70
                    : 14,
                alignment:
                    (place.isActive || plansByPlace.containsKey(place.placeId))
                    ? Alignment.bottomCenter
                    : Alignment.center,
                child: _PlacePin(
                  place: place,
                  plans: plansByPlace.remove(place.placeId) ?? const [],
                  onTap: () => showPlaceSheet(context, place),
                  onTapPlans: onTapPlans,
                ),
              ),
            // Plans at places outside the current (filtered) list still get
            // their own standalone pin.
            for (final group in plansByPlace.values)
              Marker(
                point: ll.LatLng(group.first.lat, group.first.lon),
                width: 72,
                height: 44,
                alignment: Alignment.bottomCenter,
                child: _PlanPin(
                  count: group.length,
                  onTap: () => onTapPlans(group),
                ),
              ),
            if (userLatLng != null)
              Marker(
                point: userLatLng!,
                width: 16,
                height: 16,
                alignment: Alignment.center,
                child: const _UserPositionDot(),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── User position marker ─────────────────────────────────────────────────────
class _UserPositionDot extends StatelessWidget {
  const _UserPositionDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: candelaAmber,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

// ─── Location banner ──────────────────────────────────────────────────────────
class _LocationBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _LocationBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: candelaNight.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        child: Text(
          'Activa tu ubicación para ver eventos cerca de ti.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: candelaAmber,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── My location button ───────────────────────────────────────────────────────
class _MyLocationButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MyLocationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: candelaNight,
      shape: const CircleBorder(
        side: BorderSide(color: Colors.white24, width: 0.5),
      ),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// ─── Active friends ───────────────────────────────────────────────────────────
/// Corner cluster of friends checked in right now. Tap to see who and where.
class _ActiveFriendsButton extends StatelessWidget {
  final List<CheckInEvent> friends;
  final VoidCallback onTap;
  const _ActiveFriendsButton({required this.friends, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final shown = friends.take(3).toList();
    return Material(
      color: candelaNight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusPill),
        side: const BorderSide(color: Colors.white24, width: 0.5),
      ),
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(radiusPill),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 24.0 + (shown.length - 1) * 16,
                height: 28,
                child: Stack(
                  children: [
                    for (var i = 0; i < shown.length; i++)
                      Positioned(
                        left: i * 16.0,
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: candelaNight,
                          ),
                          padding: const EdgeInsets.all(1.5),
                          child: UserAvatar(
                            username: shown[i].user.username,
                            size: 25,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'En candela',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveFriendsSheet extends StatelessWidget {
  final List<CheckInEvent> friends;
  final ValueChanged<String> onTapPlace;
  const _ActiveFriendsSheet({required this.friends, required this.onTapPlace});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          spacingScreen,
          18,
          spacingScreen,
          12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tu gente en candela ahora', style: textTheme.titleSmall),
            const SizedBox(height: 12),
            // Scrollable so a long list never overflows the sheet.
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final e in friends)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        onTap: () => onTapPlace(e.place.placeId),
                        leading: UserAvatar(
                          username: e.user.username,
                          size: 44,
                        ),
                        title: Text(
                          '@${e.user.username}',
                          style: textTheme.bodyLarge,
                        ),
                        subtitle: Text(
                          'en ${e.place.name}',
                          style: textTheme.bodySmall?.copyWith(
                            color: secondaryOn(context),
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: secondaryOn(context),
                        ),
                      ),
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

// ─── Open plans sheet ─────────────────────────────────────────────────────────
/// Lists the open plans at a tapped place, each with a "Unirme" action.
class _OpenPlansSheet extends StatelessWidget {
  final List<OpenPlan> plans;
  final ValueChanged<OpenPlan> onJoin;
  const _OpenPlansSheet({required this.plans, required this.onJoin});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final placeName = plans.isEmpty ? '' : plans.first.placeName;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          spacingScreen,
          18,
          spacingScreen,
          16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Planes en $placeName', style: textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Únete a un plan abierto aquí.',
              style: textTheme.bodySmall?.copyWith(color: secondaryOn(context)),
            ),
            const SizedBox(height: 14),
            // Scrollable so many plans never overflow the sheet.
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final p in plans)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OpenPlanCard(plan: p, onJoin: () => onJoin(p)),
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

// ─── List view ────────────────────────────────────────────────────────────────
class _PlacesListView extends StatelessWidget {
  final List<Place> places;
  final ll.LatLng reference;
  const _PlacesListView({required this.places, required this.reference});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final sorted = places.toList()
      ..sort((a, b) => _distanceMeters(a).compareTo(_distanceMeters(b)));
    return SafeArea(
      child: Column(
        children: [
          Padding(
            // Clears the floating filter bar overlaid on both views.
            padding: const EdgeInsets.fromLTRB(
              spacingScreen,
              60,
              spacingScreen,
              0,
            ),
            child: Row(
              children: [Text('Lugares cercanos', style: textTheme.titleSmall)],
            ),
          ),
          Expanded(
            child: sorted.isEmpty
                ? const EmptyState(
                    icon: Icons.location_off_outlined,
                    title: 'No encontramos lugares',
                    message: 'Prueba con otra categoría.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      spacingScreen,
                      12,
                      spacingScreen,
                      kBottomGap,
                    ),
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = sorted[i];
                      return GestureDetector(
                        onTap: () => showPlaceSheet(context, p),
                        child: AppCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (p.isActive)
                                          Container(
                                            margin: const EdgeInsets.only(
                                              right: 6,
                                            ),
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: candelaAmber,
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            p.name,
                                            style: textTheme.bodyLarge,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${categoryLabel(p.category)} · ${distanceLabel(_distanceMeters(p))}',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: secondaryOn(context),
                                      ),
                                    ),
                                    if (p.isActive &&
                                        p.activeCheckinsCount > 0) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        p.activeCheckinsCount == 1
                                            ? '1 persona en candela ahora'
                                            : '${p.activeCheckinsCount} personas en candela ahora',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: candelaAmber,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: secondaryOn(context),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  double _distanceMeters(Place place) => Geolocator.distanceBetween(
    reference.latitude,
    reference.longitude,
    place.lat,
    place.lon,
  );
}

// ─── Place pin ────────────────────────────────────────────────────────────────
/// Combined marker for a place: one label pill holding the place name and —
/// when there are open plans there — an attached sage plan chip, so the plan
/// badge never covers the place name. The teardrop is amber when the place is
/// live; sage when it only has open plans.
class _PlacePin extends StatelessWidget {
  final Place place;
  final List<OpenPlan> plans;
  final VoidCallback? onTap;
  final void Function(List<OpenPlan>)? onTapPlans;
  const _PlacePin({
    required this.place,
    this.plans = const [],
    required this.onTap,
    this.onTapPlans,
  });

  @override
  Widget build(BuildContext context) {
    final hasPlans = plans.isNotEmpty;
    // Quiet places without plans: a small dot so attention stays on what's live.
    if (!place.isActive && !hasPlans) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: secondaryOn(context).withValues(alpha: 0.55),
          border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.fromLTRB(8, 2, 4, 2),
            decoration: BoxDecoration(
              color: candelaNight.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(radiusPill),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Padding(
                    padding: EdgeInsets.only(right: hasPlans ? 6 : 4),
                    child: Text(
                      place.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                if (hasPlans)
                  GestureDetector(
                    onTap: () => onTapPlans?.call(plans),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: candelaSage,
                        borderRadius: BorderRadius.circular(radiusPill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            plans.length == 1 ? 'Plan' : '${plans.length}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(28, 36),
            painter: _TeardropPainter(
              color: place.isActive ? candelaAmber : candelaSage,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeardropPainter extends CustomPainter {
  final Color color;
  _TeardropPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w / 2, h)
      ..cubicTo(w * 0.05, h * 0.55, 0, h * 0.38, w / 2, 0)
      ..cubicTo(w, h * 0.38, w * 0.95, h * 0.55, w / 2, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawCircle(
      Offset(w / 2, h * 0.36),
      w * 0.18,
      Paint()..color = Colors.white.withValues(alpha: 0.85),
    );
  }

  @override
  bool shouldRepaint(covariant _TeardropPainter oldDelegate) =>
      oldDelegate.color != color;
}

// ─── Plan pin ─────────────────────────────────────────────────────────────────
/// Sage badge marking a place with open plans to join. Tapping opens the list
/// of plans there. Uses Candela Sage to read as distinct from amber activity.
class _PlanPin extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _PlanPin({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: candelaSage,
          borderRadius: BorderRadius.circular(radiusPill),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 13,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              count == 1 ? 'Plan' : '$count planes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter chips bar ─────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  final List<(String, String?)> categories;
  final String? active;
  final ValueChanged<String?> onChanged;
  const _FilterBar({
    required this.categories,
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: spacingScreen),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radiusPill),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: candelaNight.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(radiusPill),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (label, value) = categories[i];
                final isActive = active == value;
                return GestureDetector(
                  onTap: () => onChanged(value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive
                          ? candelaAmber
                          : Colors.white.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(radiusPill),
                    ),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isActive ? Colors.white : textDarkSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─── List-view toggle ─────────────────────────────────────────────────────────
class _ListToggleButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _ListToggleButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: candelaNight.withValues(alpha: 0.85),
      shape: const CircleBorder(
        side: BorderSide(color: Colors.white24, width: 0.5),
      ),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            active ? Icons.map_outlined : Icons.format_list_bulleted_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
