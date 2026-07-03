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
import '../services/api_service.dart';
import '../services/auth_service.dart' show ApiException;
import '../services/location_service.dart';
import '../auth/widgets.dart' show PrimaryButton;
import 'widgets.dart';

part 'checkin_steps.dart';

/// The most important interaction in the app — a moment, not a form.
/// Three full-screen steps: pick a place, capture a live photo, confirm.
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

enum _Step { place, camera, confirm }

class _CheckInScreenState extends State<CheckInScreen> {
  _Step _step = _Step.place;
  Place? _place;
  XFile? _photo;
  Position? _position;

  Future<void> _pickPlace(Place place) async {
    final position = await LocationService.getCurrentPosition();
    if (!mounted) return;
    if (position == null) {
      await _showLocationRequiredDialog();
      return;
    }
    setState(() {
      _place = place;
      _position = position;
      _step = _Step.camera;
    });
  }

  Future<void> _showLocationRequiredDialog() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: candelaNight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
        title: Text(
          'Necesitamos tu ubicación',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        content: Text(
          'Necesitamos tu ubicación para verificar que estás ahí.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: textDarkSecondary),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: textDarkSecondary),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: candelaAmber),
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openLocationSettings();
            },
            child: const Text('Abrir ajustes'),
          ),
        ],
      ),
    );
  }

  void _capture(XFile photo) => setState(() {
    _photo = photo;
    _step = _Step.confirm;
  });

  void _retake() => setState(() {
    _photo = null;
    _step = _Step.camera;
  });

  void _cancelToPlaces() => setState(() {
    _photo = null;
    _place = null;
    _step = _Step.place;
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == _Step.place,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_step == _Step.camera) {
          _cancelToPlaces();
        } else if (_step == _Step.confirm) {
          _retake();
        }
      },
      child: switch (_step) {
        _Step.place => _PlaceSelectStep(onSelected: _pickPlace),
        _Step.camera => _CameraCaptureStep(
          place: _place!,
          position: _position!,
          onCaptured: _capture,
          onCancel: _cancelToPlaces,
        ),
        _Step.confirm => _ConfirmStep(
          place: _place!,
          position: _position!,
          photo: _photo!,
          onRetake: _retake,
        ),
      },
    );
  }
}
