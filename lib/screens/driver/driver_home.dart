// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/strings.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart' show ApiException;
import '../../providers/theme_provider.dart';
import '../../services/sms_service.dart';
import '../../widgets/app_shimmer.dart';
import '../../utils/order_number.dart';
import '../../utils/map_utils.dart';
import '../../widgets/resolved_address_text.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/call_button.dart';
import '../../widgets/status_badge.dart';
import '../login_screen.dart';
import '../profile_screen.dart';
import 'pickup_items_screen.dart';
import 'driver_order_detail.dart';
import 'driver_order_form.dart';
import '../../widgets/paginated_list.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});
  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _navIndex = 0;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<OrderProvider>();
    final s = S(context.watch<ThemeProvider>().language);
    final user = auth.currentUser!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final source = provider.searchQuery.isNotEmpty
        ? provider.searchItems
        : provider.orders;

    // Olib kelish — barcha yangi zakazlar (har qanday driver olishi mumkin)
    final pickup = source.where((o) => o.status == OrderStatus.yangi).toList()
      ..sort((a, b) => a.pickupDate.compareTo(b.pickupDate));

    // Yetkazish — tayinlanmagan (hamma driverga ko'rinadi) yoki shu driverga tayinlangan tayyor zakazlar
    final deliver =
        source
            .where(
              (o) =>
                  o.status == OrderStatus.tayyor &&
                  (o.assignedDriverId == null || o.assignedDriverId == user.id),
            )
            .toList()
          ..sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: _navIndex == 1
          ? AppBar(
              backgroundColor: isDark
                  ? AppColors.surfaceDark
                  : AppColors.cardLight,
              title: Text(
                s.profileTitle,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              centerTitle: true,
              automaticallyImplyLeading: false,
            )
          : AppBar(
              backgroundColor: isDark
                  ? AppColors.surfaceDark
                  : AppColors.cardLight,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Row(
                children: [
                  const SizedBox(width: 12),
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF0A1628),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.driverLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.warning,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(96),
                child: Column(
                  children: [

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        8,
                        AppSpacing.lg,
                        AppSpacing.sm,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDark
                              : AppColors.surfaceLight,
                          borderRadius: AppRadius.lgAll,
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) =>
                              context.read<OrderProvider>().setSearch(v),
                          decoration: InputDecoration(
                            hintText: s.filterHint,
                            hintStyle: TextStyle(
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              size: 18,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      context.read<OrderProvider>().setSearch(
                                        '',
                                      );
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                          ),
                        ),
                      ),
                    ),
                    TabBar(
                      controller: _tab,
                      indicatorSize: TabBarIndicatorSize.tab,
                      tabs: [
                        _TabItem(
                          label: s.pickup,
                          count: pickup.length,
                          color: AppColors.warning,
                          icon: Icons.arrow_downward,
                        ),
                        _TabItem(
                          label: s.delivery,
                          count: deliver.length,
                          color: AppColors.success,
                          icon: Icons.arrow_upward,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _navIndex,
              children: [
                RefreshIndicator(
                  onRefresh: () => provider.loadOrders(),
                  child: TabBarView(
                    controller: _tab,
                    children: [
                      _TaskList(
                        orders: pickup,
                        isPickup: true,
                        hasMore: provider.searchQuery.isNotEmpty
                            ? provider.searchHasMore
                            : false,
                        isLoadingMore: provider.searchQuery.isNotEmpty
                            ? provider.searchLoadingMore
                            : false,
                        onLoadMore: provider.searchQuery.isNotEmpty
                            ? provider.loadMoreSearch
                            : _driverNoop,
                        onRefresh: provider.searchQuery.isNotEmpty
                            ? provider.reloadSearch
                            : provider.loadOrders,
                      ),
                      _TaskList(
                        orders: deliver,
                        isPickup: false,
                        hasMore: provider.searchQuery.isNotEmpty
                            ? provider.searchHasMore
                            : false,
                        isLoadingMore: provider.searchQuery.isNotEmpty
                            ? provider.searchLoadingMore
                            : false,
                        onLoadMore: provider.searchQuery.isNotEmpty
                            ? provider.loadMoreSearch
                            : _driverNoop,
                        onRefresh: provider.searchQuery.isNotEmpty
                            ? provider.reloadSearch
                            : provider.loadOrders,
                      ),
                    ],
                  ),
                ),
                ProfileBody(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _navIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () async {
                final added = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const DriverOrderForm()),
                );
                if (added == true && mounted) {
                  context.read<OrderProvider>().loadOrders();
                }
              },
              icon: const Icon(Icons.add),
              label: Text(s.addOrder),
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.local_shipping_outlined),
            selectedIcon: const Icon(Icons.local_shipping),
            label: s.orders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: s.profileTitle,
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final s = S(context.read<ThemeProvider>().language);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.logoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.no),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.yes),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }
}

