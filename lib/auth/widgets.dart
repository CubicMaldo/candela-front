import 'package:flutter/material.dart';
import '../theme.dart';

// ─── Logo ─────────────────────────────────────────────────────────────────────
// Squircle split diagonally red (top-left) / green (bottom-right) with a white
// locator dot at the centre — matches the design's brand mark exactly.
class LokalLogo extends StatelessWidget {
  final double size;
  const LokalLogo({this.size = 40, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.30),
        gradient: const LinearGradient(
          begin: Alignment(-1, -1),
          end: Alignment(1, 1),
          stops: [0.0, 0.495, 0.505, 1.0],
          colors: [kRed, kRed, kGreen, kGreen],
        ),
        boxShadow: [
          BoxShadow(
            color: kSoftRed,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: size * 0.26,
          height: size * 0.26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Wordmark ─────────────────────────────────────────────────────────────────
class Wordmark extends StatelessWidget {
  final double size;
  const Wordmark({this.size = 22, super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Lokal',
      style: jakartaSans(
        size: size,
        weight: FontWeight.w800,
        letterSpacing: -0.03 * size,
      ),
    );
  }
}

// ─── Primary Button ───────────────────────────────────────────────────────────
class PrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool loading;

  const PrimaryButton({
    required this.label,
    this.onTap,
    this.color,
    this.loading = false,
    super.key,
  });

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.color ?? kRed;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: bg.withValues(alpha: 0.38),
                blurRadius: 24,
                offset: const Offset(0, 10),
                spreadRadius: -8,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : Text(
                  widget.label,
                  style: jakartaSans(
                    size: 17,
                    weight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.01 * 17,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Ghost Button ─────────────────────────────────────────────────────────────
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const GhostButton({required this.label, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        child: Text(
          label,
          style: jakartaSans(
            size: 15.5,
            weight: FontWeight.w600,
            letterSpacing: -0.01 * 15.5,
          ),
        ),
      ),
    );
  }
}

// ─── Social Button (Apple / Google) ──────────────────────────────────────────
class SocialButton extends StatelessWidget {
  final bool apple;
  final VoidCallback? onTap;

  const SocialButton({required this.apple, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final bg = apple ? const Color(0xFF111111) : Colors.white;
    final fg = apple ? Colors.white : kText;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: apple ? null : Border.all(color: kBorder, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (apple) ...[
              Icon(Icons.apple, color: fg, size: 20),
              const SizedBox(width: 10),
            ] else ...[
              _GoogleMark(),
              const SizedBox(width: 10),
            ],
            Text(
              'Continue with ${apple ? 'Apple' : 'Google'}',
              style: jakartaSans(size: 16, weight: FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: _GooglePainter()),
    );
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final sw = r * 0.42;
    final inner = r - sw / 2;

    void arc(Color color, double start, double sweep) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: inner),
        start,
        sweep,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.butt,
      );
    }

    // Approximate four-colour Google ring
    arc(const Color(0xFF4285F4), -1.65, 1.72); // blue  (right + top)
    arc(const Color(0xFF34A853),  0.07, 1.57); // green (bottom-right)
    arc(const Color(0xFFFBBC05),  1.64, 0.78); // yellow
    arc(const Color(0xFFEA4335),  2.42, 1.05); // red   (left)

    // White gap for the horizontal bar (right side)
    canvas.drawRect(
      Rect.fromLTWH(c.dx, c.dy - sw * 0.6, r, sw * 1.2),
      Paint()..color = Colors.white,
    );
    arc(const Color(0xFF4285F4), -0.1, 0.2); // re-draw blue over gap
  }

  @override
  bool shouldRepaint(_GooglePainter _) => false;
}

// ─── Field ────────────────────────────────────────────────────────────────────
class LokalField extends StatefulWidget {
  final String? label;
  final String placeholder;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? leading;
  final bool readOnly;
  final VoidCallback? onTap;

  const LokalField({
    this.label,
    required this.placeholder,
    required this.controller,
    required this.focusNode,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.leading,
    this.readOnly = false,
    this.onTap,
    super.key,
  });

  @override
  State<LokalField> createState() => _LokalFieldState();
}

class _LokalFieldState extends State<LokalField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = widget.focusNode.hasFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: jakartaSans(
              size: 13,
              weight: FontWeight.w600,
              color: kMuted,
              letterSpacing: -0.01 * 13,
            ),
          ),
          const SizedBox(height: 8),
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 56,
          decoration: BoxDecoration(
            color: kField,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _focused ? kRed : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: kSoftRed,
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                const SizedBox(width: 16),
                widget.leading!,
                const SizedBox(width: 8),
              ] else
                const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  obscureText: widget.obscureText,
                  keyboardType: widget.keyboardType,
                  readOnly: widget.readOnly,
                  onTap: widget.onTap,
                  style: jakartaSans(size: 17, weight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    hintStyle: jakartaSans(
                      size: 17,
                      weight: FontWeight.w500,
                      color: kMuted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Segmented Toggle ─────────────────────────────────────────────────────────
class SegToggle extends StatelessWidget {
  final List<String> options;
  final String active;
  final ValueChanged<String> onChanged;

  const SegToggle({
    required this.options,
    required this.active,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kField,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: options.map((o) {
          final on = o == active;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: on ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: on
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  o,
                  style: jakartaSans(
                    size: 15,
                    weight: FontWeight.w600,
                    color: on ? kText : kMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Gamification Chip ────────────────────────────────────────────────────────
// The spark icon reproduces the 8-pointed star from the design's ICON.spark.
class GamificationChip extends StatelessWidget {
  final String label;
  final bool red;

  const GamificationChip(this.label, {this.red = false, super.key});

  @override
  Widget build(BuildContext context) {
    final color = red ? kRed : kGreen;
    final bg = red ? kSoftRed : kSoftGreen;
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 7, 13, 7),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 13,
            height: 13,
            child: CustomPaint(painter: _SparkPainter(color)),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: jakartaSans(
              size: 12.5,
              weight: FontWeight.w700,
              color: color,
              letterSpacing: 0.01 * 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  final Color color;
  const _SparkPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    // 8-pointed star: M12 2 l2.2 6.4 L21 11 l-6.8 2.6 L12 20 l-2.2-6.4 L3 11 l6.8-2.6z
    // Normalise to 0..1 from 0..24 viewBox
    final pts = [
      Offset(12 / 24 * w, 2 / 24 * h),
      Offset(14.2 / 24 * w, 8.4 / 24 * h),
      Offset(21 / 24 * w, 11 / 24 * h),
      Offset(14.2 / 24 * w, 13.6 / 24 * h),
      Offset(12 / 24 * w, 20 / 24 * h),
      Offset(9.8 / 24 * w, 13.6 / 24 * h),
      Offset(3 / 24 * w, 11 / 24 * h),
      Offset(9.8 / 24 * w, 8.4 / 24 * h),
    ];
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.color != color;
}

// ─── Avatar cluster (social proof) ───────────────────────────────────────────
const _avatarColors = [
  Color(0xFFF2B705),
  Color(0xFFE86A5C),
  Color(0xFF5C9CE8),
  Color(0xFF7FB069),
];

class AvatarCluster extends StatelessWidget {
  final int count;
  const AvatarCluster({this.count = 4, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28.0 + (count - 1) * 19.0,
      height: 28,
      child: Stack(
        children: List.generate(count, (i) {
          return Positioned(
            left: i * 19.0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _avatarColors[i % _avatarColors.length],
                border: Border.all(color: kBg, width: 2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─── Progress top bar (back + striped bar) ────────────────────────────────────
class ProgressTopBar extends StatelessWidget {
  final int step;
  final int total;

  const ProgressTopBar({required this.step, required this.total, super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kField,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chevron_left_rounded, size: 26, color: kText),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: kFaint,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: step / total,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: const LinearGradient(
                    colors: [kRed, kGreen],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
