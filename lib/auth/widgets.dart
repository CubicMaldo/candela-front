import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

// ─── Candela auth screen primitives ──────────────────────────────────────────
// Shared building blocks for the dark, minimal Candela auth flow
// (welcome / login / join / google-complete screens).

const _softError = Color(0xFFE2726A);

TextStyle _candelaText({
  double size = 15,
  FontWeight weight = FontWeight.w500,
  Color color = textDarkPrimary,
}) => GoogleFonts.plusJakartaSans(
  fontSize: size,
  fontWeight: weight,
  color: color,
);

/// Pill-shaped CTA used throughout the dark auth flow. `primary` renders an
/// amber-filled button; otherwise a transparent button with an amber border.
class CandelaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final bool loading;

  const CandelaButton({
    required this.label,
    this.onTap,
    this.primary = true,
    this.loading = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = _candelaText(
      size: 15,
      weight: FontWeight.w600,
      color: primary ? Colors.white : candelaAmber,
    );
    final spinner = SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: primary ? Colors.white : candelaAmber,
      ),
    );
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: primary
          ? ElevatedButton(
              onPressed: (loading || onTap == null) ? null : onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: candelaAmber,
                disabledBackgroundColor: candelaAmber.withValues(alpha: 0.45),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusPill),
                ),
              ),
              child: loading ? spinner : Text(label, style: textStyle),
            )
          : OutlinedButton(
              onPressed: (loading || onTap == null) ? null : onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: candelaAmber, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(radiusPill),
                ),
              ),
              child: loading ? spinner : Text(label, style: textStyle),
            ),
    );
  }
}

/// Text field for the dark auth screens: subtle inactive border, amber on
/// focus, 8px radius — matches the Candela design tokens (radiusMedium).
class CandelaTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final bool obscureText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final bool readOnly;
  final VoidCallback? onTap;

  const CandelaTextField({
    required this.label,
    this.hint,
    required this.controller,
    this.focusNode,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.readOnly = false,
    this.onTap,
    super.key,
  });

  @override
  State<CandelaTextField> createState() => _CandelaTextFieldState();
}

class _CandelaTextFieldState extends State<CandelaTextField> {
  late final FocusNode _focusNode = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: _candelaText(
            size: 13,
            weight: FontWeight.w600,
            color: textDarkSecondary,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: _focused
                ? candelaAmber.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(radiusMedium),
            border: Border.all(
              color: _focused ? candelaAmber : borderInactive,
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            style: _candelaText(size: 16, weight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: _candelaText(
                size: 16,
                weight: FontWeight.w500,
                color: textDarkSecondary,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: widget.suffixIcon,
            ),
          ),
        ),
      ],
    );
  }
}

/// "Continuar con Google" for the dark auth flow — white pill per Google's
/// branding guidelines, sized and rounded to match CandelaButton.
class GoogleAuthButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool loading;

  const GoogleAuthButton({this.onTap, this.loading = false, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: (loading || onTap == null) ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusPill),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: candelaNight,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleMark(),
                  const SizedBox(width: 10),
                  Text(
                    'Continuar con Google',
                    style: _candelaText(
                      size: 15,
                      weight: FontWeight.w600,
                      color: candelaNight,
                    ),
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
    arc(const Color(0xFF34A853), 0.07, 1.57); // green (bottom-right)
    arc(const Color(0xFFFBBC05), 1.64, 0.78); // yellow
    arc(const Color(0xFFEA4335), 2.42, 1.05); // red   (left)

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

/// Thin "o" divider between the email buttons and the Google button.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: surfaceDark, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'o',
            style: _candelaText(
              size: 13,
              weight: FontWeight.w500,
              color: textDarkSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: surfaceDark, thickness: 1)),
      ],
    );
  }
}

/// Soft, non-harsh error banner for the auth screens — muted red on a
/// translucent fill, never the alarming saturated red of system errors.
class CandelaErrorBanner extends StatelessWidget {
  final String message;
  const CandelaErrorBanner(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _softError.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: _softError, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: _candelaText(
                size: 13.5,
                weight: FontWeight.w600,
                color: _softError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
