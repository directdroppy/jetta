import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

/// Şoförün gördüğü ilan detayı: yük bilgisi + teklif verme akışı.
class MarketDetailScreen extends StatelessWidget {
  const MarketDetailScreen({super.key, required this.load});

  final Load load;

  void _openOfferSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _OfferSheet(load: load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Yük Detayı', style: JText.title(17))),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final offered = appState.myOfferLoadIds.contains(load.id);
          final perKm = load.targetPrice != null
              ? (load.targetPrice! / load.distanceKm).toStringAsFixed(0)
              : null;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  children: [
                    StaggerIn(
                      index: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: JColors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: JColors.line),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            const HazardStripe(height: 6),
                            Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      PlateBadge(
                                          city: load.fromCity, size: 1.3),
                                      const Icon(Icons.arrow_forward_rounded,
                                          color: JColors.amber),
                                      PlateBadge(
                                          city: load.toCity, size: 1.3),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(load.fromCity,
                                          style: JText.title(15)),
                                      Text('${load.distanceKm} km',
                                          style: JText.mono(13,
                                              color: JColors.textFaint)),
                                      Text(load.toCity,
                                          style: JText.title(15)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const RouteLine(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    StaggerIn(
                        index: 1, child: const SectionLabel('Yük bilgisi')),
                    StaggerIn(
                      index: 2,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: JColors.surface,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: JColors.line),
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                                icon: Icons.inventory_2_outlined,
                                label: 'Yük',
                                value: load.cargoType),
                            _DetailRow(
                                icon: Icons.scale_outlined,
                                label: 'Tonaj',
                                value: '${load.weightTon.round()} ton'),
                            _DetailRow(
                                icon: Icons.local_shipping_outlined,
                                label: 'İstenen araç',
                                value:
                                    '${load.vehicleType.label} — ${load.vehicleType.detail}'),
                            _DetailRow(
                                icon: Icons.calendar_today_outlined,
                                label: 'Yükleme tarihi',
                                value: formatDate(load.pickupDate)),
                            _DetailRow(
                                icon: Icons.business_outlined,
                                label: 'Yük veren',
                                value: load.ownerName,
                                isLast: true),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    StaggerIn(
                        index: 3, child: const SectionLabel('Kazanç')),
                    StaggerIn(
                      index: 4,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              JColors.amber.withValues(alpha: 0.14),
                              JColors.surface,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                              color:
                                  JColors.amber.withValues(alpha: 0.35)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('HEDEF FİYAT',
                                      style: JText.label(10)),
                                  const SizedBox(height: 6),
                                  Text(
                                    load.targetPrice != null
                                        ? formatPrice(load.targetPrice!)
                                        : 'Serbest teklif',
                                    style: JText.mono(24,
                                        color: JColors.amber),
                                  ),
                                ],
                              ),
                            ),
                            if (perKm != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('KM BAŞINA', style: JText.label(10)),
                                  const SizedBox(height: 6),
                                  Text('₺$perKm/km',
                                      style: JText.mono(16,
                                          color: JColors.textDim)),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: offered
                    ? Container(
                        height: 58,
                        decoration: BoxDecoration(
                          color: JColors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color:
                                  JColors.green.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                color: JColors.green, size: 20),
                            const SizedBox(width: 8),
                            Text('Teklifiniz iletildi',
                                style: JText.title(15,
                                    color: JColors.green)),
                          ],
                        ),
                      )
                    : JButton(
                        label: 'Teklif Ver',
                        icon: Icons.gavel_rounded,
                        onTap: () => _openOfferSheet(context),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: JColors.textFaint),
          const SizedBox(width: 14),
          SizedBox(
            width: 105,
            child: Text(label,
                style: JText.body(13, color: JColors.textDim)),
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

class _OfferSheet extends StatefulWidget {
  const _OfferSheet({required this.load});
  final Load load;

  @override
  State<_OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<_OfferSheet> {
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final target = widget.load.targetPrice;
    if (target != null) _priceController.text = target.toString();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final price = int.tryParse(
        _priceController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (price == null || price <= 0) return;
    appState.makeOffer(widget.load, price, _noteController.text.trim());
    HapticFeedback.heavyImpact();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('Teklifinizi verin',
                        style: JText.title(20))),
                Text(
                  '${plateOf(widget.load.fromCity)} → ${plateOf(widget.load.toCity)}',
                  style: JText.mono(15, color: JColors.textDim),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.load.cargoType} · ${widget.load.weightTon.round()} ton · ${widget.load.distanceKm} km',
              style: JText.body(13, color: JColors.textDim),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: JText.mono(20, color: JColors.amber),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixText: '₺ ',
                hintText: 'Teklif tutarı',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteController,
              maxLines: 2,
              style: JText.body(14),
              decoration: const InputDecoration(
                hintText:
                    'Not ekleyin (örn. "Boş dönüşüm, sabah hazırım")',
              ),
            ),
            const SizedBox(height: 22),
            JButton(
              label: 'Teklifi Gönder',
              icon: Icons.send_rounded,
              onTap: int.tryParse(_priceController.text
                          .replaceAll(RegExp(r'[^0-9]'), '')) !=
                      null
                  ? _submit
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
