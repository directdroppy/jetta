import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../app_state.dart';
import '../map_support.dart';
import '../models.dart';
import '../services/location_service.dart';
import '../theme.dart';
import '../widgets.dart';
import 'load_detail_screen.dart';

enum _Flow { browsing, matching, matched }

/// Yük verenin Uber tarzı ana ekranı: koyu harita, gerçek konum, çevredeki
/// müsait tırlar, varış seçimi, rota ve "araç aranıyor" eşleşme simülasyonu.
class MapHomeScreen extends StatefulWidget {
  const MapHomeScreen({super.key});

  @override
  State<MapHomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<MapHomeScreen>
    with TickerProviderStateMixin {
  final MapController _map = MapController();

  bool _locating = true;
  LatLng _myLocation = const LatLng(41.0082, 28.9784);
  bool _realLocation = false;
  String _locationNote = 'Konum alınıyor';
  List<NearbyTruck> _trucks = [];

  String? _toCity;
  LatLng? _toCoord;
  VehicleType _vehicle = VehicleType.tir;
  final _cargoController = TextEditingController();
  double _weight = 20;

  _Flow _flow = _Flow.browsing;
  Load? _createdLoad;
  int _matchedCount = 0;
  Timer? _matchTimer;
  AnimationController? _fly;

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();
  late final AnimationController _radar = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  late final AnimationController _converge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  Future<void> _resolveLocation() async {
    final res = await LocationService.resolve();
    if (!mounted) return;
    setState(() {
      _myLocation = res.center;
      _realLocation = res.isReal;
      _locationNote = res.note;
      _trucks = generateNearbyTrucks(res.center);
      _locating = false;
    });
  }

  @override
  void dispose() {
    _matchTimer?.cancel();
    _fly?.dispose();
    _pulse.dispose();
    _radar.dispose();
    _converge.dispose();
    _cargoController.dispose();
    _map.dispose();
    super.dispose();
  }

  // ── Kamera ───────────────────────────────────────────────────────

  void _flyTo(LatLng dest, double zoom) {
    _fly?.dispose();
    final cam = _map.camera;
    final latT = Tween(begin: cam.center.latitude, end: dest.latitude);
    final lngT = Tween(begin: cam.center.longitude, end: dest.longitude);
    final zT = Tween(begin: cam.zoom, end: zoom);
    final c = _fly = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 850));
    final a = CurvedAnimation(parent: c, curve: Curves.easeInOutCubic);
    c.addListener(() {
      if (!mounted) return;
      _map.move(
        LatLng(latT.evaluate(a), lngT.evaluate(a)),
        zT.evaluate(a),
      );
    });
    c.forward().whenCompleteOrCancel(() {
      if (_fly == c) _fly = null;
      c.dispose();
    });
  }

  void _recenter() {
    HapticFeedback.selectionClick();
    _flyTo(_myLocation, 13.4);
  }

  // ── Seçim & eşleşme ──────────────────────────────────────────────

  Future<void> _pickDestination() async {
    final city = await showCityPickerSheet(context, 'Nereye gidecek?');
    if (city == null || !mounted) return;
    final coord = coordOf(city);
    setState(() {
      _toCity = city;
      _toCoord = coord;
    });
    if (coord != null) {
      final h = MediaQuery.of(context).size.height;
      final bottomPad = math.min(h * 0.5, 430.0);
      _map.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([_myLocation, coord]),
          padding: EdgeInsets.fromLTRB(70, 130, 70, bottomPad),
        ),
      );
    }
  }

  void _callTruck() {
    if (_toCity == null || _flow != _Flow.browsing) return;
    HapticFeedback.heavyImpact();
    setState(() => _flow = _Flow.matching);
    _flyTo(_myLocation, 13.6);
    _converge.forward(from: 0);
    _radar.repeat();
    _matchTimer?.cancel();
    _matchTimer = Timer(const Duration(milliseconds: 3300), _completeMatch);
  }

  void _completeMatch() {
    if (!mounted || _flow != _Flow.matching) return;
    final from = nearestCity(_myLocation);
    final rawKm = distanceKmBetween(_myLocation, _toCoord ?? _myLocation);
    final effKm = rawKm < 1 ? 50.0 : rawKm;
    final (low, high) = estimatePrice(effKm, _vehicle);
    final cargo = _cargoController.text.trim();
    final load = Load(
      id: appState.nextId(),
      ownerName: appState.userName,
      fromCity: from,
      toCity: _toCity!,
      cargoType: cargo.isEmpty ? 'Genel kargo' : cargo,
      weightTon: _weight,
      vehicleType: _vehicle,
      pickupDate: DateTime.now().add(const Duration(days: 1)),
      distanceKm: effKm.round(),
      targetPrice: ((low + high) / 2 / 100).round() * 100,
    );
    appState.addLoad(load);

    final matching = _trucks.where((t) => t.vehicleType == _vehicle).length;
    _radar.stop();
    setState(() {
      _createdLoad = load;
      _matchedCount = matching == 0 ? math.min(3, _trucks.length) : matching;
      _flow = _Flow.matched;
    });
  }

  void _cancelMatch() {
    _matchTimer?.cancel();
    _radar.stop();
    _converge.reverse();
    setState(() => _flow = _Flow.browsing);
  }

  void _resetSearch() {
    _converge.reset();
    setState(() {
      _flow = _Flow.browsing;
      _toCity = null;
      _toCoord = null;
      _createdLoad = null;
    });
    _flyTo(_myLocation, 13.4);
  }

  void _openCreatedLoad() {
    final load = _createdLoad;
    if (load == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoadDetailScreen(load: load)),
    );
    setState(() => _flow = _Flow.browsing);
  }

  // ── Marker yapımı ────────────────────────────────────────────────

  List<Marker> _truckMarkers() {
    final t = switch (_flow) {
      _Flow.browsing => 0.0,
      _Flow.matching => Curves.easeInOut.transform(_converge.value),
      _Flow.matched => 1.0,
    };
    return _trucks.map((truck) {
      final pos =
          t > 0 ? lerpLatLng(truck.position, _myLocation, t * 0.82) : truck.position;
      return Marker(
        point: pos,
        width: 44,
        height: 44,
        rotate: false,
        child: _TruckPin(active: _flow != _Flow.browsing),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_locating) return const _LocatingView();

    final topPad = MediaQuery.of(context).padding.top;
    final dpr = MediaQuery.of(context).devicePixelRatio;

    return Stack(
      children: [
        AnimatedBuilder(
          animation: _converge,
          builder: (context, _) => FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _myLocation,
              initialZoom: 13.2,
              minZoom: 4,
              maxZoom: 18,
              backgroundColor: JColors.bg,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.jetta.jetta',
                retinaMode: dpr > 1.5,
                tileProvider: NetworkTileProvider(),
              ),
              if (_toCoord != null && _flow != _Flow.matching)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_myLocation, _toCoord!],
                      strokeWidth: 9,
                      color: JColors.amber.withValues(alpha: 0.18),
                    ),
                    Polyline(
                      points: [_myLocation, _toCoord!],
                      strokeWidth: 3.5,
                      color: JColors.amber,
                    ),
                  ],
                ),
              MarkerLayer(markers: _truckMarkers()),
              MarkerLayer(
                markers: [
                  if (_toCoord != null)
                    Marker(
                      point: _toCoord!,
                      width: 54,
                      height: 54,
                      child: const _DestPin(),
                    ),
                  Marker(
                    point: _myLocation,
                    width: 90,
                    height: 90,
                    child: _LocationPuck(pulse: _pulse),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Üst gradyan + durum şeridi
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Container(
              height: topPad + 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    JColors.bg.withValues(alpha: 0.92),
                    JColors.bg.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: topPad + 10,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: _StatusPill(note: _locationNote, real: _realLocation),
              ),
              const SizedBox(width: 12),
              Text('JETTA', style: JText.display(18)),
            ],
          ),
        ),

        // Eşleşme radar katmanı (panelin altında kalır)
        if (_flow == _Flow.matching) _buildMatchingOverlay(),

        // Alt yığın: atıf + yeniden merkezle butonu + panel.
        // LayoutBuilder, klavye açıldığında küçülen gövde yüksekliğini verir.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: LayoutBuilder(
            builder: (context, constraints) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 14, bottom: 4),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '© OpenStreetMap · CARTO',
                      style: JText.body(9.5, color: JColors.textFaint),
                    ),
                  ),
                ),
                if (_flow == _Flow.browsing)
                  Padding(
                    padding: const EdgeInsets.only(right: 20, bottom: 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _RoundButton(
                        icon: Icons.my_location_rounded,
                        onTap: _recenter,
                      ),
                    ),
                  ),
                _buildBottomPanel(constraints.maxHeight),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMatchingOverlay() {
    return Positioned.fill(
      child: Container(
        color: JColors.bg.withValues(alpha: 0.55),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: AnimatedBuilder(
                  animation: _radar,
                  builder: (context, _) =>
                      CustomPaint(painter: _RadarPainter(_radar.value)),
                ),
              ),
              const SizedBox(height: 26),
              Text('Araç aranıyor', style: JText.display(24)),
              const SizedBox(height: 8),
              Text(
                'Çevrenizdeki müsait tırlar taranıyor…',
                style: JText.body(14, color: JColors.textDim),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(double available) {
    final Widget content = switch (_flow) {
      _Flow.matched => _buildMatchedCard(),
      _Flow.matching => _buildMatchingCard(),
      _Flow.browsing => _buildBrowsingPanel(),
    };

    // Klavye/küçük ekran güvenliği: panel asla görünür gövdeyi aşmaz.
    final cap = math.min(MediaQuery.of(context).size.height * 0.55,
        math.max(available - 60, 220.0));

    return Container(
      decoration: const BoxDecoration(
        color: JColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: JColors.line),
          left: BorderSide(color: JColors.line),
          right: BorderSide(color: JColors.line),
        ),
        boxShadow: [
          BoxShadow(color: Color(0x99000000), blurRadius: 30, offset: Offset(0, -8)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: cap),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          child: content,
        ),
      ),
    );
  }

  Widget _buildBrowsingPanel() {
    final destSelected = _toCity != null;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 22 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: JColors.line,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            destSelected ? 'Yükünüzü tanımlayın' : 'Nereye gönderiyorsunuz?',
            style: JText.title(19),
          ),
          const SizedBox(height: 16),
          // Nereden (konum) — sabit
          _RoutePointRow(
            icon: Icons.radio_button_checked,
            iconColor: JColors.amber,
            label: 'NEREDEN',
            value: _realLocation ? 'Konumunuz' : nearestCity(_myLocation),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 11),
            child: SizedBox(
              height: 20,
              child: VerticalDivider(width: 2, color: JColors.line),
            ),
          ),
          // Nereye — seçilebilir
          GestureDetector(
            onTap: _pickDestination,
            behavior: HitTestBehavior.opaque,
            child: _RoutePointRow(
              icon: Icons.location_on_outlined,
              iconColor: destSelected ? JColors.amber : JColors.textFaint,
              label: 'NEREYE',
              value: _toCity ?? 'Varış şehri seçin',
              dim: !destSelected,
              trailing: destSelected
                  ? PlateBadge(city: _toCity!, size: 0.78)
                  : const Icon(Icons.chevron_right_rounded,
                      color: JColors.textFaint),
            ),
          ),
          if (!destSelected) ...[
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: JColors.surfaceHi,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_outlined,
                      size: 18, color: JColors.green),
                  const SizedBox(width: 10),
                  Text('${_trucks.length} müsait tır çevrenizde',
                      style: JText.body(13.5, color: JColors.textDim)),
                ],
              ),
            ),
          ],
          if (destSelected) ...[
            const SizedBox(height: 20),
            const SectionLabel('Araç tipi'),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final v in VehicleType.values) ...[
                    _VehicleChip(
                      type: v,
                      selected: _vehicle == v,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _vehicle = v);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _cargoController,
              style: JText.body(15),
              decoration: const InputDecoration(
                hintText: 'Yük cinsi (örn. paletli gıda)',
                prefixIcon: Icon(Icons.inventory_2_outlined,
                    color: JColors.textFaint),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Tonaj', style: JText.body(14, color: JColors.textDim)),
                const Spacer(),
                Text('${_weight.round()} ton',
                    style: JText.mono(15, color: JColors.amber)),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: JColors.amber,
                inactiveTrackColor: JColors.line,
                thumbColor: JColors.amber,
                overlayColor: JColors.amber.withValues(alpha: 0.15),
                trackHeight: 3,
              ),
              child: Slider(
                value: _weight,
                min: 1,
                max: 40,
                divisions: 39,
                onChanged: (v) => setState(() => _weight = v),
              ),
            ),
            const SizedBox(height: 6),
            _EstimateBar(
              distanceKm: distanceKmBetween(_myLocation, _toCoord ?? _myLocation),
              vehicle: _vehicle,
            ),
            const SizedBox(height: 16),
            JButton(
              label: 'Tır Çağır',
              icon: Icons.campaign_rounded,
              onTap: _callTruck,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchingCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const _ThreeDots(),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Tırlarla iletişime geçiliyor…',
                  style: JText.title(15.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _cancelMatch,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: JColors.surfaceHi,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: JColors.line),
              ),
              child: Center(
                child: Text('İptal', style: JText.title(14, color: JColors.textDim)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: JColors.green.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: JColors.green, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_matchedCount uygun tır bulundu',
                        style: JText.title(17)),
                    const SizedBox(height: 3),
                    Text('İlanınız yayınlandı, teklifler geliyor',
                        style: JText.body(12.5, color: JColors.textDim)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: JColors.surfaceHi,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                PlateBadge(city: nearestCity(_myLocation), size: 0.8),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: RouteLine(),
                  ),
                ),
                if (_toCity != null) PlateBadge(city: _toCity!, size: 0.8),
              ],
            ),
          ),
          const SizedBox(height: 16),
          JButton(
            label: 'İlanı Görüntüle',
            icon: Icons.arrow_forward_rounded,
            onTap: _openCreatedLoad,
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _resetSearch,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: Text('Yeni arama',
                  style: JText.title(14, color: JColors.textDim)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Alt bileşenler ───────────────────────────────────────────────────

class _LocatingView extends StatefulWidget {
  const _LocatingView();

  @override
  State<_LocatingView> createState() => _LocatingViewState();
}

class _LocatingViewState extends State<_LocatingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: JColors.bg,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) => Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 60 + 40 * _c.value,
                    height: 60 + 40 * _c.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: JColors.amber.withValues(alpha: 0.18 * (1 - _c.value)),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [JColors.amber, JColors.amberDeep],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.local_shipping_rounded,
                        color: Color(0xFF1A1102), size: 30),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Konumunuz alınıyor', style: JText.title(17)),
            const SizedBox(height: 6),
            Text('Çevrenizdeki tırlar yükleniyor…',
                style: JText.body(13, color: JColors.textDim)),
          ],
        ),
      ),
    );
  }
}

