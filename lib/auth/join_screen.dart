import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../app/home_shell.dart';
import '../app/widgets.dart' show CandelaBackButton;
import 'widgets.dart';

const _underageMessage = 'Pronto Candela estará disponible para ti.';
const _underageMessage = 'Debes ser mayor de 18 años para usar Candela.';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  DateTime? _birthDate;
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _usernameCtrl.text.trim().isNotEmpty &&
      _emailCtrl.text.trim().isNotEmpty &&
      _passwordCtrl.text.isNotEmpty &&
      _birthDate != null &&
      !_loading;

  int _ageOf(DateTime birthDate) {
    final now = DateTime.now();
    var age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  String _formatBirthDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      builder: (ctx, child) => Theme(data: CandleTheme.dark(), child: child!),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    final birthDate = _birthDate!;
    if (_ageOf(birthDate) < 18) {
      setState(() => _error = _underageMessage);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService.register(
        email: _emailCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passwordCtrl.text,
        birthDate: _formatBirthDate(birthDate),
      );
      await TokenStorage.saveSession(result);
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
    final birthDate = _birthDate;
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
              const CandelaBackButton(dark: true),
              const SizedBox(height: 28),
              Text(
                'Crea tu cuenta',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textDarkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Toma menos de un minuto.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: textDarkSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CandelaTextField(
                        label: 'Nombre de usuario',
                        hint: 'tu_usuario',
                        controller: _usernameCtrl,
                        focusNode: _usernameFocus,
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: spacingCardGap),
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
                      const SizedBox(height: spacingCardGap),
                      CandelaTextField(
                        label: 'Fecha de nacimiento',
                        hint: 'AAAA-MM-DD',
                        controller: TextEditingController(
                          text: birthDate == null
                              ? ''
                              : _formatBirthDate(birthDate),
                        ),
                        readOnly: true,
                        onTap: _pickBirthDate,
                        suffixIcon: const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: textDarkSecondary,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        CandelaErrorBanner(_error!),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: spacingCardGap),
              CandelaButton(
                label: 'Crear mi cuenta',
                loading: _loading,
                onTap: _canSubmit ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
