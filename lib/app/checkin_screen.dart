import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
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
import '../services/location_service.dart';
import '../auth/widgets.dart' show CandelaButton;
import 'plans_screen.dart' show showProposePlanSheet;
import 'widgets.dart';

part 'checkin_steps.dart';

/// The most important interaction in the app — a moment, not a form.
/// Three full-screen steps: pick a place, capture a live photo, confirm.
class CheckInScreen extends StatefulWidget {
  /// When opened from a place screen, that place is preselected and the flow
  /// jumps straight to the camera. Falls back to the place list if location
  /// is unavailable.
  final Place? initialPlace;
  const CheckInScreen({this.initialPlace, super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

enum _Step { place, camera, confirm }

class _CheckInScreenState extends State<CheckInScreen> {
  _Step _step = _Step.place;
  Place? _place;
  CheckInInitiation? _initiation;
  XFile? _photo;
  DateTime? _capturedAt;
  Position? _position;

  // While resolving location for a pick we show a neutral loader instead of the
  // place list, so the preselected (event) flow never flashes "¿Dónde estás?"
  // on its way to the camera.
  bool _preparing = false;

  @override
  void initState() {
    super.initState();
    final preselected = widget.initialPlace;
    if (preselected != null) {
      // Render the loader from the very first frame — not the place list — so a
      // check-in opened from a place goes straight loader → camera.
      _preparing = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _pickPlace(preselected),
      );
    }
  }

  Future<void> _pickPlace(Place place) async {
    setState(() => _preparing = true);
    final position = await LocationService.getCurrentPosition();
    if (!mounted) return;
    if (position == null) {
      // Reveal the place list behind the dialog so the user can retry or pick
      // another place once location is sorted out.
      setState(() => _preparing = false);
      await LocationService.showLocationDisabledDialog(context);
      return;
    }
    try {
      final initiation = await CheckInApi.initiateCheckIn(
        placeId: place.placeId,
        lat: position.latitude,
        lon: position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _place = place;
        _position = position;
        _initiation = initiation;
        _step = _Step.camera;
        _preparing = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _preparing = false);
      showToast(context, e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _preparing = false);
      showToast(context, 'No se pudo iniciar el check-in. Inténtalo de nuevo.');
    }
  }

  void _capture(XFile photo) => setState(() {
    _photo = photo;
    _capturedAt = DateTime.now();
    _step = _Step.confirm;
  });

  void _retake() => setState(() {
    _photo = null;
    _step = _Step.camera;
  });

  void _cancelToPlaces([String? message]) {
    setState(() {
      _photo = null;
      _place = null;
      _initiation = null;
      _step = _Step.place;
    });
    if (message != null && mounted) {
      showToast(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.place && !_preparing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_step == _Step.camera) {
          _cancelToPlaces();
        } else if (_step == _Step.confirm) {
          _retake();
        }
      },
      child: _preparing
          ? const _PreparingStep()
          : switch (_step) {
              _Step.place => _PlaceSelectStep(onSelected: _pickPlace),
              _Step.camera => _CameraCaptureStep(
                place: _place!,
                position: _position!,
                initiation: _initiation!,
                onCaptured: _capture,
                onCancel: _cancelToPlaces,
                onTimeout: () => _cancelToPlaces(
                  'El tiempo para el check-in expiró (90s). Inicia de nuevo.',
                ),
              ),
              _Step.confirm => _ConfirmStep(
                place: _place!,
                position: _position!,
                initiation: _initiation!,
                photo: _photo!,
                capturedAt: _capturedAt!,
                onRetake: _retake,
              ),
            },
    );
  }
}