class _LocationPuck extends StatelessWidget {
  const _LocationPuck({required this.pulse});
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final v = pulse.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 24 + 60 * v,
              height: 24 + 60 * v,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: JColors.amber.withValues(alpha: 0.22 * (1 - v)),
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: JColors.amber.withValues(alpha: 0.25),
              ),
            ),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: JColors.amber,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: JColors.amber.withValues(alpha: 0.6),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TruckPin extends StatelessWidget {
  const _TruckPin({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: active ? JColors.amber : JColors.surfaceHi,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? JColors.amber : JColors.line,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Icon(
        Icons.local_shipping_rounded,
        size: 20,
        color: active ? const Color(0xFF1A1102) : JColors.amber,
      ),
    );
  }
}

class _DestPin extends StatelessWidget {
  const _DestPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: JColors.bg,
        shape: BoxShape.circle,
        border: Border.all(color: JColors.amber, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: JColors.amber.withValues(alpha: 0.4),
            blurRadius: 14,
          ),
        ],
      ),
      padding: const EdgeInsets.all(9),
      child: const Icon(Icons.flag_rounded, size: 22, color: JColors.amber),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.note, required this.real});
  final String note;
  final bool real;

  @override
  Widget build(BuildContext context) {
    final color = real ? JColors.green : JColors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: JColors.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: JColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: JText.body(12.5, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: JColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: JColors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(icon, color: JColors.amber, size: 23),
      ),
    );
  }
}

