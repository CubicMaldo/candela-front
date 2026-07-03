/// App-wide configuration constants.
///
/// Single source of truth for values that were previously duplicated across
/// services and screens (per CLAUDE.md: "API base URL configured as a single
/// constant, not hardcoded per screen").
library;

/// Base URL for all `/api/...` requests. `10.0.2.2` is the host loopback as
/// seen from the Android emulator.
const String apiBaseUrl = 'http://10.0.2.2:8080';

/// Default network timeout applied to every HTTP request.
const Duration apiTimeout = Duration(seconds: 15);

/// Fallback map center used when the device location is unavailable
/// (Barranquilla).
const double fallbackLat = 10.9685;
const double fallbackLon = -74.7813;
