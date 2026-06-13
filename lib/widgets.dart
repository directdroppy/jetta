import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'theme.dart';

/// Aramalı şehir seçici alt sayfa — hem yük sihirbazı hem harita ekranı kullanır.
Future<String?> showCityPickerSheet(BuildContext context, String title) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CityPickerSheet(title: title),
  );
}

class _CityPickerSheet extends StatefulWidget {
  const _CityPickerSheet({required this.title});
  final String title;

  @override
  State<_CityPickerSheet> createState() => _CityPickerSheetState();
}

class _CityPickerSheetState extends State<_CityPickerSheet> {
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
                            style: JText.body(15, weight: FontWeight.w600)),
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

String formatPrice(int price) {
  final s = price.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '₺$buf';
}

String formatDate(DateTime d) {
  const months = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];
  return '${d.day} ${months[d.month - 1]}';
}

/// Kademeli giriş: liste elemanları sırayla aşağıdan süzülerek belirir.
class StaggerIn extends StatefulWidget {
  const StaggerIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final CurvedAnimation _a =
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 60 * math.min(widget.index, 8)), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) => Opacity(
        opacity: _a.value,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - _a.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// İkaz şeridi — kamyon arkası sarı/siyah çapraz çizgiler. İnce bir
/// vurgu bandı olarak kullanılır.
class HazardStripe extends StatelessWidget {
  const HazardStripe({super.key, this.height = 5, this.opacity = 1});

  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _HazardPainter(),
      ),
    );
  }
}

class _HazardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final amber = Paint()..color = JColors.amber;
    final dark = Paint()..color = const Color(0xFF14181F);
    canvas.drawRect(Offset.zero & size, dark);
    const w = 14.0;
    for (var x = -size.height; x < size.width + size.height; x += w * 2) {
      final path = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + size.height, 0)
        ..lineTo(x + size.height + w, 0)
        ..lineTo(x + w, size.height)
        ..close();
      canvas.drawPath(path, amber);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Plaka kodu rozeti — TR plakası gibi: mavi bant + kod.
class PlateBadge extends StatelessWidget {
  const PlateBadge({super.key, required this.city, this.size = 1});

