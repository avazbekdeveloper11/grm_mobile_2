import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../models/order_model.dart';
import '../providers/theme_provider.dart';

class StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = S(context.read<ThemeProvider>().language);
    final color = Color(status.colorValue);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: _Badge(
        key: ValueKey(status),
        label: status.labelOf(s),
        color: color,
        isDark: isDark,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;
  const _Badge({super.key, required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: AppRadius.x2lAll,
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? color.withValues(alpha: 0.9) : color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class PaymentBadge extends StatelessWidget {
  final PaymentStatus status;
  const PaymentBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final s = S(context.read<ThemeProvider>().language);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = switch (status) {
      PaymentStatus.tolangan  => AppColors.success,
      PaymentStatus.qarz      => AppColors.warning,
      PaymentStatus.tolanmagan => AppColors.error,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.12),
        borderRadius: AppRadius.x2lAll,
        border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
      ),
      child: Text(
        status.labelOf(s),
        style: TextStyle(
          color: isDark ? color.withValues(alpha: 0.9) : color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