// ─── Tab item ──────────────────────────────────────────────────────────────────

class _TabItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  const _TabItem({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) => Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

// ─── Task list ─────────────────────────────────────────────────────────────────

Future<void> _driverNoop() async {}

class _TaskList extends StatelessWidget {
  final List<OrderModel> orders;
  final bool isPickup;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;
  const _TaskList({
    required this.orders,
    required this.isPickup,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore = _driverNoop,
    this.onRefresh = _driverNoop,
  });

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    if (orders.isEmpty) {
      return AppEmptyState(
        icon: isPickup
            ? Icons.directions_car_outlined
            : Icons.local_shipping_outlined,
        title: isPickup ? s.noPickupTasks : s.noDeliveryTasks,
      );
    }
    if (hasMore || isLoadingMore) {
      return ServerPaginatedList<OrderModel>(
        items: orders,
        totalCount: hasMore ? orders.length + 1 : orders.length,
        isLoading: false,
        isLoadingMore: isLoadingMore,
        onRefresh: onRefresh,
        onLoadMore: onLoadMore,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        itemBuilder: (ctx, order, _) =>
            _DriverCard(order: order, isPickup: isPickup),
      );
    }
    return PaginatedList<OrderModel>(
      items: orders,
      pageSize: 20,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      itemBuilder: (ctx, order, _) =>
          _DriverCard(order: order, isPickup: isPickup),
    );
  }
}

