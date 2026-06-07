import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../app/home_shell.dart';
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
      final result = await AuthService.login(
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
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: kField, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.chevron_left_rounded, size: 26, color: kText),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const LokalLogo(size: 30),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'Welcome back',
                style: jakartaSans(
                    size: 30, weight: FontWeight.w800, letterSpacing: -0.03 * 30, height: 1.1),
              ),
              const SizedBox(height: 6),
              Text('Log in to keep exploring your city.',
                  style: jakartaSans(size: 15, weight: FontWeight.w500, color: kMuted)),
              const SizedBox(height: 28),
              LokalField(
                label: 'Email address',
                placeholder: 'you@email.com',
                controller: _emailCtrl,
                focusNode: _emailFocus,
                keyboardType: TextInputType.emailAddress,
                leading: const Icon(Icons.mail_outline_rounded, size: 20, color: kMuted),
              ),
              const SizedBox(height: 14),
              LokalField(
                label: 'Password',
                placeholder: 'Your password',
                controller: _passwordCtrl,
                focusNode: _passwordFocus,
                obscureText: _obscure,
                keyboardType: TextInputType.visiblePassword,
                leading: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  child: Icon(
                    _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: kMuted,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                      color: kSoftRed, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: kRed, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: jakartaSans(
                                size: 13.5, weight: FontWeight.w600, color: kRed)),
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ListenableBuilder(
                  listenable: Listenable.merge([_emailCtrl, _passwordCtrl]),
                  builder: (ctx, _) => PrimaryButton(
                    label: 'Log in',
                    loading: _loading,
                    onTap: _canSubmit ? _login : null,
                    color: _canSubmit ? kRed : const Color(0xFFCBCDCA),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
