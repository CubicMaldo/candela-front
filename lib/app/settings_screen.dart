import 'package:flutter/material.dart';
import '../theme.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart' show ApiException, TokenStorage;
import '../auth/welcome_screen.dart';
import '../main.dart' show themeModeNotifier;
import '../services/theme_storage.dart';
import 'widgets.dart';

class SettingsScreen extends StatefulWidget {
  final User profile;
  const SettingsScreen({required this.profile, super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late PrivacyMode _privacy;
  late bool _rankingOptIn;
  bool _busy = false;

  static const _privacyLabels = {
    PrivacyMode.public: 'Público',
    PrivacyMode.friends: 'Solo amigos',
    PrivacyMode.private: 'Privado',
  };

  static const _privacyHints = {
    PrivacyMode.public: 'Cualquier persona puede ver tu perfil completo.',
    PrivacyMode.friends: 'Solo tus amigos ven tu perfil completo.',
    PrivacyMode.private: 'Nadie te encuentra si no es tu amigo.',
  };

  static const _themeLabels = {
    ThemeMode.system: 'Sistema',
    ThemeMode.light: 'Claro',
    ThemeMode.dark: 'Oscuro',
  };

  @override
  void initState() {
    super.initState();
    _privacy = widget.profile.privacyMode;
    _rankingOptIn = widget.profile.rankingOptIn;
  }

  Future<void> _setPrivacy(PrivacyMode mode) async {
    if (mode == _privacy || _busy) return;
    final previous = _privacy;
    setState(() {
      _privacy = mode;
      _busy = true;
    });
    try {
      await ApiService.updatePrivacy(mode);
      if (mounted) {
        showToast(context, 'Privacidad actualizada a ${_privacyLabels[mode]}');
      }
    } on ApiException catch (e) {
      setState(() => _privacy = previous);
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setRankingOptIn(bool value) async {
    if (_busy) return;
    final previous = _rankingOptIn;
    setState(() {
      _rankingOptIn = value;
      _busy = true;
    });
    try {
      final result = await ApiService.updateRankingOptIn(value);
      if (mounted) setState(() => _rankingOptIn = result);
    } on ApiException catch (e) {
      setState(() => _rankingOptIn = previous);
      if (mounted) showToast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
    ThemeStorage.save(mode);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres cerrar tu sesión en este dispositivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    // Revokes the refresh token server-side as well, so this device's session
    // cannot be resumed with a stolen token.
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showAdaptiveDialog<bool>(
      context: context,
      builder: (context) => AlertDialog.adaptive(
        title: const Text('Eliminar cuenta'),
        content: const Text(
          'Esta acción es permanente. Se eliminarán tu perfil, tus fotos, tus '
          'check-ins, tus planes y tus puntos. No se puede deshacer. '
          '¿Quieres continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: candelaDanger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiService.deleteAccount();
      await TokenStorage.clear();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (_) => false,
      );
    } on ApiException catch (e) {
      if (mounted) showToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            spacingScreen,
            8,
            spacingScreen,
            30,
          ),
          children: [
            const ScreenHeader(title: 'Ajustes', showBack: true, padded: false),
            const SizedBox(height: 20),

            Text(
              'Privacidad',
              style: textTheme.bodySmall?.copyWith(color: secondaryOn(context)),
            ),
            const SizedBox(height: 10),
            _SegmentedControl<PrivacyMode>(
              value: _privacy,
              options: PrivacyMode.values,
              labelOf: (m) => _privacyLabels[m]!,
              onChanged: _setPrivacy,
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                _privacyHints[_privacy]!,
                key: ValueKey(_privacy),
                style: textTheme.labelSmall?.copyWith(
                  color: secondaryOn(context),
                ),
              ),
            ),

            const SizedBox(height: 26),
            _ToggleRow(
              title: 'Participar en rankings',
              subtitle: 'Comparte tu posición con tus amigos.',
              value: _rankingOptIn,
              onChanged: _setRankingOptIn,
            ),

            const SizedBox(height: 26),
            Text(
              'Modo oscuro',
              style: textTheme.bodySmall?.copyWith(color: secondaryOn(context)),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeModeNotifier,
              builder: (context, mode, _) => _SegmentedControl<ThemeMode>(
                value: mode,
                options: ThemeMode.values,
                labelOf: (m) => _themeLabels[m]!,
                onChanged: _setThemeMode,
              ),
            ),

            const SizedBox(height: 40),
            Center(
              child: TextButton(
                onPressed: _confirmLogout,
                child: const Text('Cerrar sesión'),
              ),
            ),
            Center(
              child: TextButton(
                style: TextButton.styleFrom(foregroundColor: candelaDanger),
                onPressed: _confirmDeleteAccount,
                child: const Text('Eliminar cuenta'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Segmented control ────────────────────────────────────────────────────────
class _SegmentedControl<T> extends StatelessWidget {
  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  const _SegmentedControl({
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: borderInactive.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: option == value ? candelaAmber : Colors.transparent,
                    borderRadius: BorderRadius.circular(radiusPill),
                  ),
                  child: Text(
                    labelOf(option),
                    style: textTheme.bodySmall?.copyWith(
                      color: option == value
                          ? Colors.white
                          : secondaryOn(context),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Toggle row ───────────────────────────────────────────────────────────────
class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: secondaryOn(context),
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeTrackColor: candelaAmber,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
