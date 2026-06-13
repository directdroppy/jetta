import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'models.dart';

/// Türkiye il merkezleri (yaklaşık) — rota çizimi ve kamera uçuşu için.
/// models.dart'taki plateCodes ile aynı il kümesini kapsar.
const Map<String, LatLng> cityCoords = {
  'Adana': LatLng(37.0000, 35.3213),
  'Ankara': LatLng(39.9208, 32.8541),
  'Antalya': LatLng(36.8969, 30.7133),
  'Bursa': LatLng(40.1885, 29.0610),
  'Denizli': LatLng(37.7765, 29.0864),
  'Diyarbakır': LatLng(37.9144, 40.2306),
  'Erzurum': LatLng(39.9043, 41.2679),
  'Eskişehir': LatLng(39.7767, 30.5206),
  'Gaziantep': LatLng(37.0662, 37.3833),
  'Hatay': LatLng(36.2025, 36.1606),
  'Mersin': LatLng(36.8121, 34.6415),
  'İstanbul': LatLng(41.0082, 28.9784),
  'İzmir': LatLng(38.4237, 27.1428),
  'Kayseri': LatLng(38.7312, 35.4787),
  'Kocaeli': LatLng(40.7654, 29.9408),
  'Konya': LatLng(37.8714, 32.4846),
  'Malatya': LatLng(38.3552, 38.3095),
  'Manisa': LatLng(38.6191, 27.4289),
  'Kahramanmaraş': LatLng(37.5753, 36.9228),
  'Sakarya': LatLng(40.7731, 30.3948),
  'Samsun': LatLng(41.2867, 36.3300),
  'Şanlıurfa': LatLng(37.1591, 38.7969),
  'Tekirdağ': LatLng(40.9781, 27.5117),
  'Trabzon': LatLng(41.0015, 39.7178),
  'Van': LatLng(38.4891, 43.4089),
};

const Distance _distance = Distance();

LatLng? coordOf(String city) => cityCoords[city];

double distanceKmBetween(LatLng a, LatLng b) =>
    _distance.as(LengthUnit.Kilometer, a, b);

/// Bir noktayı metre cinsinden ötele (dx: doğu+, dy: kuzey+).
LatLng offsetMeters(LatLng origin, double dx, double dy) {
  const earth = 111320.0; // 1 derece enlem ≈ metre
  final dLat = dy / earth;
  final dLng = dx / (earth * math.cos(origin.latitude * math.pi / 180));
  return LatLng(origin.latitude + dLat, origin.longitude + dLng);
}

/// İki nokta arasındaki yön (0–360°, kuzeyden saat yönünde).
double bearingDeg(LatLng from, LatLng to) {
  final lat1 = from.latitude * math.pi / 180;
  final lat2 = to.latitude * math.pi / 180;
  final dLng = (to.longitude - from.longitude) * math.pi / 180;
  final y = math.sin(dLng) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
  final deg = math.atan2(y, x) * 180 / math.pi;
  return (deg + 360) % 360;
}

/// Verilen noktaya en yakın il.
String nearestCity(LatLng p) {
  String best = 'İstanbul';
  double bestKm = double.infinity;
  cityCoords.forEach((city, coord) {
    final km = distanceKmBetween(p, coord);
    if (km < bestKm) {
      bestKm = km;
      best = city;
    }
  });
  return best;
}

/// İki LatLng arasında doğrusal interpolasyon (eşleşme animasyonu için).
LatLng lerpLatLng(LatLng a, LatLng b, double t) => LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );

/// Haritada görünen, yakındaki müsait bir tır.
class NearbyTruck {
  NearbyTruck({
    required this.id,
    required this.position,
    required this.vehicleType,
    required this.plate,
    required this.driver,
    required this.rating,
    required this.headingDeg,
    required this.distanceKm,
  });

  final String id;
  LatLng position;
  final VehicleType vehicleType;
  final String plate;
  final String driver;
  final double rating;
  double headingDeg;
  final double distanceKm;
}

const _driverPool = [
  'Mehmet K.', 'Hasan D.', 'Ali Y.', 'Osman T.', 'Kemal B.',
  'Murat A.', 'Selim G.', 'Yusuf E.', 'Recep S.', 'İbrahim Ç.',
  'Ahmet V.', 'Mustafa N.',
];

/// Merkez etrafında, deterministik (konuma göre tohumlanmış) sahte tırlar üretir.
List<NearbyTruck> generateNearbyTrucks(LatLng center, {int count = 9}) {
  final seed = (center.latitude * 1000).toInt() ^
      (center.longitude * 1000).toInt() ^
      0x4A7;
  final rng = math.Random(seed);
  final plateCity = nearestCity(center);
  final code = plateOf(plateCity);
  final letters = 'ABCDEFGHJKLMNPRSTUVYZ';
  final types = VehicleType.values;

  final trucks = <NearbyTruck>[];
  for (var i = 0; i < count; i++) {
    final angle = rng.nextDouble() * 2 * math.pi;
    final radius = 500 + rng.nextDouble() * 4200; // 0.5–4.7 km
    final pos = offsetMeters(
      center,
      math.cos(angle) * radius,
      math.sin(angle) * radius,
    );
    final plate = '$code '
        '${letters[rng.nextInt(letters.length)]}'
        '${letters[rng.nextInt(letters.length)]}'
        '${letters[rng.nextInt(letters.length)]} '
        '${100 + rng.nextInt(900)}';
    trucks.add(NearbyTruck(
      id: 'T$i',
      position: pos,
      vehicleType: types[rng.nextInt(types.length)],
      plate: plate,
      driver: _driverPool[rng.nextInt(_driverPool.length)],
      rating: 4.3 + rng.nextDouble() * 0.7,
      headingDeg: rng.nextDouble() * 360,
      distanceKm: radius / 1000,
    ));
  }
  trucks.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  return trucks;
}

/// Araç tipine göre yaklaşık km başı navlun (₺) — tahmini fiyat için.
double ratePerKm(VehicleType type) => switch (type) {
      VehicleType.kamyonet => 32,
      VehicleType.kamyon => 48,
      VehicleType.tenteli => 58,
      VehicleType.tir => 62,
      VehicleType.frigorifik => 75,
      VehicleType.lowbed => 95,
    };

/// (alt, üst) tahmini fiyat aralığı.
(int, int) estimatePrice(double distanceKm, VehicleType type) {
  final base = 4500 + distanceKm * ratePerKm(type);
  final low = (base * 0.92 / 100).round() * 100;
  final high = (base * 1.12 / 100).round() * 100;
  return (low, high);
}
