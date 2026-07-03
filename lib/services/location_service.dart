import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../theme.dart';

/// Wraps device location access — permissions, position fetching, and the
/// shared "please enable location" dialog used across map and check-in flows.
class LocationService {
  static Future<bool> requestPermission() async {
    final status = await ph.Permission.location.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      await ph.openAppSettings();
      return false;
    }
    final result = await ph.Permission.location.request();
    return result.isGranted;
  }

  static Future<Position?> getCurrentPosition() async {
    final granted = await requestPermission();
    if (!granted) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isLocationEnabled() =>
      Geolocator.isLocationServiceEnabled();

  static Future<void> showLocationDisabledDialog(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: candelaNight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
        title: Text(
          'Activa tu ubicación',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: Colors.white),
        ),
        content: Text(
          'Necesitamos tu ubicación para verificar tus check-ins y mostrarte '
          'eventos cerca de ti.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: textDarkSecondary),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: textDarkSecondary),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Ahora no'),
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
}
