import 'enums.dart';


// ─── Place ────────────────────────────────────────────────────────────────────
class Place {
  final String placeId;
  final String name;
  final String? description;
  final String category;
  final double lat;
  final double lon;
  final int geofenceMeters;
  final String? minorSuitability;
  final bool isVerified;
  final bool isActive;
  final bool isFollowed;
  final int activeCheckinsCount;
  final DateTime? lastCheckinAt;
  final int followerCount;
  final double? distance;

  const Place({
    required this.placeId,
    required this.name,
    this.description,
    required this.category,
    required this.lat,
    required this.lon,
    required this.geofenceMeters,
    this.minorSuitability,
    required this.isVerified,
    required this.isActive,
    required this.isFollowed,
    required this.activeCheckinsCount,
    this.lastCheckinAt,
    required this.followerCount,
    this.distance,
  });

  factory Place.fromJson(Map<String, dynamic> j) => Place(
    placeId: (j['place_id'] ?? '').toString(),
    name: (j['name'] ?? '').toString(),
    description: j['description'] as String?,
    category: (j['category'] ?? '').toString(),
    lat: (j['lat'] as num?)?.toDouble() ?? 0,
    lon: (j['lon'] as num?)?.toDouble() ?? 0,
    geofenceMeters: parseInt(j['geofence_meters']),
    minorSuitability: j['minor_suitability'] as String?,
    isVerified: j['is_verified'] == true,
    isActive: j['is_active'] == true,
    isFollowed: j['is_followed'] == true,
    activeCheckinsCount: parseInt(j['active_checkins_count']),
    lastCheckinAt: parseDateOrNull(j['last_checkin_at']),
    followerCount: parseInt(j['follower_count']),
    distance: (j['distance'] as num?)?.toDouble(),
  );

  Place copyWith({bool? isFollowed, int? followerCount}) => Place(
    placeId: placeId,
    name: name,
    description: description,
    category: category,
    lat: lat,
    lon: lon,
    geofenceMeters: geofenceMeters,
    minorSuitability: minorSuitability,
    isVerified: isVerified,
    isActive: isActive,
    isFollowed: isFollowed ?? this.isFollowed,
    activeCheckinsCount: activeCheckinsCount,
    lastCheckinAt: lastCheckinAt,
    followerCount: followerCount ?? this.followerCount,
    distance: distance,
  );

  Map<String, dynamic> toJson() => {
    'place_id': placeId,
    'name': name,
    if (description != null) 'description': description,
    'category': category,
    'lat': lat,
    'lon': lon,
    'geofence_meters': geofenceMeters,
    if (minorSuitability != null) 'minor_suitability': minorSuitability,
    'is_verified': isVerified,
    'is_active': isActive,
    'is_followed': isFollowed,
    'active_checkins_count': activeCheckinsCount,
    if (lastCheckinAt != null)
      'last_checkin_at': lastCheckinAt!.toUtc().toIso8601String(),
    'follower_count': followerCount,
    if (distance != null) 'distance': distance,
  };
}

