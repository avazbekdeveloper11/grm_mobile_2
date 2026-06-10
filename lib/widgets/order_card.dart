import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../l10n/strings.dart';
import '../models/order_model.dart';
import '../providers/theme_provider.dart';
import '../utils/map_utils.dart';
import '../utils/order_number.dart';
import '../utils/phone_utils.dart';
import 'resolved_address_text.dart';
import 'call_button.dart';
import 'status_badge.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;
  final bool showPrice;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.trailing,
    this.compact = false,
    this.showPrice = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fmt = DateFormat('dd.MM.yyyy');
    final moneyFmt = NumberFormat('#,###');

    final statusColor = Color(order.status.colorValue);
    final isOverdue =
        order.status != OrderStatus.yangi &&
        order.status != OrderStatus.yetkazildi &&
        order.deliveryDate.isBefore(DateTime.now());
    final isToday = _isToday(order.deliveryDate);
    // Faqat address koordinata formatida bo'lganda reverse geocode qilamiz
    final addressCoords = coordsFromAddress(order.address);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.5)
              : isDark
              ? AppColors.borderDark.withValues(alpha: 0.5)
              : AppColors.borderLight,
          width: isOverdue ? 1.5 : 1,
        ),
        boxShadow: isDark ? null : AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          splashColor: statusColor.withValues(alpha: 0.08),
          highlightColor: statusColor.withValues(alpha: 0.04),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Status accent bar
                Container(
                  width: 4,
                  margin: const EdgeInsets.symmetric(
                    vertical: 10,
                  ).copyWith(left: 3),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header row
                        Row(
                          children: [
                            // Order number
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(
                                right: AppSpacing.sm,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary.withValues(
                                      alpha: isDark ? 0.3 : 0.12,
                                    ),
                                    AppColors.accent.withValues(
                                      alpha: isDark ? 0.2 : 0.08,
                                    ),
                                  ],
                                ),
                                borderRadius: AppRadius.smAll,
                              ),
                              child: Text(
                                orderNumber(order.id),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (order.fromBot)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                margin: const EdgeInsets.only(
                                  right: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.info.withValues(alpha: 0.12),
                                  borderRadius: AppRadius.smAll,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.smart_toy_outlined,
                                      size: 11,
                                      color: AppColors.info,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      s.botBadge,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.info,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            Expanded(
                              child: Text(
                                order.customerName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                  letterSpacing: -0.2,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isOverdue)
                              Container(
                                margin: const EdgeInsets.only(
                                  left: AppSpacing.xs,
                                ),
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: AppRadius.smAll,
                                ),
                                child: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: AppColors.error,
                                  size: 14,
                                ),
                              )
                            else if (isToday)
                              Container(
                                margin: const EdgeInsets.only(
                                  left: AppSpacing.xs,
                                ),
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: AppRadius.smAll,
                                ),
                                child: const Icon(
                                  Icons.today,
                                  color: AppColors.warning,
                                  size: 14,
                                ),
                              ),
                            if (trailing != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.xs,
                                ),
                                child: trailing!,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        // Info row
                        Row(
                          children: [
                            Icon(
                              Icons.phone_outlined,
                              size: 12,
                              color: cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              formatPhone(order.phone),
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white : cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            CallButton(phone: order.phone, mini: true),
                            const SizedBox(width: AppSpacing.md),
                          ],
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: addressCoords != null
                                    ? ResolvedAddressText(
                                        key: ValueKey('addr_${order.id}'),
                                        lat: addressCoords.lat,
                                        lng: addressCoords.lng,
                                        fallback: order.address,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? Colors.white : cs.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                      )
                                    : Text(
                                        order.address,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark ? Colors.white : cs.onSurfaceVariant,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                              ),
                            ],
                          ),
                        ],
                        if (order.itemsSummary != null &&
                            order.itemsSummary!.hasItems) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 12,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                order.itemsSummary!.displayText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sm),
                        // Footer row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  StatusBadge(status: order.status),
                                  PaymentBadge(status: order.paymentStatus),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (showPrice && order.effectivePrice > 0)
                                  Text(
                                    "${moneyFmt.format(order.effectivePrice)} so'm",
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isDark
                                          ? const Color(0xFF6BAEFF)
                                          : AppColors.primary,
                                    ),
                                  ),
                                Text(
                                  fmt.format(order.pickupDate),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isOverdue
                                        ? AppColors.error
                                        : cs.onSurfaceVariant,
                                    fontWeight: isOverdue
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }
}
