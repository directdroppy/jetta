import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_state.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets.dart';
import 'carrier_shell.dart';
import 'shipper_shell.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  UserRole? _selected;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _continue() {
    final role = _selected;
    if (role == null) return;
    appState.selectRole(role, _nameController.text);
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, anim, _) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
                .animate(CurvedAnimation(
                    parent: anim, curve: Curves.easeOutCubic)),
            child: role == UserRole.shipper
                ? const ShipperShell()
                : const CarrierShell(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StaggerIn(
                index: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('JETTA', style: JText.display(40)),
                        const SizedBox(width: 12),
                        const Expanded(child: HazardStripe(height: 8)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Yükün yolu\nburadan geçer.',
                      style: JText.display(34, color: JColors.textDim)
                          .copyWith(height: 1.12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              StaggerIn(
                index: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: JColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: JColors.line),
                  ),
                  child: Row(
                    children: [
                      const PlateBadge(city: 'İstanbul', size: 0.9),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: RouteLine(),
                        ),
                      ),
                      const PlateBadge(city: 'Ankara', size: 0.9),
                      const SizedBox(width: 14),
                      Text('450 km', style: JText.mono(13, color: JColors.textDim)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),
              StaggerIn(index: 2, child: const SectionLabel('Nasıl kullanacaksınız?')),
              StaggerIn(
                index: 3,
                child: _RoleCard(
                  role: UserRole.shipper,
                  selected: _selected == UserRole.shipper,
                  icon: Icons.inventory_2_outlined,
                  title: 'Yük Verenim',
                  subtitle:
                      'Yükümü ilan ederim, gelen teklifleri karşılaştırır,\naracımı dakikalar içinde bulurum.',
                  onTap: () => setState(() => _selected = UserRole.shipper),
                ),
              ),
              const SizedBox(height: 14),
              StaggerIn(
                index: 4,
                child: _RoleCard(
                  role: UserRole.carrier,
                  selected: _selected == UserRole.carrier,
                  icon: Icons.local_shipping_outlined,
                  title: 'Şoförüm / Nakliyeciyim',
                  subtitle:
                      'Güzergâhıma uygun yükleri görür, teklif verir,\nboş dönüşü kâra çeviririm.',
                  onTap: () => setState(() => _selected = UserRole.carrier),
                ),
              ),
              const SizedBox(height: 26),
              StaggerIn(
                index: 5,
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: JText.body(15),
                  decoration: const InputDecoration(
                    hintText: 'Adınız veya firma adınız (opsiyonel)',
                    prefixIcon:
                        Icon(Icons.person_outline, color: JColors.textFaint),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              StaggerIn(
                index: 6,
                child: JButton(
                  label: 'Yola Çık',
                  icon: Icons.arrow_forward_rounded,
                  onTap: _selected == null ? null : _continue,
                ),
              ),
              const SizedBox(height: 16),
              StaggerIn(
                index: 7,
                child: Center(
                  child: Text(
                    'Prototip sürümü — veriler örnektir',
                    style: JText.body(12, color: JColors.textFaint),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected ? JColors.surfaceHi : JColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? JColors.amber : JColors.line,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: JColors.amber.withValues(alpha: 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: selected
                    ? JColors.amber
                    : JColors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon,
                  color: selected ? const Color(0xFF1A1102) : JColors.amber,
                  size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: JText.title(16.5)),
                  const SizedBox(height: 5),
                  Text(subtitle,
                      style: JText.body(12.5, color: JColors.textDim)),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: selected ? 1 : 0,
              child: const Icon(Icons.check_circle_rounded,
                  color: JColors.amber, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}
