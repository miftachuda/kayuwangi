import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final String address;
  final DateTime timestamp;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.address,
    required this.timestamp,
  });

  String get coordinateDisplay {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lngDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(6)}° $latDir, ${longitude.abs().toStringAsFixed(6)}° $lngDir';
  }
}

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Determine the current position and reverse geocode it to readable address
  Future<LocationResult> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Return default location or throw
      throw Exception('Layanan GPS / Lokasi pada perangkat tidak aktif. Mohon aktifkan GPS.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin akses lokasi ditolak oleh pengguna.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin akses lokasi ditolak secara permanen. Mohon aktifkan di pengaturan aplikasi.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );

    // Reverse geocode to address
    String addressString = 'Lokasi Tanaman (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})';
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = <String>[];
        if (place.street != null && place.street!.isNotEmpty) parts.add(place.street!);
        if (place.subLocality != null && place.subLocality!.isNotEmpty) parts.add(place.subLocality!);
        if (place.locality != null && place.locality!.isNotEmpty) parts.add(place.locality!);
        if (place.subAdministrativeArea != null && place.subAdministrativeArea!.isNotEmpty) parts.add(place.subAdministrativeArea!);
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) parts.add(place.administrativeArea!);

        if (parts.isNotEmpty) {
          addressString = parts.join(', ');
        }
      }
    } catch (_) {
      // In case offline geocoding fails, fallback to coordinates
      addressString = 'Kayuwangi Plot (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)})';
    }

    return LocationResult(
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      address: addressString,
      timestamp: DateTime.now(),
    );
  }
}
