import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/google_signin_service.dart';
import '../app/home_shell.dart';
import 'google_flow_button.dart';
import 'widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailCtrl.text.trim().isNotEmpty &&
      _passwordCtrl.text.isNotEmpty &&
      !_loading;

  Future<void> _login() async {
    if (!_canSubmit) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      await TokenStorage.save(result.token);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
        (_) => false,
      );
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Algo salió mal. Inténtalo de nuevo.';
        _loading = false;
      });
    }
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
                'Entrar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textDarkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Vuelve a lo que está prendido.',
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
                hint: 'Tu contraseña',
                controller: _passwordCtrl,
                focusNode: _passwordFocus,
                obscureText: _obscure,
                keyboardType: TextInputType.visiblePassword,
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: textDarkSecondary,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                CandelaErrorBanner(_error!),
              ],
              const Spacer(),
              ListenableBuilder(
                listenable: Listenable.merge([_emailCtrl, _passwordCtrl]),
                builder: (ctx, _) => CandelaButton(
                  label: 'Entrar',
                  loading: _loading,
                  onTap: _canSubmit ? _login : null,
                ),
              ),
              if (GoogleSignInService.isConfigured) ...[
                const SizedBox(height: 16),
                const AuthDivider(),
                const SizedBox(height: 16),
                GoogleFlowButton(
                  onError: (msg) => setState(() => _error = msg),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
