import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../theme.dart';
import '../../models.dart';
import '../../config.dart';
import '../widgets.dart';
import '../place_sheet.dart';
import 'map_screen.dart'; // for interactions and bquillaCenter

// ─── Map body ─────────────────────────────────────────────────────────────────

class MapBody extends StatelessWidget {
  final List<Place> places;
  final List<OpenPlan> openPlans;
  final MapController controller;
  final ll.LatLng? userLatLng;
  final void Function(List<OpenPlan>) onTapPlans;
  const MapBody({
    super.key,
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
    final mapBackground = isDark ? candelaNight : candelaSand;
    final cartoKeyQuery = cartoApiKey.isNotEmpty ? '?key=$cartoApiKey' : '';
    return FlutterMap(
      key: ValueKey('flutter_map_$basemap'),
      mapController: controller,
      options: MapOptions(
        initialCenter: userLatLng ?? bquillaCenter,
        initialZoom: userLatLng != null ? 15 : 14,
        interactionOptions: candelaMapInteractions(),
        backgroundColor: mapBackground,
      ),
      children: [
        TileLayer(
          key: ValueKey('tile_layer_$basemap'),
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
                child: PlacePin(
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
                child: PlanPin(
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
                child: const UserPositionDot(),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── User position marker ─────────────────────────────────────────────────────
class UserPositionDot extends StatelessWidget {
  const UserPositionDot({super.key});

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
class LocationBanner extends StatelessWidget {
  final VoidCallback onTap;
  const LocationBanner({super.key, required this.onTap});

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
class MyLocationButton extends StatelessWidget {
  final VoidCallback onTap;
  const MyLocationButton({super.key, required this.onTap});

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
class ActiveFriendsButton extends StatelessWidget {
  final List<CheckInEvent> friends;
  final VoidCallback onTap;
  const ActiveFriendsButton({
    super.key,
    required this.friends,
    required this.onTap,
  });

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

class ActiveFriendsSheet extends StatelessWidget {
  final List<CheckInEvent> friends;
  final ValueChanged<String> onTapPlace;
  const ActiveFriendsSheet({
    super.key,
    required this.friends,
    required this.onTapPlace,
  });

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
class OpenPlansSheet extends StatelessWidget {
  final List<OpenPlan> plans;
  final ValueChanged<OpenPlan> onJoin;
  const OpenPlansSheet({
    super.key,
    required this.plans,
    required this.onJoin,
  });

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
// ─── List view ────────────────────────────────────────────────────────────────
class PlacesListView extends StatelessWidget {
  final List<Place> places;
  final ll.LatLng reference;
  final Future<void> Function()? onRefresh;
  const PlacesListView({
    super.key,
    required this.places,
    required this.reference,
    this.onRefresh,
  });

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
            child: RefreshIndicator(
              color: candelaAmber,
              onRefresh: onRefresh ?? () async {},
              child: sorted.isEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: const Center(
                            child: EmptyState(
                              icon: Icons.location_off_outlined,
                              title: 'No encontramos lugares',
                              message: 'Prueba con otra categoría o desliza para actualizar.',
                            ),
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                                          Expanded(
                                            child: Text(
                                              p.name,
                                              style: textTheme.bodyLarge?.copyWith(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (p.isActive) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: candelaAmber.withValues(
                                                  alpha: 0.15,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                  radiusPill,
                                                ),
                                                border: Border.all(
                                                  color: candelaAmber.withValues(
                                                    alpha: 0.4,
                                                  ),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons
                                                        .local_fire_department_rounded,
                                                    size: 12,
                                                    color: candelaAmber,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    p.activeCheckinsCount > 0
                                                        ? '${p.activeCheckinsCount}'
                                                        : 'Activo',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: candelaAmber,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: 11,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${categoryLabel(p.category)} · ${distanceLabel(_distanceMeters(p))}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: secondaryOn(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
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
class PlacePin extends StatelessWidget {
  final Place place;
  final List<OpenPlan> plans;
  final VoidCallback? onTap;
  final void Function(List<OpenPlan>)? onTapPlans;
  const PlacePin({
    super.key,
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
class PlanPin extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const PlanPin({
    super.key,
    required this.count,
    required this.onTap,
  });

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
class FilterBar extends StatelessWidget {
  final List<(String, String?)> categories;
  final String? active;
  final ValueChanged<String?> onChanged;
  const FilterBar({
    super.key,
    required this.categories,
    required this.active,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              color: isDark
                  ? candelaNight.withValues(alpha: 0.75)
                  : Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(radiusPill),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final (label, value) = categories[i];
                final isActive = active == value;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(value);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive
                          ? candelaAmber
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.10)
                              : Colors.black.withValues(alpha: 0.06)),
                      borderRadius: BorderRadius.circular(radiusPill),
                    ),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isActive ? Colors.white : secondaryOn(context),
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
class ListToggleButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const ListToggleButton({
    super.key,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark
          ? candelaNight.withValues(alpha: 0.88)
          : Colors.white.withValues(alpha: 0.92),
      shape: CircleBorder(
        side: BorderSide(
          color: isDark ? Colors.white24 : Colors.black12,
          width: 0.5,
        ),
      ),
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            active ? Icons.map_outlined : Icons.format_list_bulleted_rounded,
            color: isDark ? Colors.white : candelaNight,
            size: 22,
          ),
        ),
      ),
    );
  }
}