// ─── Driver card ───────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final OrderModel order;
  final bool isPickup;
  const _DriverCard({required this.order, required this.isPickup});

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = DateFormat('dd.MM.yyyy');
    final date = isPickup ? order.pickupDate : order.deliveryDate;
    final now = DateTime.now();
    final isToday =
        date.day == now.day && date.month == now.month && date.year == now.year;
    final isOverdue = date.isBefore(now) && !isToday;
    final hasLocation = order.pickupLat != null && order.pickupLng != null;
    final hasCarpets = order.carpetCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOverdue ? Colors.red.shade200 : cs.outlineVariant,
          width: isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => DriverOrderDetail(order: order)),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Header strip
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: isPickup
                    ? AppColors.warning.withValues(alpha: 0.07)
                    : AppColors.success.withValues(alpha: 0.07),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isPickup ? Colors.orange : Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isPickup ? Icons.arrow_downward : Icons.arrow_upward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                orderNumber(order.id),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                order.customerName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(
                              isOverdue
                                  ? Icons.warning_amber_rounded
                                  : Icons.calendar_today_outlined,
                              size: 12,
                              color: isOverdue
                                  ? Colors.red
                                  : isToday
                                  ? Colors.orange
                                  : cs.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${isPickup ? s.pickupDatePrefix : s.deliveryDatePrefix}${fmt.format(date)}'
                                '${isOverdue
                                    ? s.lateLabel
                                    : isToday
                                    ? s.todayLabel
                                    : ""}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isOverdue
                                      ? Colors.red
                                      : isToday
                                      ? Colors.orange
                                      : cs.onSurfaceVariant,
                                  fontWeight: isOverdue || isToday
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(status: order.status),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Phone + call
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: cs.onSurfaceVariant,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          formatPhone(order.phone),
                          style: TextStyle(
                            fontSize: 13,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                      CallButton(phone: order.phone, mini: true),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Address — manzil koordinata ko'rinishida bo'lsa, o'qiladigan manzil + xarita tugmasi
                  Builder(
                    builder: (_) {
                      final coords =
                          (order.pickupLat != null && order.pickupLng != null)
                          ? (lat: order.pickupLat!, lng: order.pickupLng!)
                          : coordsFromAddress(order.address);
                      if (coords != null) {
                        return _CoordAddressLine(
                          lat: coords.lat,
                          lng: coords.lng,
                        );
                      }
                      return Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              order.address,
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes_outlined,
                          size: 14,
                          color: cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.notes!,
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Carpet info (if measured)
                  if (hasCarpets) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.layers,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${order.carpetCount} ta gilam',
                            style: const TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (order.effectivePrice > 0) ...[
                            const Spacer(),
                            Text(
                              "${NumberFormat('#,###').format(order.effectivePrice)} so'm",
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  // To'lov holati
                  const SizedBox(height: 10),
                  _PaymentBlock(order: order, isPickup: isPickup),

                  // Pickup location (delivery tab da ko'rsatiladi)
                  if (!isPickup && hasLocation) ...[
                    const SizedBox(height: 10),
                    _LocationChip(
                      lat: order.pickupLat!,
                      lng: order.pickupLng!,
                      address: order.address,
                    ),
                  ],

                  const SizedBox(height: 14),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                children: [
                  if (order.assignedDriverId == null) ...[
                    // Hech kimga tayinlanmagan — birinchi qabul qilgan driver oladi
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.touch_app_outlined, size: 18),
                        label: Text(s.claimOrder),
                        onPressed: () => _claimOrder(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.primary,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ] else if (isPickup) ...[
                    // OLIB KELISH: o'lcham kiritish + olib kelindi → qabulQilindi
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.straighten, size: 18),
                        label: Text(
                          hasCarpets ? s.measureOrChange : s.enterCarpetsPickup,
                        ),
                        onPressed: () => _openPickup(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: hasCarpets
                              ? Color(OrderStatus.qabulQilindi.colorValue)
                              : cs.primary,
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // YETKAZISH: avval to'lov, keyin yetkazildi
                    if (order.paymentStatus == PaymentStatus.tolanmagan) ...[
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.payments, size: 18),
                          label: Text(s.collectPayment),
                          onPressed: () => _collectPayment(context),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
                            minimumSize: const Size(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: Text(s.deliveredBtn),
                        onPressed: () {
                          if (order.paymentStatus == PaymentStatus.tolangan ||
                              order.paymentStatus == PaymentStatus.qarz) {
                            _confirmDelivery(context);
                          } else {
                            _showPaymentRequired(context);
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Color(
                            OrderStatus.yetkazildi.colorValue,
                          ),
                          minimumSize: const Size(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentRequired(BuildContext context) {
    final s = S(context.read<ThemeProvider>().language);
    final fmt = NumberFormat('#,###');
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.payments_outlined, size: 48, color: Colors.orange),
            const SizedBox(height: 14),
            Text(
              s.paymentRequired,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              order.effectivePrice > 0
                  ? "${order.customerName} dan ${fmt.format(order.effectivePrice)} so'm to'lovni oling, so'ng yetkazildi deb belgilang"
                  : "${order.customerName} dan to'lovni oling, so'ng yetkazildi deb belgilang",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.payments),
              label: Text(s.collectPayment),
              onPressed: () {
                Navigator.pop(ctx);
                _collectPayment(context);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.credit_card_off, color: Colors.orange),
              label: Text(
                s.deliverAsDebtBtn,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _deliverAsDebt(context);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(s.cancel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _collectPayment(BuildContext context) async {
    final s = S(context.read<ThemeProvider>().language);
    final fmt = NumberFormat('#,###');
    final hasAdvance = order.advancePayment > 0 && order.effectivePrice > 0;
    final remaining = hasAdvance
        ? (order.effectivePrice - order.advancePayment).clamp(
            0.0,
            double.infinity,
          )
        : order.effectivePrice;
    final sum = order.effectivePrice > 0
        ? "${fmt.format(order.effectivePrice)} so'm"
        : "Summa kiritilmagan";
    final remainingStr = order.effectivePrice > 0
        ? "${fmt.format(remaining)} so'm"
        : "Summa kiritilmagan";

    // result: 'paid' | 'debt' | null
    final result = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.payments, size: 40, color: Colors.green),
            const SizedBox(height: 12),
            Text(
              s.didYouCollect,
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              "${order.customerName}  •  $sum",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            if (hasAdvance) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.totalLabel,
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          sum,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${s.paidInAdvance}:",
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          "${fmt.format(order.advancePayment)} so'm",
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          s.remainingLabel,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          remainingStr,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: Text(
                hasAdvance
                    ? "${s.yesCollected}  •  $remainingStr"
                    : "${s.yesCollected}  •  $sum",
              ),
              onPressed: () => Navigator.pop(ctx, 'paid'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.credit_card_off, color: Colors.orange),
              label: Text(
                s.deliverAsDebtBtn,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              onPressed: () => Navigator.pop(ctx, 'debt'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.orange),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: Text(s.cancel),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      try {
        if (result == 'paid') {
          await context.read<OrderProvider>().collectPayment(order.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.paymentAcceptedMsg),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (result == 'debt') {
          await context.read<OrderProvider>().markAsDebt(order.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(s.deliveredAsDebtMsg),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _openPickup(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => PickupItemsScreen(order: order)));
  }

  Future<void> _claimOrder(BuildContext context) async {
    final s = S(context.read<ThemeProvider>().language);
    final provider = context.read<OrderProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(s.claimOrder),
        content: Text(s.claimOrderConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.claimOrder),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await provider.claimOrder(order.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(s.claimedOk), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final taken = e is ApiException && e.statusCode == 409;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(taken ? s.claimedTaken : 'Xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmDelivery(BuildContext context) async {
    final s = S(context.read<ThemeProvider>().language);
    final provider = context.read<OrderProvider>();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              order.customerName,
              style: Theme.of(
                ctx,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              order.address,
              style: TextStyle(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _PaymentBlock(order: order, isPickup: false, large: true),
            if (order.pickupLat != null) ...[
              const SizedBox(height: 10),
              _LocationChip(
                lat: order.pickupLat!,
                lng: order.pickupLng!,
                address: order.address,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: const Icon(Icons.check),
              label: Text(s.confirmDeliveryBtn),
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: Color(OrderStatus.yetkazildi.colorValue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final sms = await provider.updateOrderStatus(
        order.id,
        OrderStatus.yetkazildi,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sms == SmsResult.sent ? s.deliveredSms : s.deliveredOk,
            ),
            backgroundColor: Color(OrderStatus.yetkazildi.colorValue),
          ),
        );
      }
    }
  }

  Future<void> _deliverAsDebt(BuildContext context) async {
    final s = S(context.read<ThemeProvider>().language);
    final provider = context.read<OrderProvider>();
    try {
      await provider.markAsDebt(order.id);
      if (context.mounted) {
        await provider.updateOrderStatus(order.id, OrderStatus.yetkazildi);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(s.deliveredAsDebtMsg),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ─── Coordinate address line ───────────────────────────────────────────────────
// Manzil koordinata (lat, lng) ko'rinishida bo'lsa — o'qiladigan manzilga
// aylantirib ko'rsatadi va yoniga xaritada ochish tugmasini qo'shadi.

class _CoordAddressLine extends StatelessWidget {
  final double lat;
  final double lng;
  const _CoordAddressLine({required this.lat, required this.lng});

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final cs = Theme.of(context).colorScheme;
    final coordText = '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.location_on_outlined, size: 14, color: cs.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: ResolvedAddressText(
            lat: lat,
            lng: lng,
            fallback: coordText,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            maxLines: 2,
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => openInMaps(lat, lng),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.blue, Color(0xFF1976D2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    s.mapBtn,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Location chip ─────────────────────────────────────────────────────────────

class _LocationChip extends StatelessWidget {
  final double lat;
  final double lng;
  final String address;
  const _LocationChip({
    required this.lat,
    required this.lng,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    return GestureDetector(
      onTap: () => _openMap(lat, lng, address),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_pin, color: Colors.blue, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                s.pickupLocation,
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.open_in_new, color: Colors.blue, size: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap(double lat, double lng, String label) async {
    // Avval Google Maps ilovasini ochishga urinib ko'ramiz
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    if (await canLaunchUrl(geoUri)) {
      await launchUrl(geoUri);
      return;
    }
    // Agar ilova yo'q bo'lsa — brauzerda ochamiz
    final webUri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    await launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}

class _PaymentBlock extends StatelessWidget {
  final OrderModel order;
  final bool isPickup;
  final bool large;

  const _PaymentBlock({
    required this.order,
    required this.isPickup,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final isPaid = order.paymentStatus == PaymentStatus.tolangan;
    final isDebt = order.paymentStatus == PaymentStatus.qarz;
    final fmt = NumberFormat('#,###');
    final hasSum = order.effectivePrice > 0;

    final hasAdvance = order.advancePayment > 0;
    final remaining = hasSum
        ? (order.effectivePrice - order.advancePayment).clamp(
            0.0,
            double.infinity,
          )
        : 0.0;

    if (isDebt) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: large ? 12 : 8),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.credit_card_off,
              color: AppColors.warning,
              size: large ? 22 : 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.deliveredAsDebtLabel,
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: large ? 16 : 13,
                ),
              ),
            ),
            if (hasSum)
              Flexible(
                child: Text(
                  "${fmt.format(order.effectivePrice)} so'm",
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: large ? 16 : 13,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Har doim ko'rsatamiz — to'langan yoki to'lanmagan
    if (isPaid) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: large ? 12 : 8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: large ? 22 : 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.paidLabel,
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: large ? 16 : 13,
                    ),
                  ),
                ),
                if (hasSum)
                  Flexible(
                    child: Text(
                      "${fmt.format(order.effectivePrice)} so'm",
                      textAlign: TextAlign.end,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: large ? 16 : 13,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasAdvance) ...[
              const SizedBox(height: 4),
              Text(
                "${s.paidInAdvance}: ${fmt.format(order.advancePayment)} so'm ${s.paidEarlierSuffix}",
                style: TextStyle(color: Colors.green.shade600, fontSize: 11),
              ),
            ],
          ],
        ),
      );
    }

    // To'lanmagan — diqqat tortuvchi qizil
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: large ? 14 : 10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_rounded,
                color: AppColors.error,
                size: large ? 24 : 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.unpaidBig,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: large ? 17 : 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (hasSum)
                Flexible(
                  child: Text(
                    "${fmt.format(order.effectivePrice)} so'm",
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: large ? 17 : 14,
                    ),
                  ),
                ),
            ],
          ),
          if (hasAdvance && hasSum) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  "${s.paidInAdvance}: ",
                  style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                ),
                Text(
                  "${fmt.format(order.advancePayment)} so'm",
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  "${s.remainingLabel} ",
                  style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                ),
                Text(
                  "${fmt.format(remaining)} so'm",
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
          if (large) ...[
            const SizedBox(height: 6),
            Text(
              isPickup ? s.remindPayment : s.dontForgetMoney,
              style: TextStyle(color: Colors.red.shade600, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
