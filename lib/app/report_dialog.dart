import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import 'package:candela_front/services/api/api_client.dart';
import 'package:candela_front/services/api/auth_api.dart';
import 'package:candela_front/services/api/users_api.dart';
import 'package:candela_front/services/api/places_api.dart';
import 'package:candela_front/services/api/plans_api.dart';
import 'package:candela_front/services/api/feed_api.dart';
import 'package:candela_front/services/api/checkin_api.dart';
import 'package:candela_front/services/api/misc_api.dart';
import '../services/auth_service.dart' show ApiException;
import 'widgets.dart' show showToast;

/// Shows a dialog to report inappropriate content, users, or places
/// per FRONTEND_GUIDE.md §9 (POST /api/reports).
Future<bool?> showReportDialog(
  BuildContext context, {
  required String targetType,
  required String targetId,
  String? targetName,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => _ReportDialog(
      targetType: targetType,
      targetId: targetId,
      targetName: targetName,
    ),
  );
}

class _ReportDialog extends StatefulWidget {
  final String targetType;
  final String targetId;
  final String? targetName;

  const _ReportDialog({
    required this.targetType,
    required this.targetId,
    this.targetName,
  });

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  static const _reasons = [
    ('Contenido inapropiado', 'INAPPROPRIATE_CONTENT'),
    ('Acoso o intimidación', 'HARASSMENT'),
    ('Spam o publicidad', 'SPAM'),
    ('Contenido falso o engañoso', 'FAKE_CONTENT'),
    ('Otro motivo', 'OTHER'),
  ];

  String _selectedReason = 'INAPPROPRIATE_CONTENT';
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final commentText = _commentCtrl.text.trim();
      await MiscApi.createReport(
        CreateReportRequest(
          targetType: widget.targetType,
          targetId: widget.targetId,
          reason: _selectedReason,
          comment: commentText.isEmpty ? null : commentText,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      showToast(context, 'Gracias por avisarnos. Revisaremos el reporte.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showToast(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showToast(context, 'No se pudo enviar el reporte. Inténtalo de nuevo.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? surfaceDark : Colors.white;

    final typeLabel = switch (widget.targetType.toUpperCase()) {
      'PHOTO' => 'esta foto',
      'USER' => widget.targetName != null ? '@${widget.targetName}' : 'este usuario',
      'PLACE' => widget.targetName ?? 'este lugar',
      _ => 'este contenido',
    };

    return AlertDialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusCard),
      ),
      title: Text(
        'Denunciar $typeLabel',
        style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ayúdanos a mantener la comunidad segura.',
              style: textTheme.bodySmall?.copyWith(color: secondaryOn(context)),
            ),
            const SizedBox(height: 14),
            Text(
              'Motivo',
              style: textTheme.labelSmall?.copyWith(
                color: secondaryOn(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radiusMedium),
                border: Border.all(color: borderInactive.withValues(alpha: 0.5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedReason,
                  dropdownColor: bg,
                  items: [
                    for (final (label, code) in _reasons)
                      DropdownMenuItem(
                        value: code,
                        child: Text(label, style: textTheme.bodyMedium),
                      ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (v) {
                          if (v != null) setState(() => _selectedReason = v);
                        },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Detalles adicionales (opcional)',
              style: textTheme.labelSmall?.copyWith(
                color: secondaryOn(context),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              enabled: !_submitting,
              decoration: InputDecoration(
                hintText: 'Cuéntanos qué sucedió...',
                hintStyle: textTheme.bodySmall?.copyWith(
                  color: secondaryOn(context).withValues(alpha: 0.7),
                ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radiusMedium),
                  borderSide: BorderSide(
                    color: borderInactive.withValues(alpha: 0.5),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(radiusMedium),
                  borderSide: BorderSide(
                    color: borderInactive.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: candelaAmber,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radiusPill),
            ),
          ),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Enviar denuncia'),
        ),
      ],
    );
  }
}

