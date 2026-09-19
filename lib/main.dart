import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'package:candela_front/services/api/api_client.dart';
import 'services/theme_storage.dart';
import 'providers/theme_provider.dart';
import 'auth/welcome_screen.dart';
import 'app/home_shell.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  
  final initialTheme = await ThemeStorage.load();
  
  ApiClient.onSessionExpired = () => handleSessionExpired();
  
  runApp(
    ProviderScope(
      overrides: [
        themeProvider.overrideWith(() => ThemeNotifier(initialTheme)),
      ],
      child: const CandelaApp(),
    ),
  );
}

bool _handlingSessionExpired = false;

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

class CandelaApp extends ConsumerWidget {
  const CandelaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeProvider);
    return MaterialApp(
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: scaffoldMessengerKey,
      title: 'Candela',
      debugShowCheckedModeBanner: false,
      theme: CandleTheme.light(),
      darkTheme: CandleTheme.dark(),
      themeMode: mode,
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
    );
  }
}

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

