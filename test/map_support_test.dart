import 'package:flutter_test/flutter_test.dart';

import 'package:jetta/map_support.dart';
import 'package:jetta/models.dart';

void main() {
  test('picker\'daki her şehrin harita koordinatı var (drift koruması)', () {
    for (final city in allCities) {
      expect(coordOf(city), isNotNull,
          reason: '$city için cityCoords girişi eksik');
    }
  });

  test('mesafe ve fiyat tahmini makul', () {
    final ist = coordOf('İstanbul')!;
    final ank = coordOf('Ankara')!;
    final km = distanceKmBetween(ist, ank);
    expect(km, greaterThan(300));
    expect(km, lessThan(500));

    final (low, high) = estimatePrice(km, VehicleType.tir);
    expect(low, greaterThan(0));
    expect(high, greaterThan(low));
  });
}
