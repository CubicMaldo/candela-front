import 'package:flutter/material.dart';
import '../theme.dart';
import 'widgets.dart';
import 'profile_screen.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus    = FocusNode();
  final _passwordFocus = FocusNode();

  String _mode = 'Email'; // Email | Phone
  bool _marketingOptIn = true;
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
      _emailCtrl.text.trim().isNotEmpty &&
      _passwordCtrl.text.isNotEmpty;

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
      backgroundColor: kBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Progress bar ──────────────────────────────────────────────
              const ProgressTopBar(step: 2, total: 4),
              const SizedBox(height: 30),

              // ── Heading ───────────────────────────────────────────────────
              Text(
                'How should we\nreach you?',
                style: jakartaSans(
                  size: 27,
                  weight: FontWeight.w800,
                  letterSpacing: -0.03 * 27,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "We'll use this to set up your account.",
                style: jakartaSans(
                  size: 15,
                  weight: FontWeight.w500,
                  color: kMuted,
                ),
              ),
              const SizedBox(height: 22),

              // ── Email / Phone toggle ──────────────────────────────────────
              SegToggle(
                options: const ['Email', 'Phone'],
                active: _mode,
                onChanged: (v) {
                  setState(() => _mode = v);
                  if (v == 'Phone') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Phone sign-up coming soon.',
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
                    setState(() => _mode = 'Email');
                  }
                },
              ),
              const SizedBox(height: 18),

              // ── Scrollable form area ──────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email field
                      LokalField(
                        label: 'Email address',
                        placeholder: 'you@email.com',
                        controller: _emailCtrl,
                        focusNode: _emailFocus,
                        keyboardType: TextInputType.emailAddress,
                        leading: const Icon(
                          Icons.mail_outline_rounded,
                          size: 20,
                          color: kMuted,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password field
                      LokalField(
                        label: 'Password',
                        placeholder: 'At least 8 characters',
                        controller: _passwordCtrl,
                        focusNode: _passwordFocus,
                        obscureText: _obscurePassword,
                        keyboardType: TextInputType.visiblePassword,
                        leading: GestureDetector(
                          onTap: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                          child: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: kMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Marketing opt-in
                      GestureDetector(
                        onTap: () => setState(
                          () => _marketingOptIn = !_marketingOptIn,
                        ),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: _marketingOptIn ? kGreen : Colors.transparent,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: _marketingOptIn ? kGreen : kBorder,
                                  width: 1.5,
                                ),
                              ),
                              child: _marketingOptIn
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 11,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              'Email me local picks & event drops',
                              style: jakartaSans(
                                size: 13,
                                weight: FontWeight.w600,
                                color: kMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // ── CTA pinned above keyboard ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ListenableBuilder(
                  listenable: Listenable.merge([_emailCtrl, _passwordCtrl]),
                  builder: (ctx, _) => PrimaryButton(
                    label: 'Continue →',
                    onTap: _canContinue ? _continue : null,
                    color: _canContinue ? kRed : const Color(0xFFCBCDCA),
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
