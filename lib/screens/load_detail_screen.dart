import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';

/// Yük verenin ilan detayı: teklifleri karşılaştırır, kabul eder,
/// atanmış taşımayı zaman çizelgesiyle takip eder.
class LoadDetailScreen extends StatelessWidget {
  const LoadDetailScreen({super.key, required this.load});

  final Load load;

  void _confirmAccept(BuildContext context, Offer offer) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Teklifi kabul et', style: JText.title(20)),
            const SizedBox(height: 8),
            Text(
              '${offer.carrierName} (${offer.plate}) ile '
              '${formatPrice(offer.price)} bedelle anlaşacaksınız. '
              'Diğer teklifler otomatik reddedilir.',
              style: JText.body(14, color: JColors.textDim),
            ),
            const SizedBox(height: 24),
            JButton(
              label: 'Onayla ve Aracı Ata',
              icon: Icons.handshake_outlined,
              onTap: () {
                appState.acceptOffer(load, offer);
                HapticFeedback.heavyImpact();
                Navigator.of(sheetContext).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('İlan Detayı', style: JText.title(17)),
      ),
      body: ListenableBuilder(
        listenable: appState,
        builder: (context, _) {
          final pendingOffers = load.offers
              .where((o) => o.status == OfferStatus.pending)
              .toList();
          final accepted = load.acceptedOffer;

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
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
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(load.cargoType,
                                      style: JText.title(18)),
                                ),
                                StatusChip(status: load.status),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    PlateBadge(
                                        city: load.fromCity, size: 1.15),
                                    const SizedBox(height: 8),
                                    Text(load.fromCity,
                                        style: JText.body(13,
                                            color: JColors.textDim)),
                                  ],
                                ),
                                Expanded(
                                  child: Column(
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: RouteLine(),
                                      ),
                                      const SizedBox(height: 6),
                                      Text('${load.distanceKm} km',
                                          style: JText.mono(12,
                                              color: JColors.textFaint)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    PlateBadge(
                                        city: load.toCity, size: 1.15),
                                    const SizedBox(height: 8),
                                    Text(load.toCity,
                                        style: JText.body(13,
                                            color: JColors.textDim)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                color: JColors.surfaceHi,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _Spec('TONAJ',
                                      '${load.weightTon.round()} t'),
                                  _Spec('ARAÇ', load.vehicleType.label),
                                  _Spec('TARİH',
                                      formatDate(load.pickupDate)),
                                  if (load.targetPrice != null)
                                    _Spec('HEDEF',
                                        formatPrice(load.targetPrice!),
                                        accent: true),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              if (accepted != null) ...[
                StaggerIn(
                    index: 1,
                    child: const SectionLabel('Atanan taşıyıcı')),
                StaggerIn(
                  index: 2,
                  child: _CarrierCard(offer: accepted),
                ),
                const SizedBox(height: 28),
                StaggerIn(
                    index: 3, child: const SectionLabel('Taşıma durumu')),
                StaggerIn(
                  index: 4,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: JColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: JColors.line),
                    ),
                    child: TrackingTimeline(load: load),
                  ),
                ),
              ] else ...[
                StaggerIn(
                  index: 1,
                  child: SectionLabel(
                      'Gelen teklifler (${pendingOffers.length})'),
                ),
                if (pendingOffers.isEmpty)
                  const StaggerIn(
                    index: 2,
                    child: EmptyState(
                      icon: Icons.hourglass_empty_rounded,
                      title: 'Henüz teklif yok',
                      subtitle:
                          'İlanınız şoförlere ulaştı. İlk teklifler\ngenellikle 30 dakika içinde gelir.',
                    ),
                  )
                else
                  for (var i = 0; i < pendingOffers.length; i++)
                    StaggerIn(
                      index: 2 + i,
                      child: _OfferCard(
                        offer: pendingOffers[i],
                        isBest: pendingOffers[i].price ==
                            pendingOffers
                                .map((o) => o.price)
                                .reduce((a, b) => a < b ? a : b),
                        onAccept: () =>
                            _confirmAccept(context, pendingOffers[i]),
                      ),
                    ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Spec extends StatelessWidget {
  const _Spec(this.label, this.value, {this.accent = false});
  final String label;
  final String value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: JText.label(9.5)),
        const SizedBox(height: 4),
        Text(value,
            style: JText.mono(13,
                color: accent ? JColors.amber : JColors.text)),
      ],
    );
  }
}

class _CarrierCard extends StatelessWidget {
  const _CarrierCard({required this.offer});
  final Offer offer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: JColors.surface,
        borderRadius: BorderRadius.circular(22),
        border:
            Border.all(color: JColors.green.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: JColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.local_shipping_outlined,
                color: JColors.green, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.carrierName, style: JText.title(15.5)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(offer.plate,
                        style: JText.mono(12, color: JColors.textDim)),
                    const SizedBox(width: 10),
                    const Icon(Icons.star_rounded,
                        size: 14, color: JColors.amber),
                    Text(' ${offer.rating}',
                        style: JText.body(12, color: JColors.textDim)),
                  ],
                ),
              ],
            ),
          ),
          Text(formatPrice(offer.price),
              style: JText.mono(17, color: JColors.green)),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.isBest,
    required this.onAccept,
  });

  final Offer offer;
  final bool isBest;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: JColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: isBest
                ? JColors.amber.withValues(alpha: 0.55)
                : JColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: JColors.surfaceHi,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: JColors.line),
                ),
                child: Center(
                  child: Text(
                    offer.carrierName
                        .split(' ')
                        .map((w) => w[0])
                        .take(2)
                        .join(),
                    style: JText.title(15, color: JColors.amber),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(offer.carrierName,
                              style: JText.title(15),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isBest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: JColors.amber,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text('EN İYİ FİYAT',
                                style: JText.label(8.5,
                                    color: const Color(0xFF1A1102))),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: JColors.amber),
                        Text(
                          ' ${offer.rating} · ${offer.tripCount} sefer · ${offer.plate}',
                          style:
                              JText.body(12, color: JColors.textDim),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(formatPrice(offer.price),
                  style: JText.mono(17, color: JColors.amber)),
            ],
          ),
          if (offer.note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: JColors.surfaceHi,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('“${offer.note}”',
                  style: JText.body(12.5, color: JColors.textDim)),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onAccept();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: JColors.amber,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text('Teklifi Kabul Et',
                            style: JText.title(14,
                                color: const Color(0xFF1A1102))),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
