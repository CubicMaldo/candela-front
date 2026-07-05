part of 'checkin_screen.dart';

// ─── Preparing placeholder ────────────────────────────────────────────────────
/// Neutral full-screen loader shown while a picked place's location resolves.
/// Its black background matches the camera step so the transition into the
/// camera is seamless and the place list never flashes on the preselected flow.
class _PreparingStep extends StatelessWidget {
  const _PreparingStep();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: CandelaLoader.centered(),
    );
  }
}

// ─── Step 1 — Place selection ─────────────────────────────────────────────────
class _PlaceSelectStep extends StatefulWidget {
  final ValueChanged<Place> onSelected;
  const _PlaceSelectStep({required this.onSelected});

  @override
  State<_PlaceSelectStep> createState() => _PlaceSelectStepState();
}

class _PlaceSelectStepState extends State<_PlaceSelectStep> {
  late Future<List<Place>> _places;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _places = _loadPlaces();
  }

  Future<List<Place>> _loadPlaces() async {
    final position = await LocationService.getCurrentPosition();
    return ApiService.getNearbyPlaces(
      lat: position?.latitude ?? fallbackLat,
      lon: position?.longitude ?? fallbackLon,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                spacingScreen,
                8,
                spacingScreen,
                0,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: borderInactive.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(radiusMedium),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text('¿Dónde estás?', style: textTheme.titleSmall),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                spacingScreen,
                14,
                spacingScreen,
                0,
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar un lugar',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: spacingScreen),
              child: GestureDetector(
                onTap: () => showProposePlanSheet(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: candelaAmber.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(radiusMedium),
                    border: Border.all(
                      color: candelaAmber.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: candelaAmber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿No estás ahí todavía?',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Propón un plan para verte con un amigo',
                              style: textTheme.bodySmall?.copyWith(
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: AsyncView<List<Place>>(
                future: _places,
                errorTitle: 'No pudimos encontrar lugares',
                builder: (places) {
                  var list = places.toList()
                    ..sort(
                      (a, b) => b.activeCheckinsCount.compareTo(
                        a.activeCheckinsCount,
                      ),
                    );
                  if (_query.isNotEmpty) {
                    list = list
                        .where(
                          (p) =>
                              p.name.toLowerCase().contains(_query) ||
                              p.category.toLowerCase().contains(_query),
                        )
                        .toList();
                  }
                  if (list.isEmpty) {
                    return const EmptyState(
                      icon: Icons.location_off_outlined,
                      title: 'No encontramos lugares',
                      message: 'Prueba con otro nombre o categoría.',
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      spacingScreen,
                      8,
                      spacingScreen,
                      16,
                    ),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final p = list[i];
                      return GestureDetector(
                        onTap: () => widget.onSelected(p),
                        child: AppCard(
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: p.isActive
                                      ? candelaAmber
                                      : borderInactive,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.name,
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.isActive && p.activeCheckinsCount > 0
                                          ? '${p.category} · ${p.activeCheckinsCount} en candela ahora'
                                          : p.category,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: p.isActive
                                            ? candelaAmber
                                            : textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 20,
                                color: textSecondary,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Step 2 — Camera capture ──────────────────────────────────────────────────
class _CameraCaptureStep extends StatefulWidget {
  final Place place;
  final Position position;
  final ValueChanged<XFile> onCaptured;
  final VoidCallback onCancel;
  const _CameraCaptureStep({
    required this.place,
    required this.position,
    required this.onCaptured,
    required this.onCancel,
  });

  @override
  State<_CameraCaptureStep> createState() => _CameraCaptureStepState();
}

class _CameraCaptureStepState extends State<_CameraCaptureStep> {
  CameraController? _controller;
  Future<void>? _init;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(
          () => _error = 'No encontramos una cámara en este dispositivo.',
        );
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      _init = controller.initialize();
      await _init;
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _error = 'No pudimos abrir la cámara.');
    }
  }

  Future<void> _shutter() async {
    final controller = _controller;
    if (controller == null || _capturing || !controller.value.isInitialized) {
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _capturing = true);
    try {
      final file = await controller.takePicture();
      if (mounted) widget.onCaptured(file);
    } catch (_) {
      if (mounted) {
        showToast(context, 'No se pudo tomar la foto. Intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_error != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
              ),
            )
          else if (_init != null)
            FutureBuilder<void>(
              future: _init,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done ||
                    _controller == null ||
                    !_controller!.value.isInitialized) {
                  return const CandelaLoader.centered();
                }
                return CameraPreview(_controller!);
              },
            )
          else
            const CandelaLoader.centered(),

          // Place name, accuracy pill and shutter hint
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(radiusPill),
                        ),
                        child: Text(
                          widget.place.name,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _AccuracyPill(accuracy: widget.position.accuracy),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(radiusPill),
                        ),
                        child: Text(
                          'Tómate una foto aquí',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Cancel
          Positioned(
            top: 0,
            left: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(spacingScreen),
                child: GestureDetector(
                  onTap: widget.onCancel,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Shutter — camera only, no gallery access by design
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: Center(
                  child: GestureDetector(
                    onTap: _error == null ? _shutter : null,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: candelaAmber,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      alignment: Alignment.center,
                      child: _capturing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : null,
                    ),
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

// ─── Location accuracy indicator ──────────────────────────────────────────────
class _AccuracyPill extends StatelessWidget {
  final double accuracy;
  const _AccuracyPill({required this.accuracy});

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;
    final IconData icon;
    if (accuracy <= 20) {
      label = 'Ubicación precisa';
      color = candelaSage;
      icon = Icons.check_circle_rounded;
    } else if (accuracy <= 50) {
      label = 'Ubicación aproximada';
      color = candelaAmber;
      icon = Icons.my_location_rounded;
    } else {
      label = 'Señal débil — acércate más';
      color = candelaWarning;
      icon = Icons.location_searching_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Step 3 — Confirm & publish ───────────────────────────────────────────────
class _ConfirmStep extends StatefulWidget {
  final Place place;
  final Position position;
  final XFile photo;
  final VoidCallback onRetake;
  const _ConfirmStep({
    required this.place,
    required this.position,
    required this.photo,
    required this.onRetake,
  });

  @override
  State<_ConfirmStep> createState() => _ConfirmStepState();
}

class _ConfirmStepState extends State<_ConfirmStep> {
  bool _permanent = false;
  bool _publishing = false;

  Future<void> _publish() async {
    if (_publishing) return;
    setState(() => _publishing = true);
    try {
      final initiation = await ApiService.initiateCheckIn(
        placeId: widget.place.placeId,
        lat: widget.position.latitude,
        lon: widget.position.longitude,
      );
      final bytes = await widget.photo.readAsBytes();
      final uploadRes = await http.put(
        Uri.parse(initiation.uploadUrl),
        headers: const {'Content-Type': 'image/jpeg'},
        body: bytes,
      );
      if (uploadRes.statusCode < 200 || uploadRes.statusCode >= 300) {
        throw const ApiException(
          message: 'No se pudo subir tu foto. Intenta de nuevo.',
          statusCode: 0,
        );
      }
      final result = await ApiService.confirmCheckIn(
        placeId: widget.place.placeId,
        checkinNonce: initiation.checkinNonce,
        photoKey: initiation.photoKey,
        photoIsPermanent: _permanent,
      );
      if (widget.photo.path.isNotEmpty) {
        try {
          await File(widget.photo.path).delete();
        } catch (_) {}
      }
      if (!mounted) return;
      _showCelebration(result);
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 422) {
        showToast(context, 'No te ubico bien ahí. Acércate un poco más.');
      } else {
        showToast(context, e.message);
      }
    } catch (_) {
      if (mounted) {
        showToast(
          context,
          'No se pudo publicar tu check-in. Intenta de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  void _showCelebration(ConfirmCheckInResult result) {
    HapticFeedback.heavyImpact();
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;
    var removed = false;
    void remove() {
      if (removed) return;
      removed = true;
      entry.remove();
    }

    entry = OverlayEntry(
      builder: (context) => _CelebrationOverlay(
        breakdown: result.pointsBreakdown,
        onDismiss: remove,
      ),
    );
    overlay.insert(entry);
    Timer(const Duration(seconds: 4), remove);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(File(widget.photo.path), fit: BoxFit.cover),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                spacingScreen,
                18,
                spacingScreen,
                28,
              ),
              decoration: const BoxDecoration(
                color: surfaceDark,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(radiusCard),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '¿Marcar como permanente?',
                              style: textTheme.bodyMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Las fotos permanentes quedan en tu historial.',
                              style: textTheme.bodySmall?.copyWith(
                                color: textDarkSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: _permanent,
                        activeTrackColor: candelaAmber,
                        onChanged: _publishing
                            ? null
                            : (v) => setState(() => _permanent = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  CandelaButton(
                    label: 'Publicar',
                    loading: _publishing,
                    onTap: _publishing ? null : _publish,
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: textDarkSecondary,
                      ),
                      onPressed: _publishing ? null : widget.onRetake,
                      child: const Text('Repetir foto'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Celebration overlay — "¡Ahí estás! +N puntos." ───────────────────────────
class _CelebrationOverlay extends StatefulWidget {
  final PointsBreakdown breakdown;
  final VoidCallback onDismiss;
  const _CelebrationOverlay({required this.breakdown, required this.onDismiss});

  @override
  State<_CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<_CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
  )..forward();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.breakdown;
    return Positioned(
      left: spacingScreen,
      right: spacingScreen,
      bottom: 110,
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _ctrl,
          child: ScaleTransition(
            scale: Tween(begin: 0.85, end: 1.0).animate(
              CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
            ),
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: widget.onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: surfaceDark,
                  borderRadius: BorderRadius.circular(radiusCard),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: candelaAmber,
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Ahí estás! +${b.total} puntos.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Base ${b.base} · x${b.multiplier.toStringAsFixed(1)}'
                            '${b.weeklyBonus > 0 ? ' · racha +${b.weeklyBonus}' : ''}'
                            '${b.planBonus > 0 ? ' · plan +${b.planBonus}' : ''}',
                            style: const TextStyle(
                              color: textDarkSecondary,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
