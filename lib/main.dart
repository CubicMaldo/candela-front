import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/theme_storage.dart';
import 'auth/welcome_screen.dart';
import 'app/home_shell.dart';

/// Global navigation/messenger handles so non-widget code (e.g. the API layer
/// catching a `SessionExpiredException`) can route back to the welcome screen
/// and surface a snackbar without a `BuildContext`.
final navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// User-forceable dark/light/system override, set from the Settings screen.
final themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Icon brightness is applied per-theme in CandelaApp's builder.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  // Restore the user's saved light/dark/system choice before the first frame
  // so the app opens in the right theme without a flash.
  themeModeNotifier.value = await ThemeStorage.load();
  // Let the API layer trigger an automatic logout — without holding a
  // BuildContext — whenever it sees a 401 or finds the account is gone.
  ApiService.onSessionExpired = () => handleSessionExpired();
  runApp(const CandelaApp());
}

bool _handlingSessionExpired = false;

/// Clears the stored session and routes back to the welcome screen with a
/// brief explanation. Call this wherever `ApiService` throws
/// `SessionExpiredException` (401 from the server, or a missing account).
Future<void> handleSessionExpired() async {
  if (_handlingSessionExpired) return;
  _handlingSessionExpired = true;
  try {
    await TokenStorage.clear();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          'Tu sesión expiró. Vuelve a entrar.',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        margin: const EdgeInsets.all(spacingScreen),
      ),
    );
  } finally {
    _handlingSessionExpired = false;
  }
}

class CandelaApp extends StatelessWidget {
  const CandelaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) => MaterialApp(
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        title: 'Candela',
        debugShowCheckedModeBanner: false,
        theme: CandleTheme.light(),
        darkTheme: CandleTheme.dark(),
        themeMode: mode,
        // Status-bar icons must flip with the theme: dark icons over Sand,
        // light icons over Night — otherwise they vanish in dark mode.
        builder: (context, child) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: isDark
                  ? Brightness.light
                  : Brightness.dark,
              statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const _Root(),
      ),
    );
  }
}

/// Decides the first screen: jump straight into the app if a token is stored,
/// otherwise show the welcome / onboarding flow.
class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  late final Future<String?> _token = TokenStorage.get();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _token,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: candelaNight,
            body: Center(child: CircularProgressIndicator(color: candelaAmber)),
          );
        }
        final hasToken = (snap.data ?? '').isNotEmpty;
        return hasToken ? const HomeShell() : const WelcomeScreen();
      },
    );
  }
}
