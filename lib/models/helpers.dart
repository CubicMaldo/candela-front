

// Data models for the Candela API (MVP 1.0). Field names mirror the JSON
// response keys documented in CANDELA_API_CHANGELOG.md sections 4-6.


// ─── Relative time helpers ────────────────────────────────────────────────────
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inSeconds < 60) return 'justo ahora';
  if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
  if (d.inHours < 24) return 'hace ${d.inHours} h';
  if (d.inDays < 7) return 'hace ${d.inDays} d';
  return 'hace ${(d.inDays / 7).floor()} sem';
}

String countdownLabel(Duration d) {
  if (d.inSeconds <= 0) return 'expirado';
  if (d.inHours >= 24) return '${d.inDays}d ${d.inHours % 24}h restantes';
  if (d.inHours >= 1) return '${d.inHours}h ${d.inMinutes % 60}m restantes';
  return '${d.inMinutes}m restantes';
}

/// Human distance label: "240 m" under a km, "4.4 km" above.
String distanceLabel(double meters) {
  if (meters < 1000) return '${meters.round()} m';
  return '${(meters / 1000).toStringAsFixed(1)} km';
}


// ─── Place category display labels ────────────────────────────────────────────
/// Spanish display label for an API place category code. The raw codes
/// ('CAFE', 'NIGHTCLUB'…) must never reach the UI.
String categoryLabel(String category) {
  return switch (category.toUpperCase()) {
    'CAFE' => 'Café',
    'RESTAURANT' => 'Restaurante',
    'BAR' => 'Bar',
    'NIGHTCLUB' => 'Rumba',
    'PARK' => 'Parque',
    'UNIVERSITY' => 'Universidad',
    _ => category,
  };
}

