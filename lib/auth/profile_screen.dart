import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import '../app/home_shell.dart';
import 'widgets.dart';

class ProfileScreen extends StatefulWidget {
  final String email;
  final String password;

  const ProfileScreen({required this.email, required this.password, super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _usernameFocus = FocusNode();

  DateTime? _birthDate;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _nameFocus.dispose();
    _usernameFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty &&
      _usernameCtrl.text.trim().isNotEmpty &&
      _birthDate != null &&
      !_loading;

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20),
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year - 13), // server enforces 18+; allow selecting
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: candelaAmber,
            onPrimary: Colors.white,
            surface: kBg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _register() async {
    if (!_canSubmit) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final birthDate =
        '${_birthDate!.year.toString().padLeft(4, '0')}'
        '-${_birthDate!.month.toString().padLeft(2, '0')}'
        '-${_birthDate!.day.toString().padLeft(2, '0')}';

    try {
      final result = await AuthService.register(
        email: widget.email,
        username: _usernameCtrl.text.trim(),
        password: widget.password,
        birthDate: birthDate,
      );
      await TokenStorage.save(result.token);
      if (!mounted) return;
      // Replace the entire auth stack with the main app shell
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
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Progress bar ──────────────────────────────────────────────
              const ProgressTopBar(step: 3, total: 4),
              const SizedBox(height: 30),

              // ── Heading ───────────────────────────────────────────────────
              Text(
                'Set up your profile',
                style: jakartaSans(
                  size: 27,
                  weight: FontWeight.w800,
                  letterSpacing: -0.03 * 27,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This is how other locals will see you.',
                style: jakartaSans(
                  size: 15,
                  weight: FontWeight.w500,
                  color: kMuted,
                ),
              ),
              const SizedBox(height: 24),

              // ── Scrollable form ───────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar uploader
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Photo upload coming soon.',
                                  style: jakartaSans(
                                    size: 14,
                                    weight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: kText,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          },
                          child: SizedBox(
                            width: 104,
                            height: 104,
                            child: Stack(
                              children: [
                                Container(
                                  width: 104,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: kField,
                                    border: Border.all(
                                      color: kBorder,
                                      width: 1.5,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.photo_camera_outlined,
                                    size: 28,
                                    color: kMuted,
                                  ),
                                ),
                                Positioned(
                                  right: -2,
                                  bottom: -2,
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: candelaAmber,
                                      border: Border.all(color: kBg, width: 3),
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Full name
                      CandelaField(
                        label: 'Full name',
                        placeholder: 'Your name',
                        controller: _nameCtrl,
                        focusNode: _nameFocus,
                        keyboardType: TextInputType.name,
                      ),
                      const SizedBox(height: 16),

                      // Username
                      CandelaField(
                        label: 'Username',
                        placeholder: 'yourhandle',
                        controller: _usernameCtrl,
                        focusNode: _usernameFocus,
                        keyboardType: TextInputType.text,
                        leading: Text(
                          '@',
                          style: jakartaSans(
                            size: 17,
                            weight: FontWeight.w600,
                            color: kMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Birth date (date picker trigger)
                      _DateField(date: _birthDate, onTap: _pickBirthDate),
                      const SizedBox(height: 18),

                      // Gamification incentive
                      const GamificationChip(
                        '+50 points for completing your profile',
                      ),

                      // Error message
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: kSoftRed,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: candelaAmber,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: jakartaSans(
                                    size: 13.5,
                                    weight: FontWeight.w600,
                                    color: candelaAmber,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── CTA ───────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ListenableBuilder(
                  listenable: Listenable.merge([_nameCtrl, _usernameCtrl]),
                  builder: (ctx, _) => PrimaryButton(
                    label: 'Start exploring',
                    onTap: _canSubmit ? _register : null,
                    color: _canSubmit ? kGreen : const Color(0xFFCBCDCA),
                    loading: _loading,
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

// ─── Date field (read-only, opens system date picker on tap) ─────────────────
class _DateField extends StatelessWidget {
  final DateTime? date;
  final VoidCallback onTap;

  const _DateField({required this.date, required this.onTap});

  String get _label {
    if (date == null) return '';
    return '${date!.day.toString().padLeft(2, '0')} / '
        '${date!.month.toString().padLeft(2, '0')} / '
        '${date!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of birth',
          style: jakartaSans(
            size: 13,
            weight: FontWeight.w600,
            color: kMuted,
            letterSpacing: -0.01 * 13,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: kField,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: kMuted,
                ),
                const SizedBox(width: 10),
                Text(
                  date == null ? 'DD / MM / YYYY' : _label,
                  style: jakartaSans(
                    size: 17,
                    weight: date == null ? FontWeight.w500 : FontWeight.w600,
                    color: date == null ? kMuted : kText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