class _RoutePointRow extends StatelessWidget {
  const _RoutePointRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.dim = false,
    this.trailing,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final bool dim;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: JText.label(10)),
              const SizedBox(height: 3),
              Text(
                value,
                style: dim
                    ? JText.body(15.5, color: JColors.textFaint)
                    : JText.title(16),
              ),
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _VehicleChip extends StatelessWidget {
  const _VehicleChip({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final VehicleType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? JColors.amber : JColors.surfaceHi,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: selected ? JColors.amber : JColors.line),
        ),
        child: Text(
          type.label,
          style: JText.body(
            13,
            weight: FontWeight.w600,
            color: selected ? const Color(0xFF1A1102) : JColors.text,
          ),
        ),
      ),
    );
  }
}

class _EstimateBar extends StatelessWidget {
  const _EstimateBar({required this.distanceKm, required this.vehicle});
  final double distanceKm;
  final VehicleType vehicle;

  @override
  Widget build(BuildContext context) {
    final (low, high) = estimatePrice(distanceKm, vehicle);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            JColors.amber.withValues(alpha: 0.14),
            JColors.surfaceHi,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: JColors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TAHMİNİ FİYAT', style: JText.label(9.5)),
              const SizedBox(height: 5),
              Text('${formatPrice(low)} – ${formatPrice(high)}',
                  style: JText.mono(16, color: JColors.amber)),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('MESAFE', style: JText.label(9.5)),
              const SizedBox(height: 5),
              Text('${distanceKm.round()} km',
                  style: JText.mono(16, color: JColors.textDim)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThreeDots extends StatefulWidget {
  const _ThreeDots();

  @override
  State<_ThreeDots> createState() => _ThreeDotsState();
}

class _ThreeDotsState extends State<_ThreeDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (_c.value + i * 0.25) % 1.0;
          final scale = 0.6 + 0.4 * math.sin(phase * math.pi).abs();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: JColors.amber,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width / 2;

    // Genişleyen halkalar (üç fazlı)
    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1.0;
      final r = maxR * phase;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = JColors.amber.withValues(alpha: (1 - phase) * 0.6);
      canvas.drawCircle(center, r, paint);
    }

    // Dönen tarama dilimi
    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: [
          JColors.amber.withValues(alpha: 0),
          JColors.amber.withValues(alpha: 0.35),
        ],
        transform: GradientRotation(t * 2 * math.pi),
      ).createShader(Rect.fromCircle(center: center, radius: maxR));
    canvas.drawCircle(center, maxR, sweep);

    // Merkez nokta
    canvas.drawCircle(center, 7, Paint()..color = JColors.amber);
    canvas.drawCircle(
      center,
      7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) => oldDelegate.t != t;
}
