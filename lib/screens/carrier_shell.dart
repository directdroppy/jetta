import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'market_detail_screen.dart';
import 'profile_screen.dart';

class CarrierShell extends StatefulWidget {
  const CarrierShell({super.key});

  @override
  State<CarrierShell> createState() => _CarrierShellState();
}

class _CarrierShellState extends State<CarrierShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: const [_MarketTab(), _MyJobsTab(), ProfileTab()],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: JBottomNav(
          index: _tab,
          items: const [
            (Icons.explore_outlined, 'Yük Pazarı'),
            (Icons.route_outlined, 'Taşımalarım'),
            (Icons.person_outline, 'Profil'),
          ],
          onChanged: (i) => setState(() => _tab = i),
        ),
      ),
    );
  }
}

class _MarketTab extends StatefulWidget {
  const _MarketTab();

  @override
  State<_MarketTab> createState() => _MarketTabState();
}

class _MarketTabState extends State<_MarketTab> {
  String? _cityFilter;
  VehicleType? _vehicleFilter;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        var loads = appState.marketLoads;
        if (_cityFilter != null) {
          loads = loads
              .where((l) =>
                  l.fromCity == _cityFilter || l.toCity == _cityFilter)
              .toList();
        }
        if (_vehicleFilter != null) {
          loads =
              loads.where((l) => l.vehicleType == _vehicleFilter).toList();
        }

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StaggerIn(
                      index: 0,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Yük Pazarı', style: JText.display(26)),
                                const SizedBox(height: 4),
                                Text(
                                  '${loads.length} açık ilan · Türkiye geneli',
                                  style: JText.body(13.5,
                                      color: JColors.textDim),
                                ),
                              ],
                            ),
                          ),
                          Text('JETTA', style: JText.display(18)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    StaggerIn(
                      index: 1,
                      child: SizedBox(
                        height: 42,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterChip(
                              label: _cityFilter ?? 'Şehir',
                              icon: Icons.location_on_outlined,
                              active: _cityFilter != null,
                              onTap: _pickCityFilter,
                            ),
                            const SizedBox(width: 10),
                            for (final v in VehicleType.values) ...[
                              _FilterChip(
                                label: v.label,
                                active: _vehicleFilter == v,
                                onTap: () => setState(() =>
                                    _vehicleFilter =
                                        _vehicleFilter == v ? null : v),
                              ),
                              const SizedBox(width: 10),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                  ],
                ),
              ),
            ),
            if (loads.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Filtreye uygun yük yok',
                  subtitle:
                      'Filtreleri temizleyin veya farklı bir\ngüzergâh deneyin.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                sliver: SliverList.builder(
                  itemCount: loads.length,
                  itemBuilder: (context, i) {
                    final load = loads[i];
                    final offered =
                        appState.myOfferLoadIds.contains(load.id);
                    return StaggerIn(
                      index: 2 + i,
                      child: LoadCard(
                        load: load,
                        trailing: offered
                            ? Text('Teklif verildi',
                                style: JText.body(12,
                                    weight: FontWeight.w700,
                                    color: JColors.green))
                            : (load.targetPrice != null
                                ? Text(formatPrice(load.targetPrice!),
                                    style: JText.mono(15,
                                        color: JColors.amber))
                                : Text('Serbest teklif',
                                    style: JText.body(12,
                                        color: JColors.textDim))),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MarketDetailScreen(load: load),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _pickCityFilter() async {
    HapticFeedback.selectionClick();
    final selected = await showModalBottomSheet<String?>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(24),
          children: [
            Text('Şehre göre filtrele', style: JText.title(18)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final city in allCities)
                  GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(city),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _cityFilter == city
                            ? JColors.amber
                            : JColors.surfaceHi,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: JColors.line),
                      ),
                      child: Text(
                        '${plateOf(city)} $city',
                        style: JText.body(13,
                            weight: FontWeight.w600,
                            color: _cityFilter == city
                                ? const Color(0xFF1A1102)
                                : JColors.text),
                      ),
                    ),
                  ),
              ],
            ),
            if (_cityFilter != null) ...[
              const SizedBox(height: 18),
              JButton(
                label: 'Filtreyi Temizle',
                filled: false,
                onTap: () => Navigator.of(sheetContext).pop('__clear__'),
              ),
            ],
          ],
        ),
      ),
    );
    if (selected != null) {
      setState(
          () => _cityFilter = selected == '__clear__' ? null : selected);
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: active ? JColors.amber : JColors.surfaceHi,
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: active ? JColors.amber : JColors.line),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: active
                      ? const Color(0xFF1A1102)
                      : JColors.textDim),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: JText.body(13,
                  weight: FontWeight.w600,
                  color:
                      active ? const Color(0xFF1A1102) : JColors.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyJobsTab extends StatelessWidget {
  const _MyJobsTab();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final jobs = appState.myJobs;
        final offers = appState.loads
            .where((l) =>
                l.status == LoadStatus.open &&
                appState.myOfferLoadIds.contains(l.id))
            .toList();

        if (jobs.isEmpty && offers.isEmpty) {
          return const EmptyState(
            icon: Icons.route_outlined,
            title: 'Henüz taşımanız yok',
            subtitle:
                'Yük Pazarı\'ndan güzergâhınıza uygun bir yüke\nteklif vererek başlayın.',
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
          children: [
            StaggerIn(
                index: 0,
                child: Text('Taşımalarım', style: JText.display(26))),
            const SizedBox(height: 24),
            if (jobs.isNotEmpty) ...[
              StaggerIn(
                  index: 1, child: const SectionLabel('Aktif taşımalar')),
              for (var i = 0; i < jobs.length; i++)
                StaggerIn(
                  index: 2 + i,
                  child: _JobCard(load: jobs[i]),
                ),
            ],
            if (offers.isNotEmpty) ...[
              const SizedBox(height: 16),
              StaggerIn(
                  index: 2 + jobs.length,
                  child: const SectionLabel('Bekleyen tekliflerim')),
              for (var i = 0; i < offers.length; i++)
                StaggerIn(
                  index: 3 + jobs.length + i,
                  child: LoadCard(
                    load: offers[i],
                    trailing: Text('Yanıt bekleniyor',
                        style: JText.body(12,
                            weight: FontWeight.w700,
                            color: JColors.amber)),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MarketDetailScreen(load: offers[i]),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _JobCard extends StatelessWidget {
  const _JobCard({required this.load});
  final Load load;

  @override
  Widget build(BuildContext context) {
    final price = load.acceptedOffer?.price;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: JColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: load.status == LoadStatus.delivered
                ? JColors.green.withValues(alpha: 0.4)
                : JColors.blue.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(load.cargoType, style: JText.title(16))),
                StatusChip(status: load.status),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                PlateBadge(city: load.fromCity, size: 0.85),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: RouteLine(),
                  ),
                ),
                PlateBadge(city: load.toCity, size: 0.85),
              ],
            ),
            const SizedBox(height: 18),
            TrackingTimeline(load: load),
            if (price != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('ANLAŞILAN BEDEL', style: JText.label(10)),
                  const Spacer(),
                  Text(formatPrice(price),
                      style: JText.mono(17, color: JColors.green)),
                ],
              ),
            ],
            if (load.status != LoadStatus.delivered) ...[
              const SizedBox(height: 16),
              JButton(
                label: load.status == LoadStatus.assigned
                    ? 'Yükü Aldım, Yola Çıktım'
                    : 'Teslimatı Tamamla',
                icon: load.status == LoadStatus.assigned
                    ? Icons.play_arrow_rounded
                    : Icons.flag_rounded,
                onTap: () => appState.advanceLoad(load),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
