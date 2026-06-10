import 'package:flutter/material.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'create_load_screen.dart';
import 'load_detail_screen.dart';
import 'profile_screen.dart';

class ShipperShell extends StatefulWidget {
  const ShipperShell({super.key});

  @override
  State<ShipperShell> createState() => _ShipperShellState();
}

class _ShipperShellState extends State<ShipperShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _tab,
          children: const [_MyLoadsTab(), ProfileTab()],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: JBottomNav(
          index: _tab,
          items: const [
            (Icons.inventory_2_outlined, 'Yüklerim'),
            (Icons.person_outline, 'Profil'),
          ],
          onChanged: (i) => setState(() => _tab = i),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _tab == 0
          ? Padding(
              padding: const EdgeInsets.only(bottom: 78),
              child: SizedBox(
                width: 200,
                child: JButton(
                  label: 'Yeni Yük İlanı',
                  icon: Icons.add_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const CreateLoadScreen()),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

class _MyLoadsTab extends StatelessWidget {
  const _MyLoadsTab();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final loads = appState.myLoads;
        final active = loads
            .where((l) =>
                l.status == LoadStatus.assigned ||
                l.status == LoadStatus.inTransit)
            .length;
        final waitingOffers =
            loads.fold<int>(0, (sum, l) => sum + l.pendingOfferCount);

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
                                Text('Merhaba,',
                                    style: JText.body(15,
                                        color: JColors.textDim)),
                                Text(appState.userName,
                                    style: JText.display(26)),
                              ],
                            ),
                          ),
                          Text('JETTA', style: JText.display(18)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    StaggerIn(
                      index: 1,
                      child: Row(
                        children: [
                          _StatCard(
                              value: '${loads.length}',
                              label: 'Toplam İlan'),
                          const SizedBox(width: 12),
                          _StatCard(
                              value: '$waitingOffers',
                              label: 'Bekleyen Teklif',
                              highlight: waitingOffers > 0),
                          const SizedBox(width: 12),
                          _StatCard(value: '$active', label: 'Aktif Taşıma'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    StaggerIn(
                        index: 2,
                        child: const SectionLabel('Yük ilanlarım')),
                  ],
                ),
              ),
            ),
            if (loads.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Henüz ilanınız yok',
                  subtitle:
                      'İlk yük ilanınızı oluşturun, dakikalar içinde\nteklif almaya başlayın.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 160),
                sliver: SliverList.builder(
                  itemCount: loads.length,
                  itemBuilder: (context, i) {
                    final load = loads[i];
                    return StaggerIn(
                      index: 3 + i,
                      child: LoadCard(
                        load: load,
                        trailing: load.status == LoadStatus.open
                            ? Text(
                                '${load.pendingOfferCount} teklif',
                                style:
                                    JText.mono(13, color: JColors.amber),
                              )
                            : null,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LoadDetailScreen(load: load),
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
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    this.highlight = false,
  });

  final String value;
  final String label;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: highlight
              ? JColors.amber.withValues(alpha: 0.1)
              : JColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: highlight
                  ? JColors.amber.withValues(alpha: 0.45)
                  : JColors.line),
        ),
        child: Column(
          children: [
            Text(value,
                style: JText.mono(22,
                    color: highlight ? JColors.amber : JColors.text)),
            const SizedBox(height: 4),
            Text(label, style: JText.body(11, color: JColors.textDim)),
          ],
        ),
      ),
    );
  }
}
