import 'package:flutter/material.dart';

import '../app/home_shell.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/google_signin_service.dart';
import 'google_complete_screen.dart';
import 'widgets.dart';

/// Self-contained "Continuar con Google" flow: native sign-in → ID token →
/// POST /api/auth/google → HomeShell, or the complete-profile screen when the
/// email has no Candela account yet. Renders nothing while the Google Cloud
/// client ID is not configured (see config.dart).
class GoogleFlowButton extends StatefulWidget {
  /// Called with a user-facing message when the flow fails. Cancelling the
  /// account picker is not a failure.
  final ValueChanged<String> onError;

  const GoogleFlowButton({required this.onError, super.key});

  @override
  State<GoogleFlowButton> createState() => _GoogleFlowButtonState();
}

class _GoogleFlowButtonState extends State<GoogleFlowButton> {
  bool _loading = false;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    try {
      final idToken = await GoogleSignInService.obtainIdToken();
      if (idToken == null) {
        // User cancelled the picker.
        if (mounted) setState(() => _loading = false);
        return;
      }

      final outcome = await ApiService.loginWithGoogle(idToken: idToken);
      if (!mounted) return;

      if (outcome.needsRegistration) {
        setState(() => _loading = false);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => GoogleCompleteScreen(
              idToken: idToken,
              email: outcome.pendingEmail!,
            ),
          ),
        );
        return;
      }

      await TokenStorage.saveSession(outcome.auth!);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.onError(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      widget.onError('No pudimos conectar con Google. Inténtalo de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!GoogleSignInService.isConfigured) return const SizedBox.shrink();
    return GoogleAuthButton(loading: _loading, onTap: _signIn);
  }
}
