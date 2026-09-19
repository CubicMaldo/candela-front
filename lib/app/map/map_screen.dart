import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../config.dart';
import '../../theme.dart';
import '../../models.dart';
import 'package:candela_front/services/api/places_api.dart';
import 'package:candela_front/services/api/plans_api.dart';
import 'package:candela_front/services/api/feed_api.dart';
import '../../services/auth_service.dart' show ApiException;
import '../../services/location_service.dart';
import '../widgets.dart';
import 'map_components.dart';
import '../place_sheet.dart';

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

const bquillaCenter = ll.LatLng(fallbackLat, fallbackLon);
const _bquillaCenter = bquillaCenter;

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
        PlansApi.discoverOpenPlans(lat: lat, lon: lon),
        PlansApi.getOutgoingPlans(),
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
      await PlansApi.joinPlan(p.planId);
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
      builder: (_) => OpenPlansSheet(plans: plans, onJoin: _joinOpenPlan),
    );
  }

  /// Friends with a live check-in right now, derived from the city feed
  /// (one entry per friend, most recent first). There is no dedicated
  /// "active friends" endpoint, so we reuse the feed like the profile does.
  Future<List<CheckInEvent>> _loadActiveFriends() async {
    // 50 is the server's ceiling on this endpoint; asking for more is silently
    // clamped, so request what we can actually get.
    final page = await FeedApi.getFeed(limit: 50);
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
        _places = PlacesApi.getNearbyPlaces(
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
        _places ??= PlacesApi.getNearbyPlaces(
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

  Future<void> _refreshPlaces() async {
    final c = _referenceCenter;
    final fut = PlacesApi.getNearbyPlaces(
      lat: c.latitude,
      lon: c.longitude,
    );
    setState(() {
      _places = fut;
    });
    await fut;
    _refreshLiveData();
  }

  void _showActiveFriends(List<CheckInEvent> friends) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(radiusCard)),
      ),
      builder: (_) => ActiveFriendsSheet(
        friends: friends,
        onTapPlace: (placeId) async {
          Navigator.pop(context);
          final place = await PlacesApi.getPlaceDetail(placeId);
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
        onRetry: _refreshPlaces,
        builder: (places) {
          final filtered = _category == null
              ? places
              : places.where((p) => p.category == _category).toList();
          return Stack(
            children: [
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _listView
                      ? PlacesListView(
                          key: const ValueKey('places_list'),
                          places: filtered,
                          reference: _referenceCenter,
                          onRefresh: _refreshPlaces,
                        )
                      : MapBody(
                          key: ValueKey('places_map_${Theme.of(context).brightness.name}'),
                          places: filtered,
                          openPlans: _openPlans,
                          controller: _mapController,
                          userLatLng: _userLatLng,
                          onTapPlans: _showOpenPlansAtPlace,
                        ),
                ),
              ),
              // The category filter applies to both views (spec §7.3/7.5).
              Positioned(
                top: topInset + 8,
                left: 0,
                right: 0,
                child: FilterBar(
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
                    child: LocationBanner(
                      onTap: () =>
                          LocationService.showLocationDisabledDialog(context),
                    ),
                  ),
                Positioned(
                  right: spacingScreen,
                  bottom: navBarClearance(context),
                  child: MyLocationButton(onTap: _onMyLocationTap),
                ),
                Positioned(
                  right: spacingScreen,
                  bottom: navBarClearance(context) + 52,
                  child: FutureBuilder<List<CheckInEvent>>(
                    future: _activeFriends,
                    builder: (context, snap) {
                      final friends = snap.data ?? const <CheckInEvent>[];
                      if (friends.isEmpty) return const SizedBox.shrink();
                      return ActiveFriendsButton(
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
                child: ListToggleButton(
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


