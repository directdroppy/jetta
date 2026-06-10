import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

class CreateLoadScreen extends StatefulWidget {
  const CreateLoadScreen({super.key});

  @override
  State<CreateLoadScreen> createState() => _CreateLoadScreenState();
}

class _CreateLoadScreenState extends State<CreateLoadScreen> {
  final _page = PageController();
  int _step = 0;

  String? _fromCity;
  String? _toCity;
  final _cargoController = TextEditingController();
  double _weight = 20;
  VehicleType _vehicle = VehicleType.tir;
  int _dayOffset = 1;
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _page.dispose();
    _cargoController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  bool get _stepValid => switch (_step) {
        0 => _fromCity != null && _toCity != null && _fromCity != _toCity,
        1 => _cargoController.text.trim().isNotEmpty,
        _ => true,
      };

  void _next() {
    if (_step < 2) {
      setState(() => _step++);
      _page.animateToPage(_step,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_step == 0) {
      Navigator.of(context).pop();
    } else {
      setState(() => _step--);
      _page.animateToPage(_step,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic);
    }
  }

  void _submit() {
    final price = int.tryParse(
        _priceController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    appState.addLoad(Load(
      id: appState.nextId(),
      ownerName: appState.userName,
      fromCity: _fromCity!,
      toCity: _toCity!,
      cargoType: _cargoController.text.trim(),
      weightTon: _weight,
      vehicleType: _vehicle,
      pickupDate: DateTime.now().add(Duration(days: _dayOffset)),
      distanceKm: 100 + (_fromCity!.length + _toCity!.length) * 23,
      targetPrice: price,
    ));
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: JColors.surfaceHi,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: JColors.green),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: JColors.green, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text('İlanınız yayında! Teklifler gelmeye başlayacak.',
                  style: JText.body(13.5)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickCity(bool isFrom) async {
    final city = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _CityPicker(
          title: isFrom ? 'Nereden yüklenecek?' : 'Nereye gidecek?'),
    );
    if (city != null) {
      setState(() => isFrom ? _fromCity = city : _toCity = city);
    }
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Güzergâh', 'Yük Bilgisi', 'Tarih & Bütçe'];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _back,
        ),
        title: Text('Yeni Yük — ${titles[_step]}', style: JText.title(17)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 320),
                        height: 5,
                        decoration: BoxDecoration(
                          color: i <= _step ? JColors.amber : JColors.line,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    if (i < 2) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildRouteStep(),
                  _buildCargoStep(),
                  _buildScheduleStep(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: JButton(
                label: _step == 2 ? 'İlanı Yayınla' : 'Devam Et',
                icon: _step == 2
                    ? Icons.campaign_outlined
                    : Icons.arrow_forward_rounded,
                onTap: _stepValid ? _next : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionLabel('Güzergâh seçin'),
        _CityField(
          label: 'NEREDEN',
          city: _fromCity,
          icon: Icons.radio_button_checked,
          onTap: () => _pickCity(true),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 27),
          child: SizedBox(
            height: 26,
            child: VerticalDivider(
              color: JColors.textFaint.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _CityField(
          label: 'NEREYE',
          city: _toCity,
          icon: Icons.location_on_outlined,
          onTap: () => _pickCity(false),
        ),
        if (_fromCity != null && _toCity != null && _fromCity == _toCity)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text('Çıkış ve varış şehri aynı olamaz.',
                style: JText.body(13, color: JColors.red)),
          ),
        if (_fromCity != null && _toCity != null && _fromCity != _toCity)
          Padding(
            padding: const EdgeInsets.only(top: 28),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: JColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: JColors.line),
              ),
              child: Row(
                children: [
                  PlateBadge(city: _fromCity!),
                  const Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: RouteLine(),
                    ),
                  ),
                  PlateBadge(city: _toCity!),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCargoStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionLabel('Ne taşınacak?'),
        TextField(
          controller: _cargoController,
          style: JText.body(15),
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            hintText: 'Örn. paletli gıda, rulo sac, mobilya…',
            prefixIcon:
                Icon(Icons.inventory_2_outlined, color: JColors.textFaint),
          ),
        ),
        const SizedBox(height: 32),
        const SectionLabel('Tonaj'),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
          decoration: BoxDecoration(
            color: JColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: JColors.line),
          ),
          child: Column(
            children: [
              Text('${_weight.round()} ton',
                  style: JText.mono(30, color: JColors.amber)),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: JColors.amber,
                  inactiveTrackColor: JColors.line,
                  thumbColor: JColors.amber,
                  overlayColor: JColors.amber.withValues(alpha: 0.15),
                ),
                child: Slider(
                  value: _weight,
                  min: 1,
                  max: 40,
                  divisions: 39,
                  onChanged: (v) {
                    if (v.round() != _weight.round()) {
                      HapticFeedback.selectionClick();
                    }
                    setState(() => _weight = v);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const SectionLabel('Araç tipi'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final v in VehicleType.values)
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _vehicle = v);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  decoration: BoxDecoration(
                    color: _vehicle == v
                        ? JColors.amber
                        : JColors.surfaceHi,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color:
                            _vehicle == v ? JColors.amber : JColors.line),
                  ),
                  child: Text(
                    v.label,
                    style: JText.body(
                      13.5,
                      weight: FontWeight.w600,
                      color: _vehicle == v
                          ? const Color(0xFF1A1102)
                          : JColors.text,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleStep() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SectionLabel('Yükleme tarihi'),
        Row(
          children: [
            for (final (offset, label) in [
              (0, 'Bugün'),
              (1, 'Yarın'),
              (2, '2 gün'),
              (3, '3 gün'),
            ]) ...[
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _dayOffset = offset);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _dayOffset == offset
                          ? JColors.amber
                          : JColors.surfaceHi,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _dayOffset == offset
                              ? JColors.amber
                              : JColors.line),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: JText.body(
                          13,
                          weight: FontWeight.w700,
                          color: _dayOffset == offset
                              ? const Color(0xFF1A1102)
                              : JColors.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (offset < 3) const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 32),
        const SectionLabel('Hedef fiyat (opsiyonel)'),
        TextField(
          controller: _priceController,
          keyboardType: TextInputType.number,
          style: JText.mono(17),
          decoration: const InputDecoration(
            hintText: '0',
            prefixText: '₺ ',
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Boş bırakırsanız şoförler serbest teklif verir.',
          style: JText.body(12.5, color: JColors.textFaint),
        ),
        const SizedBox(height: 32),
        if (_fromCity != null && _toCity != null) ...[
          const SectionLabel('Özet'),
          Container(
            decoration: BoxDecoration(
              color: JColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: JColors.line),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const HazardStripe(height: 6),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _SummaryRow('Güzergâh',
                          '$_fromCity (${plateOf(_fromCity!)}) → $_toCity (${plateOf(_toCity!)})'),
                      _SummaryRow('Yük', _cargoController.text.trim()),
                      _SummaryRow('Tonaj', '${_weight.round()} ton'),
                      _SummaryRow('Araç', _vehicle.label),
                      _SummaryRow(
                          'Tarih',
                          formatDate(DateTime.now()
                              .add(Duration(days: _dayOffset)))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 86,
            child: Text(label.toUpperCase(), style: JText.label(10.5)),
          ),
          Expanded(
            child: Text(value,
                style: JText.body(14, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _CityField extends StatelessWidget {
  const _CityField({
    required this.label,
    required this.city,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? city;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: JColors.surfaceHi,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: city != null ? JColors.amber : JColors.line),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: city != null ? JColors.amber : JColors.textFaint,
                size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: JText.label(10)),
                  const SizedBox(height: 3),
                  Text(
                    city ?? 'Şehir seçin',
                    style: city != null
                        ? JText.title(16)
                        : JText.body(15, color: JColors.textFaint),
                  ),
                ],
              ),
            ),
            if (city != null) PlateBadge(city: city!, size: 0.8),
          ],
        ),
      ),
    );
  }
}

class _CityPicker extends StatefulWidget {
  const _CityPicker({required this.title});
  final String title;

  @override
  State<_CityPicker> createState() => _CityPickerState();
}

class _CityPickerState extends State<_CityPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final cities = allCities
        .where((c) => c.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      maxChildSize: 0.92,
      builder: (context, scroll) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: JColors.line,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: JText.title(19)),
                const SizedBox(height: 14),
                TextField(
                  autofocus: false,
                  style: JText.body(15),
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    hintText: 'Şehir ara…',
                    prefixIcon:
                        Icon(Icons.search_rounded, color: JColors.textFaint),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              itemCount: cities.length,
              itemBuilder: (context, i) {
                final city = cities[i];
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).pop(city);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: JColors.surfaceHi,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: JColors.line),
                    ),
                    child: Row(
                      children: [
                        PlateBadge(city: city, size: 0.75),
                        const SizedBox(width: 14),
                        Text(city,
                            style:
                                JText.body(15, weight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
