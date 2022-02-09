import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:new_app/backbone/exception.dart';

import 'location.dart';

abstract class LocationService {
  Future<DeviceLocation> getCurrentLocation();

  Future<DeviceLocation> getCurrentLocationWithoutPermissionsCheck();

  Future<void> checkPermissionsAndThrowExceptionIfNeeded();
}

class new_appLocationService implements LocationService {
  static const MethodChannel platform =
      const MethodChannel('com.new_app.navigator.flutter/platform');
  final Geolocator _location = Geolocator();
  final LocationPermissions _locationPermissions = LocationPermissions();

  @override
  Future<DeviceLocation> getCurrentLocation() async {
    checkPermissionsAndThrowExceptionIfNeeded();
    final Position position = await _location
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .timeout(Duration(seconds: 30));
    return DeviceLocation(
        position.latitude, position.longitude, DateTime.now());
  }

  @override
  Future<DeviceLocation> getCurrentLocationWithoutPermissionsCheck() async {
    final Position position = await _location
        .getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .timeout(Duration(seconds: 20));
    return DeviceLocation(
        position.latitude, position.longitude, DateTime.now());
  }

  Future<void> checkPermissionsAndThrowExceptionIfNeeded() async {
    final ServiceStatus serviceStatus =
        await _locationPermissions.checkServiceStatus();
    if (serviceStatus != ServiceStatus.enabled) {
      throw LocationException(
        message: "Service for getting current location is not enabled",
      );
    }
    PermissionStatus permissionStatus =
        await _locationPermissions.checkPermissionStatus();
    if (permissionStatus != PermissionStatus.granted) {
      if (Platform.isAndroid) {
        if (await _displayNativeLocationPermissionsDescriptionDialog()) {
          permissionStatus = await _locationPermissions.requestPermissions(
              permissionLevel: LocationPermissionLevel.locationAlways);
        }
      } else {
        permissionStatus = await _locationPermissions.requestPermissions(
            permissionLevel: LocationPermissionLevel.locationAlways);
      }
      if (permissionStatus != PermissionStatus.granted) {
        throw LocationException(
          message: "Permissions for getting current location was not granted. "
              "Please, give an access to your location in phone settings",
        );
      }
    }
  }

  Future<bool> _displayNativeLocationPermissionsDescriptionDialog() async {
    try {
      return await platform.invokeMethod('displayPermissionsDialog');
    } on PlatformException catch (e, st) {
      FirebaseCrashlytics.instance.recordError(e, st);
      return true;
    }
  }
}

class LocationException extends DocumentedException {
  LocationException({String message, Object cause})
      : super(message: message, cause: cause);
}
