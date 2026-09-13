/// App-wide configuration constants.
///
/// Single source of truth for values that were previously duplicated across
/// services and screens (per CLAUDE.md: "API base URL configured as a single
/// constant, not hardcoded per screen").
library;

/// Base URL for all `/api/...` requests.
///
/// Override per build with `--dart-define=API_BASE_URL=https://api.example.com`.
/// The default is the host loopback as seen from the Android emulator, which is
/// only reachable there — a release build must always pass this define, and
/// must point at `https`, since Android blocks cleartext traffic by default.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:8080',
);

/// Default network timeout applied to every HTTP request.
const Duration apiTimeout = Duration(seconds: 15);

/// Fallback map center used when the device location is unavailable
/// (Barranquilla).
const double fallbackLat = 10.9685;
const double fallbackLon = -74.7813;

/// OAuth client ID of type "Web application" from Google Cloud Console.
/// Must be the SAME value as GOOGLE_CLIENT_ID in candela-api/.env — the API
/// validates the ID token against this audience. Leave empty to hide the
/// "Continuar con Google" button (e.g. while the Cloud project is not set up).
///
/// Setup (Google Cloud Console → APIs & Services → Credentials):
///  1. Create an OAuth client "Web application" → this constant + API env var.
///  2. Create an OAuth client "Android" with the app's package name and the
///     debug/release SHA-1 — no value to copy here; it authorizes the device.
const String googleServerClientId = '';
