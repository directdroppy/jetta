import 'package:flutter/foundation.dart';

import 'models.dart';

/// Prototip durumu: tüm veriler bellekte tutulur, gerçek backend yok.
class AppState extends ChangeNotifier {
  UserRole? role;
  String userName = '';

  final List<Load> loads = _seedLoads();

  /// Şoförün teklif verdiği ilan id'leri.
  final Set<String> myOfferLoadIds = {};

  /// Yük verenin sahip olduğu ilan id'leri (demo başlangıcı: L1 ve L2).
  final Set<String> myLoadIds = {'L1', 'L2'};

  int _idCounter = 100;
  String nextId() => 'L${_idCounter++}';

  void selectRole(UserRole r, String name) {
    role = r;
    userName = name.trim().isEmpty
        ? (r == UserRole.shipper ? 'Yük Veren' : 'Kaptan')
        : name.trim();
    notifyListeners();
  }

  void logout() {
    role = null;
    notifyListeners();
  }

  // ── Yük veren aksiyonları ──────────────────────────────────────────

  List<Load> get myLoads =>
      loads.where((l) => myLoadIds.contains(l.id)).toList();

  void addLoad(Load load) {
    loads.insert(0, load);
    myLoadIds.add(load.id);
    notifyListeners();
  }

  void acceptOffer(Load load, Offer offer) {
    for (final o in load.offers) {
      o.status = o.id == offer.id ? OfferStatus.accepted : OfferStatus.rejected;
    }
    load.status = LoadStatus.assigned;
    notifyListeners();
  }

  // ── Şoför aksiyonları ──────────────────────────────────────────────

  List<Load> get marketLoads =>
      loads.where((l) => l.status == LoadStatus.open).toList();

  List<Load> get myJobs => loads
      .where((l) =>
          l.status != LoadStatus.open &&
          (myOfferLoadIds.contains(l.id) || l.acceptedOffer != null))
      .toList();

  void makeOffer(Load load, int price, String note) {
    load.offers.add(Offer(
      id: 'O${_idCounter++}',
      carrierName: userName,
      plate: '34 JTA ${800 + load.offers.length}',
      rating: 5.0,
      tripCount: 0,
      price: price,
      note: note,
    ));
    myOfferLoadIds.add(load.id);
    notifyListeners();
  }

  void advanceLoad(Load load) {
    load.status = switch (load.status) {
      LoadStatus.assigned => LoadStatus.inTransit,
      LoadStatus.inTransit => LoadStatus.delivered,
      _ => load.status,
    };
    notifyListeners();
  }
}

final appState = AppState();

List<Load> _seedLoads() {
  final now = DateTime.now();
  return [
    Load(
      id: 'L1',
      ownerName: 'Aydın Tekstil A.Ş.',
      fromCity: 'İstanbul',
      toCity: 'Ankara',
      cargoType: 'Paletli tekstil ürünü',
      weightTon: 18,
      vehicleType: VehicleType.tir,
      pickupDate: now.add(const Duration(days: 1)),
      distanceKm: 450,
      targetPrice: 28000,
      offers: [
        Offer(
          id: 'O1',
          carrierName: 'Mehmet Kaya',
          plate: '06 ANK 412',
          rating: 4.8,
          tripCount: 214,
          price: 27500,
          note: 'Boş dönüş yapıyorum, sabah 08:00 yüklemeye hazırım.',
        ),
        Offer(
          id: 'O2',
          carrierName: 'Hasan Demir',
          plate: '34 HDL 287',
          rating: 4.6,
          tripCount: 156,
          price: 29000,
          note: 'Tente yeni, kasko tam. Aynı gün teslim.',
        ),
      ],
    ),
    Load(
      id: 'L2',
      ownerName: 'Ege Gıda San.',
      fromCity: 'İzmir',
      toCity: 'İstanbul',
      cargoType: 'Soğuk zincir gıda',
      weightTon: 22,
      vehicleType: VehicleType.frigorifik,
      pickupDate: now.add(const Duration(days: 2)),
      distanceKm: 480,
      targetPrice: 34000,
    ),
    Load(
      id: 'L3',
      ownerName: 'Çukurova Narenciye',
      fromCity: 'Adana',
      toCity: 'Bursa',
      cargoType: 'Narenciye (kasalı)',
      weightTon: 24,
      vehicleType: VehicleType.frigorifik,
      pickupDate: now.add(const Duration(days: 1)),
      distanceKm: 840,
      targetPrice: 52000,
    ),
    Load(
      id: 'L4',
      ownerName: 'Anadolu Mobilya',
      fromCity: 'Kayseri',
      toCity: 'Antalya',
      cargoType: 'Mobilya (hacimli)',
      weightTon: 12,
      vehicleType: VehicleType.tenteli,
      pickupDate: now.add(const Duration(days: 3)),
      distanceKm: 620,
    ),
    Load(
      id: 'L5',
      ownerName: 'Marmara Çelik',
      fromCity: 'Kocaeli',
      toCity: 'Gaziantep',
      cargoType: 'Rulo sac',
      weightTon: 26,
      vehicleType: VehicleType.tir,
      pickupDate: now.add(const Duration(days: 2)),
      distanceKm: 1100,
      targetPrice: 68000,
    ),
    Load(
      id: 'L6',
      ownerName: 'Trakya Tarım',
      fromCity: 'Tekirdağ',
      toCity: 'Konya',
      cargoType: 'Tohum & gübre (paletli)',
      weightTon: 20,
      vehicleType: VehicleType.kamyon,
      pickupDate: now.add(const Duration(days: 4)),
      distanceKm: 700,
      targetPrice: 41000,
    ),
    Load(
      id: 'L7',
      ownerName: 'Karadeniz İnşaat',
      fromCity: 'Samsun',
      toCity: 'Erzurum',
      cargoType: 'Ekskavatör',
      weightTon: 30,
      vehicleType: VehicleType.lowbed,
      pickupDate: now.add(const Duration(days: 5)),
      distanceKm: 540,
    ),
  ];
}
