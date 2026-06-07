import 'package:flutter/material.dart';
import '../theme.dart';
import 'widgets.dart';
import 'join_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 16, 26, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top: logo + wordmark ─────────────────────────────────────
              Row(
                children: [
                  const LokalLogo(size: 36),
                  const SizedBox(width: 11),
                  const Wordmark(size: 21),
                ],
              ),

              const Spacer(),

              // ── Middle: headline block ────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const GamificationChip('Level up your city'),
                  const SizedBox(height: 18),
                  Text(
                    'Your city,\nunlocked.',
                    style: jakartaSans(
                      size: 42,
                      weight: FontWeight.w800,
                      letterSpacing: -0.035 * 42,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Discover the spots locals actually love — and earn your way to local legend.',
                    style: jakartaSans(
                      size: 16.5,
                      weight: FontWeight.w500,
                      color: kMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 26),
                  // Social proof
                  Row(
                    children: [
                      const AvatarCluster(count: 4),
                      const SizedBox(width: 11),
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            style: jakartaSans(
                              size: 13.5,
                              weight: FontWeight.w600,
                              color: kMuted,
                            ),
                            children: [
                              TextSpan(
                                text: '12,400 locals',
                                style: jakartaSans(
                                  size: 13.5,
                                  weight: FontWeight.w600,
                                  color: kText,
                                ),
                              ),
                              const TextSpan(text: ' exploring nearby'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const Spacer(),

              // ── Bottom: CTAs ──────────────────────────────────────────────
              Column(
                children: [
                  PrimaryButton(
                    label: 'Get started',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JoinScreen()),
                    ),
                  ),
                  GhostButton(
                    label: 'I already have an account',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