  final String city;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF2),
        borderRadius: BorderRadius.circular(6 * size),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9 * size,
            height: 34 * size,
            color: const Color(0xFF1B4CC4),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 9 * size),
            child: Text(
              plateOf(city),
              style: JText.mono(19 * size, color: const Color(0xFF12161C)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rota çizgisi: çıkış noktası → animasyonlu kesik çizgi → varış.
/// Otoyol şerit çizgisi gibi akar.
class RouteLine extends StatefulWidget {
  const RouteLine({super.key, this.animate = true});

  final bool animate;

  @override
  State<RouteLine> createState() => _RouteLineState();
}

class _RouteLineState extends State<RouteLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) =>
            CustomPaint(painter: _RoutePainter(_c.value)),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final dotPaint = Paint()..color = JColors.amber;
    final hollow = Paint()
      ..color = JColors.amber
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(Offset(4, y), 4, dotPaint);
    canvas.drawCircle(Offset(size.width - 5, y), 4.5, hollow);

    final dashPaint = Paint()
      ..color = JColors.textFaint
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 7.0;
    const gap = 6.0;
    final start = 14.0;
    final end = size.width - 16;
    final offset = t * (dash + gap);
    for (var x = start - (dash + gap) + offset; x < end; x += dash + gap) {
      final x1 = math.max(x, start);
      final x2 = math.min(x + dash, end);
      if (x2 > x1) {
        canvas.drawLine(Offset(x1, y), Offset(x2, y), dashPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) => oldDelegate.t != t;
}

/// Basılınca yaylanan, dokunsal geri bildirimli birincil buton.
class JButton extends StatefulWidget {
  const JButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool filled;

  @override
  State<JButton> createState() => _JButtonState();
}

class _JButtonState extends State<JButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final fg = widget.filled ? const Color(0xFF1A1102) : JColors.amber;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              HapticFeedback.mediumImpact();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? 0.965 : 1,
        duration: const Duration(milliseconds: 110),
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.4,
          duration: const Duration(milliseconds: 200),
          child: Container(
            height: 58,
            decoration: BoxDecoration(
              gradient: widget.filled
                  ? const LinearGradient(
                      colors: [JColors.amber, JColors.amberDeep],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              border: widget.filled
                  ? null
                  : Border.all(color: JColors.amber, width: 1.4),
              borderRadius: BorderRadius.circular(18),
              boxShadow: widget.filled && enabled
                  ? [
                      BoxShadow(
                        color: JColors.amber.withValues(alpha: 0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: fg, size: 21),
                  const SizedBox(width: 9),
                ],
                Text(widget.label,
                    style: JText.title(16, color: fg)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final LoadStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, _) = switch (status) {
      LoadStatus.open => (JColors.amber, 0),
      LoadStatus.assigned => (JColors.blue, 1),
      LoadStatus.inTransit => (JColors.blue, 2),
      LoadStatus.delivered => (JColors.green, 3),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == LoadStatus.inTransit)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _Pulse(color: color),
            ),
          Text(status.label,
              style: JText.label(10.5, color: color)),
        ],
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.color});
  final Color color;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: 7,
        height: 7,
        decoration:
            BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(text.toUpperCase(), style: JText.label(11)),
          const SizedBox(width: 12),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: JColors.surfaceHi,
                shape: BoxShape.circle,
                border: Border.all(color: JColors.line),
              ),
              child: Icon(icon, size: 36, color: JColors.textFaint),
            ),
            const SizedBox(height: 24),
            Text(title, style: JText.title(18), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: JText.body(14, color: JColors.textDim),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// Yük kartı — pazar ve "yüklerim" listelerinin ana yapı taşı.
class LoadCard extends StatelessWidget {
  const LoadCard({
    super.key,
    required this.load,
    required this.onTap,
    this.trailing,
  });

  final Load load;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: JColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: JColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(load.cargoType,
                            style: JText.title(16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      StatusChip(status: load.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PlateBadge(city: load.fromCity),
                          const SizedBox(height: 6),
                          Text(load.fromCity,
                              style:
                                  JText.body(12, color: JColors.textDim)),
                        ],
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: RouteLine(),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          PlateBadge(city: load.toCity),
                          const SizedBox(height: 6),
                          Text(load.toCity,
                              style:
                                  JText.body(12, color: JColors.textDim)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              decoration: const BoxDecoration(
                color: JColors.surfaceHi,
                border: Border(top: BorderSide(color: JColors.line)),
              ),
              child: Row(
                children: [
                  _Meta(icon: Icons.scale_outlined, text: '${load.weightTon.toStringAsFixed(load.weightTon % 1 == 0 ? 0 : 1)} ton'),
                  const SizedBox(width: 16),
                  _Meta(
                      icon: Icons.local_shipping_outlined,
                      text: load.vehicleType.label),
                  const SizedBox(width: 16),
                  _Meta(
                      icon: Icons.calendar_today_outlined,
                      text: formatDate(load.pickupDate)),
                  const Spacer(),
                  if (trailing != null)
                    trailing!
                  else if (load.targetPrice != null)
                    Text(formatPrice(load.targetPrice!),
                        style: JText.mono(15, color: JColors.amber)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Taşıma durum zaman çizelgesi — dikey adımlar, aktif adımda nabız.
class TrackingTimeline extends StatelessWidget {
  const TrackingTimeline({super.key, required this.load});

  final Load load;

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('Araç atandı', 'Taşıyıcı ile anlaşma sağlandı', LoadStatus.assigned),
      ('Yükleme & yola çıkış', '${load.fromCity} çıkışı yapıldı',
          LoadStatus.inTransit),
      ('Teslim edildi', '${load.toCity} teslimatı tamamlandı',
          LoadStatus.delivered),
    ];
    final currentIndex = switch (load.status) {
      LoadStatus.open => -1,
      LoadStatus.assigned => 0,
      LoadStatus.inTransit => 1,
      LoadStatus.delivered => 2,
    };

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _TimelineStep(
            title: steps[i].$1,
            subtitle: steps[i].$2,
            state: i < currentIndex
                ? _StepState.done
                : i == currentIndex
                    ? (load.status == LoadStatus.delivered
                        ? _StepState.done
                        : _StepState.active)
                    : _StepState.todo,
            isLast: i == steps.length - 1,
          ),
      ],
    );
  }
}

enum _StepState { done, active, todo }

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    required this.state,
    required this.isLast,
  });

  final String title;
  final String subtitle;
  final _StepState state;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      _StepState.done => JColors.green,
      _StepState.active => JColors.amber,
      _StepState.todo => JColors.textFaint,
    };
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              if (state == _StepState.active)
                _PulsingDot(color: color)
              else
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state == _StepState.done
                        ? color.withValues(alpha: 0.15)
                        : Colors.transparent,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: state == _StepState.done
                      ? Icon(Icons.check_rounded, size: 13, color: color)
                      : null,
                ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: state == _StepState.done
                        ? JColors.green.withValues(alpha: 0.5)
                        : JColors.line,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: JText.title(15,
                          color: state == _StepState.todo
                              ? JColors.textFaint
                              : JColors.text)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: JText.body(12.5, color: JColors.textDim)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 10 + 12 * _c.value,
              height: 10 + 12 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color
                    .withValues(alpha: 0.4 * (1 - _c.value)),
              ),
            ),
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                  shape: BoxShape.circle, color: widget.color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Yüzen hap (pill) alt gezinme çubuğu.
class JBottomNav extends StatelessWidget {
  const JBottomNav({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  });

  final List<(IconData, String)> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 14),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: JColors.surfaceHi,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: JColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(i);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: i == index ? JColors.amber : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        items[i].$1,
                        size: 22,
                        color: i == index
                            ? const Color(0xFF1A1102)
                            : JColors.textDim,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        items[i].$2,
                        style: JText.body(
                          10.5,
                          weight: FontWeight.w600,
                          color: i == index
                              ? const Color(0xFF1A1102)
                              : JColors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: JColors.textFaint),
        const SizedBox(width: 5),
        Text(text, style: JText.body(12, color: JColors.textDim)),
      ],
    );
  }
}
