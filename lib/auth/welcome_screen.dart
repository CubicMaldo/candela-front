import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'widgets.dart';
import 'join_screen.dart';
import 'login_screen.dart';

/// First screen for unauthenticated users — minimal, dark, premium. The
/// Candela wordmark over near-black is the most authentic expression of the
/// brand (see CANDELA_ESPECIFICACIONES_FUNCIONALES.md §3.5).
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: candelaNight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingScreen,
            vertical: 32,
          ),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Center(
                child: Column(
                  children: [
                    Text(
                      'Candela',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 40,
                        fontWeight: FontWeight.w700,
                        color: candelaAmber,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Lo que está prendido',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: textDarkSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 4),
              CandelaButton(
                label: 'Entrar',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
              ),
              const SizedBox(height: spacingCardGap),
              CandelaButton(
                label: 'Crear cuenta',
                primary: false,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JoinScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
