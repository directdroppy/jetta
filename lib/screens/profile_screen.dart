import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'role_select_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final isShipper = appState.role == UserRole.shipper;
        final initials = appState.userName
            .split(' ')
            .where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase())
            .take(2)
            .join();

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
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
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [JColors.amber, JColors.amberDeep],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: Text(
                                initials.isEmpty ? 'J' : initials,
                                style: JText.display(22,
                                    color: const Color(0xFF1A1102)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(appState.userName,
                                    style: JText.title(18)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: JColors.amber
                                        .withValues(alpha: 0.12),
                                    borderRadius:
                                        BorderRadius.circular(100),
                                  ),
                                  child: Text(
                                    isShipper
                                        ? 'YÜK VEREN'
                                        : 'ŞOFÖR / NAKLİYECİ',
                                    style: JText.label(9.5,
                                        color: JColors.amber),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              const Icon(Icons.star_rounded,
                                  color: JColors.amber, size: 22),
                              Text('5.0', style: JText.mono(14)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            StaggerIn(index: 1, child: const SectionLabel('Hesap')),
            StaggerIn(
              index: 2,
              child: _MenuGroup(items: [
                if (isShipper) ...[
                  (Icons.business_outlined, 'Firma bilgileri',
                      'Vergi no, adres, yetkili'),
                  (Icons.receipt_long_outlined, 'Faturalarım',
                      'e-Fatura & e-İrsaliye'),
                ] else ...[
                  (Icons.badge_outlined, 'Belgelerim',
                      'K1/K2 yetki belgesi, SRC, ehliyet'),
                  (Icons.local_shipping_outlined, 'Araçlarım',
                      'Çekici ve dorse bilgileri'),
                ],
                (Icons.account_balance_wallet_outlined, 'Ödemeler',
                    'IBAN ve ödeme geçmişi'),
                (Icons.notifications_outlined, 'Bildirimler',
                    'Yük ve teklif uyarıları'),
              ]),
            ),
            const SizedBox(height: 24),
            StaggerIn(index: 3, child: const SectionLabel('Destek')),
            StaggerIn(
              index: 4,
              child: _MenuGroup(items: const [
                (Icons.headset_mic_outlined, '7/24 Destek hattı',
                    'Canlı destek ile görüşün'),
                (Icons.shield_outlined, 'Güvenlik & sigorta',
                    'Yük sigortası kapsamı'),
              ]),
            ),
            const SizedBox(height: 28),
            StaggerIn(
              index: 5,
              child: JButton(
                label: 'Rol Değiştir / Çıkış',
                icon: Icons.swap_horiz_rounded,
                filled: false,
                onTap: () {
                  appState.logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (_) => const RoleSelectScreen()),
                    (route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: Text('Jetta v0.1 — MVP Prototip',
                  style: JText.body(12, color: JColors.textFaint)),
            ),
          ],
        );
      },
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items});

  final List<(IconData, String, String)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: JColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: JColors.line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: JColors.surfaceHi,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    content: Text(
                        '"${items[i].$2}" bir sonraki sürümde geliyor.',
                        style: JText.body(13)),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: JColors.surfaceHi,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(items[i].$1,
                          size: 20, color: JColors.amber),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(items[i].$2,
                              style: JText.body(14.5,
                                  weight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(items[i].$3,
                              style: JText.body(12,
                                  color: JColors.textDim)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: JColors.textFaint),
                  ],
                ),
              ),
            ),
            if (i < items.length - 1)
              const Divider(height: 1, indent: 74),
          ],
        ],
      ),
    );
  }
}
