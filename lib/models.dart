enum UserRole { shipper, carrier }

enum VehicleType {
  tir('Tır (13.60)', '13.60m standart dorse'),
  kamyon('Kamyon', '10 teker / kırkayak'),
  kamyonet('Kamyonet', 'Şehir içi & parsiyel'),
  frigorifik('Frigorifik', 'Soğuk zincir'),
  lowbed('Lowbed', 'İş makinesi & ağır yük'),
  tenteli('Tenteli', 'Branda örtülü dorse');

  const VehicleType(this.label, this.detail);
  final String label;
  final String detail;
}

enum LoadStatus {
  open('Teklif Bekliyor'),
  assigned('Araç Atandı'),
  inTransit('Yolda'),
  delivered('Teslim Edildi');

  const LoadStatus(this.label);
  final String label;
}

enum OfferStatus { pending, accepted, rejected }

class Offer {
  Offer({
    required this.id,
    required this.carrierName,
    required this.plate,
    required this.rating,
    required this.tripCount,
    required this.price,
    required this.note,
    this.status = OfferStatus.pending,
  });

  final String id;
  final String carrierName;
  final String plate;
  final double rating;
  final int tripCount;
  final int price;
  final String note;
  OfferStatus status;
}

class Load {
  Load({
    required this.id,
    required this.ownerName,
    required this.fromCity,
    required this.toCity,
    required this.cargoType,
    required this.weightTon,
    required this.vehicleType,
    required this.pickupDate,
    required this.distanceKm,
    this.targetPrice,
    this.status = LoadStatus.open,
    List<Offer>? offers,
  }) : offers = offers ?? [];

  final String id;
  final String ownerName;
  final String fromCity;
  final String toCity;
  final String cargoType;
  final double weightTon;
  final VehicleType vehicleType;
  final DateTime pickupDate;
  final int distanceKm;
  final int? targetPrice;
  LoadStatus status;
  final List<Offer> offers;

  Offer? get acceptedOffer {
    for (final o in offers) {
      if (o.status == OfferStatus.accepted) return o;
    }
    return null;
  }

  int get pendingOfferCount =>
      offers.where((o) => o.status == OfferStatus.pending).length;
}

/// Türkiye plaka kodları — lojistikte şehirler plaka koduyla anılır.
const Map<String, String> plateCodes = {
  'Adana': '01',
  'Ankara': '06',
  'Antalya': '07',
  'Bursa': '16',
  'Denizli': '20',
  'Diyarbakır': '21',
  'Erzurum': '25',
  'Eskişehir': '26',
  'Gaziantep': '27',
  'Hatay': '31',
  'Mersin': '33',
  'İstanbul': '34',
  'İzmir': '35',
  'Kayseri': '38',
  'Kocaeli': '41',
  'Konya': '42',
  'Malatya': '44',
  'Manisa': '45',
  'Kahramanmaraş': '46',
  'Sakarya': '54',
  'Samsun': '55',
  'Tekirdağ': '59',
  'Trabzon': '61',
  'Şanlıurfa': '63',
  'Van': '65',
};

String plateOf(String city) => plateCodes[city] ?? '··';

List<String> get allCities => plateCodes.keys.toList()..sort();
