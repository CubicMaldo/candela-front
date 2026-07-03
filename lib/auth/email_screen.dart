import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'widgets.dart';
import 'profile_screen.dart';

/// Step 2 of registration — collects the email & password that will back the
/// new account. Styled with the same dark Candela aesthetic as the login flow.
class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _emailCtrl.text.trim().isNotEmpty && _passwordCtrl.text.isNotEmpty;

  void _continue() {
    if (!_canContinue) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: candelaNight,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            spacingScreen,
            8,
            spacingScreen,
            24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CandelaBackButton(),
              const SizedBox(height: 28),
              Text(
                'Tu correo y\ncontraseña',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textDarkPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Así vas a entrar a Candela cada vez.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: textDarkSecondary,
                ),
              ),
              const SizedBox(height: 28),
              CandelaTextField(
                label: 'Correo electrónico',
                hint: 'tucorreo@email.com',
                controller: _emailCtrl,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: spacingCardGap),
              CandelaTextField(
                label: 'Contraseña',
                hint: 'Al menos 8 caracteres',
                controller: _passwordCtrl,
                focusNode: _passwordFocus,
                obscureText: _obscurePassword,
                keyboardType: TextInputType.visiblePassword,
                suffixIcon: GestureDetector(
                  onTap: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: textDarkSecondary,
                  ),
                ),
              ),
              const Spacer(),
              ListenableBuilder(
                listenable: Listenable.merge([_emailCtrl, _passwordCtrl]),
                builder: (ctx, _) => CandelaButton(
                  label: 'Continuar',
                  onTap: _canContinue ? _continue : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
