import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../app/home_shell.dart';
import 'widgets.dart';

const _underageMessage = 'Pronto Candela estará disponible para ti.';

/// Final step of the Google sign-up: the email is already verified by Google,
/// so only the username and birth date (18+) remain.
class GoogleCompleteScreen extends StatefulWidget {
  final String idToken;
  final String email;

  const GoogleCompleteScreen({
    required this.idToken,
    required this.email,
    super.key,
  });

  @override
  State<GoogleCompleteScreen> createState() => _GoogleCompleteScreenState();
}

class _GoogleCompleteScreenState extends State<GoogleCompleteScreen> {
  final _usernameCtrl = TextEditingController();
  final _usernameFocus = FocusNode();

  DateTime? _birthDate;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _usernameFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _usernameCtrl.text.trim().isNotEmpty && _birthDate != null && !_loading;

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
      final result = await ApiService.registerWithGoogle(
        idToken: widget.idToken,
        username: _usernameCtrl.text.trim(),
        birthDate: _formatBirthDate(birthDate),
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
              const CandelaBackButton(),
              const SizedBox(height: 28),
              Text(
                'Ya casi estás',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textDarkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tu cuenta de Google está lista. Completa tu perfil.',
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
                      // Verified Google email — informative, not editable.
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: surfaceDark,
                          borderRadius: BorderRadius.circular(radiusMedium),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.mail_outline_rounded,
                              size: 18,
                              color: textDarkSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.email,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textDarkPrimary,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: candelaSage,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: spacingCardGap),
                      CandelaTextField(
                        label: 'Nombre de usuario',
                        hint: 'tu_usuario',
                        controller: _usernameCtrl,
                        focusNode: _usernameFocus,
                        keyboardType: TextInputType.text,
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
              ListenableBuilder(
                listenable: _usernameCtrl,
                builder: (ctx, _) => CandelaButton(
                  label: 'Crear mi cuenta',
                  loading: _loading,
                  onTap: _canSubmit ? _submit : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
