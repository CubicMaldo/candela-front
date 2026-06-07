import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'services/auth_service.dart';
import 'auth/welcome_screen.dart';
import 'app/home_shell.dart';
import 'auth/widgets.dart' show LokalLogo;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const LokalApp());
}

class LokalApp extends StatelessWidget {
  const LokalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lokal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeShell(),
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
            backgroundColor: kBg,
            body: Center(child: LokalLogo(size: 56)),
          );
        }
        final hasToken = (snap.data ?? '').isNotEmpty;
        return hasToken ? const HomeShell() : const WelcomeScreen();
      },
    );
  }
}
