import 'package:flutter/material.dart';
import '../theme.dart';
import 'widgets.dart';
import 'email_screen.dart';

class JoinScreen extends StatelessWidget {
  const JoinScreen({super.key});

  void _comingSoon(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$provider sign-in coming soon.',
          style: jakartaSans(size: 14, weight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: kText,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 22, 26, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top: back + logo ─────────────────────────────────────────
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: kField,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 26,
                        color: kText,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const LokalLogo(size: 30),
                ],
              ),
              const SizedBox(height: 34),

              // ── Heading ───────────────────────────────────────────────────
              Text(
                'Create your account',
                style: jakartaSans(
                  size: 30,
                  weight: FontWeight.w800,
                  letterSpacing: -0.03 * 30,
                  height: 1.08,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Takes less than a minute.',
                style: jakartaSans(
                  size: 16,
                  weight: FontWeight.w500,
                  color: kMuted,
                ),
              ),
              const SizedBox(height: 30),

              // ── Social sign-in ────────────────────────────────────────────
              SocialButton(
                apple: true,
                onTap: () => _comingSoon(context, 'Apple'),
              ),
              const SizedBox(height: 12),
              SocialButton(
                apple: false,
                onTap: () => _comingSoon(context, 'Google'),
              ),

              // ── Divider ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Row(
                  children: [
                    const Expanded(child: Divider(color: kBorder, thickness: 1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text(
                        'or',
                        style: jakartaSans(
                          size: 13,
                          weight: FontWeight.w600,
                          color: kMuted,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: kBorder, thickness: 1)),
                  ],
                ),
              ),

              // ── Email option ──────────────────────────────────────────────
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EmailScreen()),
                ),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kBorder, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.mail_outline_rounded,
                        size: 20,
                        color: kText,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Continue with email',
                        style: jakartaSans(
                          size: 16,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // ── Terms ─────────────────────────────────────────────────────
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: jakartaSans(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: kMuted,
                      height: 1.5,
                    ),
                    children: [
                      const TextSpan(text: 'By continuing you agree to our '),
                      TextSpan(
                        text: 'Terms',
                        style: jakartaSans(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: kText,
                        ),
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: jakartaSans(
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: kText,
                        ),
                      ),
                      const TextSpan(text: '.'),
                    ],
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
