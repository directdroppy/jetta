import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Konum çözümleme sonucu — gerçek GPS ya da nazik bir geri dönüş (fallback).
class LocationResult {
  const LocationResult({
    required this.center,
    required this.isReal,
    required this.note,
  });

  final LatLng center;
  final bool isReal;
  final String note;
}

/// geolocator sarmalayıcısı. İzin akışını yönetir; servis kapalı / izin yok /
/// hata durumlarında İstanbul merkezine düşer ki harita her zaman bir şey gösterir.
abstract final class LocationService {
  static const LatLng _fallback = LatLng(41.0082, 28.9784); // İstanbul

  static Future<LocationResult> resolve() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult(
          center: _fallback,
          isReal: false,
          note: 'Konum servisi kapalı',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return const LocationResult(
          center: _fallback,
          isReal: false,
          note: 'Konum izni verilmedi',
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return LocationResult(
        center: LatLng(pos.latitude, pos.longitude),
        isReal: true,
        note: 'Konumunuz',
      );
    } catch (_) {
      return const LocationResult(
        center: _fallback,
        isReal: false,
        note: 'Konum alınamadı',
      );
    }
  }
}
