// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.dart';
import '../../models/order_model.dart';
import '../../providers/theme_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../services/api_service.dart';
import '../../utils/order_number.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/paginated_list.dart';
import '../../utils/phone_utils.dart';
import '../../utils/latin_to_cyrillic.dart';
import '../../widgets/call_button.dart';
import '../../widgets/status_badge.dart';
import '../login_screen.dart';
import '../profile_screen.dart';

class WorkerHome extends StatefulWidget {
  const WorkerHome({super.key});

  @override
  State<WorkerHome> createState() => _WorkerHomeState();
}

class _WorkerHomeState extends State<WorkerHome>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _navIndex = 0;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    final source = provider.searchQuery.isNotEmpty
        ? provider.searchItems
        : provider.orders;

    // Ochrat: barcha qabulQilindi zakazlar (hali hech kim yuvmagan)
    final ochrat =
        source.where((o) => o.status == OrderStatus.qabulQilindi).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    // Yuvyapman: barcha yuvilyapti zakazlar
    final yuvyapman =
        source.where((o) => o.status == OrderStatus.yuvilyapti).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Bajarildi: barcha tugagan zakazlar
    final done =
        source
            .where(
              (o) =>
                  o.status == OrderStatus.upakovka ||
                  o.status == OrderStatus.tayyor ||
                  o.status == OrderStatus.yetkazildi,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
              centerTitle: true,
              automaticallyImplyLeading: false,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white
                          : const Color(0xFF0A1628),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s.workerLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF6BAEFF)
                          : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(100),
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
                            hintText: s.search,
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
                      controller: _tabController,
                      tabAlignment: TabAlignment.center,
                      tabs: [
                        _WorkerTab(
                          label: 'Ochrat',
                          count: ochrat.length,
                          color: Color(OrderStatus.qabulQilindi.colorValue),
                        ),
                        _WorkerTab(
                          label: 'Yuvyapman',
                          count: yuvyapman.length,
                          color: Color(OrderStatus.yuvilyapti.colorValue),
                        ),
                        _WorkerTab(
                          label: 'Bajarildi',
                          count: done.length,
                          color: AppColors.success,
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
                    controller: _tabController,
                    children: [
                      _OchratList(
                        orders: ochrat,
                        userId: user.id,
                        hasMore: provider.searchQuery.isNotEmpty
                            ? provider.searchHasMore
                            : false,
                        isLoadingMore: provider.searchQuery.isNotEmpty
                            ? provider.searchLoadingMore
                            : false,
                        onLoadMore: provider.searchQuery.isNotEmpty
                            ? provider.loadMoreSearch
                            : _noop,
                        onRefresh: provider.searchQuery.isNotEmpty
                            ? provider.reloadSearch
                            : provider.loadOrders,
                      ),
                      _WorkerTaskList(
                        orders: yuvyapman,
                        mode: _WorkerMode.yuvyapman,
                        hasMore: provider.searchQuery.isNotEmpty
                            ? provider.searchHasMore
                            : false,
                        isLoadingMore: provider.searchQuery.isNotEmpty
                            ? provider.searchLoadingMore
                            : false,
                        onLoadMore: provider.searchQuery.isNotEmpty
                            ? provider.loadMoreSearch
                            : _noop,
                        onRefresh: provider.searchQuery.isNotEmpty
                            ? provider.reloadSearch
                            : provider.loadOrders,
                      ),
                      _WorkerTaskList(
                        orders: done,
                        mode: _WorkerMode.done,
                        hasMore: provider.searchQuery.isNotEmpty
                            ? provider.searchHasMore
                            : false,
                        isLoadingMore: provider.searchQuery.isNotEmpty
                            ? provider.searchLoadingMore
                            : false,
                        onLoadMore: provider.searchQuery.isNotEmpty
                            ? provider.loadMoreSearch
                            : _noop,
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.work_outline),
            selectedIcon: const Icon(Icons.work),
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
    final confirm = await showDialog<bool>(
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
    if (confirm == true && mounted) {
      final auth = context.read<AuthProvider>();
      await auth.logout();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }
}

enum _WorkerMode { yuvyapman, done }

class _WorkerTab extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _WorkerTab({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Tab(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

// Ochratdagi barcha qabulQilindi zakazlar — ishchi birini oladi
class _OchratList extends StatelessWidget {
  final List<OrderModel> orders;
  final String userId;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;
  const _OchratList({
    required this.orders,
    required this.userId,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore = _noop,
    this.onRefresh = _noop,
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: 'Ochratda zakaz yo\'q',
        subtitle: 'Driver zakazlarni olib kelgach bu yerda ko\'rinadi',
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
        padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.lg),
        itemBuilder: (ctx, order, _) => _WorkerOrderCard(
          order: order,
          mode: _WorkerMode.yuvyapman,
          userId: userId,
        ),
      );
    }
    return PaginatedList<OrderModel>(
      items: orders,
      pageSize: 20,
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.lg),
      itemBuilder: (ctx, order, _) => _WorkerOrderCard(
        order: order,
        mode: _WorkerMode.yuvyapman,
        userId: userId,
      ),
    );
  }
}

class _WorkerTaskList extends StatelessWidget {
  final List<OrderModel> orders;
  final _WorkerMode mode;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;
  const _WorkerTaskList({
    required this.orders,
    required this.mode,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore = _noop,
    this.onRefresh = _noop,
  });

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    if (orders.isEmpty) {
      return AppEmptyState(
        icon: mode == _WorkerMode.done
            ? Icons.task_alt_rounded
            : Icons.local_laundry_service_outlined,
        title: mode == _WorkerMode.done
            ? s.noDoneOrders
            : 'Hozirda yuvayotgan zakaz yo\'q',
        subtitle: mode == _WorkerMode.done
            ? 'Bajarilgan buyurtmalar bu yerda ko\'rinadi'
            : 'Ochratdan zakaz oling',
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
        padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.lg),
        itemBuilder: (ctx, order, _) =>
            _WorkerOrderCard(order: order, mode: mode),
      );
    }
    return PaginatedList<OrderModel>(
      items: orders,
      pageSize: 20,
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.lg),
      itemBuilder: (ctx, order, _) =>
          _WorkerOrderCard(order: order, mode: mode),
    );
  }
}

Future<void> _noop() async {}

class _WorkerOrderCard extends StatelessWidget {
  final OrderModel order;
  final _WorkerMode mode;
  final String? userId; // ochrat uchun: worker o'zini tayinlash
  const _WorkerOrderCard({
    required this.order,
    required this.mode,
    this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final theme = Theme.of(context);
    final fmt = DateFormat('dd.MM.yyyy');
    final statusColor = Color(order.status.colorValue);

    // Mode ga qarab keyingi status
    final OrderStatus? next = mode == _WorkerMode.done
        ? null
        : order.status == OrderStatus.qabulQilindi
        ? OrderStatus
              .yuvilyapti // ochrat → yuvishni boshlash
        : order.status == OrderStatus.yuvilyapti
        ? OrderStatus
              .upakovka // yuvyapman → upakovkaga
        : null;

    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: isDark
              ? AppColors.borderDark.withValues(alpha: 0.5)
              : AppColors.borderLight,
        ),
        boxShadow: isDark ? null : AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          borderRadius: AppRadius.lgAll,
          splashColor: statusColor.withValues(alpha: 0.08),
          onTap: () => _showItems(context),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Status bar
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
                        Row(
                          children: [
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
                                      ? const Color(0xFF6BAEFF)
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                order.customerName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0A1628),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Flexible(child: StatusBadge(status: order.status)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _Row(Icons.phone_outlined, order.phone, isPhone: true),
                        _Row(
                          Icons.inventory_2_outlined,
                          order.itemsSummary != null &&
                                  order.itemsSummary!.hasItems
                              ? order.itemsSummary!.displayText
                              : order.status == OrderStatus.yuvilyapti ||
                                    order.status == OrderStatus.upakovka ||
                                    order.status == OrderStatus.tayyor ||
                                    order.status == OrderStatus.yetkazildi
                              ? '${s.pickedUp} ✓'
                              : s.driverNotPickedYet,
                        ),
                        _Row(Icons.location_on_outlined, order.address),
                        _Row(
                          Icons.event_outlined,
                          '${s.deliveryDatePrefix}${fmt.format(order.deliveryDate)}',
                        ),
                        if (next != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _AnimatedStatusButton(
                            label: next == OrderStatus.yuvilyapti
                                ? 'Yuvishni boshlash'
                                : "${next.labelOf(s)}${s.moveTo}",
                            color: Color(next.colorValue),
                            onPressed: () => _updateStatus(context, next),
                          ),
                        ],
                        if (mode == _WorkerMode.done) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(
                                alpha: isDark ? 0.15 : 0.08,
                              ),
                              borderRadius: AppRadius.smAll,
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.check_circle_outline,
                                  color: AppColors.success,
                                  size: 14,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  s.washingDoneLabel,
                                  style: const TextStyle(
                                    color: AppColors.success,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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

  Future<void> _showItems(BuildContext context) async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkerOrderDetailScreen(order: order)),
    );
  }

  Future<void> _updateStatus(BuildContext context, OrderStatus next) async {
    final s = S(context.read<ThemeProvider>().language);
    final provider = context.read<OrderProvider>();

    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final nextColor = Color(next.colorValue);
        return Container(
          margin: const EdgeInsets.all(AppSpacing.lg),
          padding: const EdgeInsets.all(AppSpacing.x2l),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
            borderRadius: AppRadius.x2lAll,
            boxShadow: AppShadows.elevated,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: nextColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Icon(
                      Icons.arrow_circle_up_rounded,
                      color: nextColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${order.carpetCount} ta gilam  •  ${order.address}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x2l),
              Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [nextColor, nextColor.withValues(alpha: 0.7)],
                  ),
                  borderRadius: AppRadius.lgAll,
                  boxShadow: [
                    BoxShadow(
                      color: nextColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: AppRadius.lgAll,
                  child: InkWell(
                    borderRadius: AppRadius.lgAll,
                    onTap: () => Navigator.pop(ctx, true),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            "${next.labelOf(s)}${s.moveTo}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.cancel),
              ),
            ],
          ),
        );
      },
    );

    if (confirm == true && context.mounted) {
      // "Yuvilyapti"ga o'tkazishda worker o'zini tayinlaydi
      final workerId = next == OrderStatus.yuvilyapti ? userId : null;

      await provider.updateOrderStatus(order.id, next, workerId: workerId);
      if (context.mounted) {
        final msg = '${s.statusUpdatedMsg}${next.labelOf(s)}';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: null,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _AnimatedStatusButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const _AnimatedStatusButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  State<_AnimatedStatusButton> createState() => _AnimatedStatusButtonState();
}

class _AnimatedStatusButtonState extends State<_AnimatedStatusButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _ctrl;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.reverse(),
        onTapUp: (_) {
          _ctrl.forward();
          widget.onPressed();
        },
        onTapCancel: () => _ctrl.forward(),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color, widget.color.withValues(alpha: 0.75)],
            ),
            borderRadius: AppRadius.lgAll,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_forward, color: Colors.white, size: 16),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final bool isPhone;
  const _Row(this.icon, this.text, {this.color, this.isPhone = false});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              isPhone ? formatPhone(text) : text,
              style: TextStyle(fontSize: 13, color: c),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isPhone) ...[
            const SizedBox(width: 6),
            CallButton(phone: text, mini: true),
          ],
        ],
      ),
    );
  }
}

// ─── Worker order detail screen ───────────────────────────────────────────────

class WorkerOrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  const WorkerOrderDetailScreen({super.key, required this.order});

  @override
  State<WorkerOrderDetailScreen> createState() =>
      _WorkerOrderDetailScreenState();
}

class _WorkerOrderDetailScreenState extends State<WorkerOrderDetailScreen> {
  List<Map<String, dynamic>>? _items;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final api = context.read<ApiService>();
      final data = await api.getOrderItems(widget.order.id);
      if (mounted)
        setState(() {
          _items = data.cast<Map<String, dynamic>>();
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat('dd.MM.yyyy');
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(title: Text(orderNumber(order.id)), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mijoz ma'lumotlari
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : AppColors.cardLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.customerName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      formatPhone(order.phone),
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(width: 8),
                    CallButton(phone: order.phone, mini: true),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        order.address,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.event_outlined, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${s.deliveryDatePrefix}${dateFmt.format(order.deliveryDate)}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                StatusBadge(status: order.status),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Xizmatlar
          Text(
            'Xizmatlar ro\'yxati',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_items == null || _items!.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                s.servicesNotEntered,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 15),
              ),
            )
          else ...[
            ...() {
              // Bir xil xizmatlarni guruhlash
              final grouped = <String, Map<String, dynamic>>{};
              for (final item in _items!) {
                final name = item['service_name']?.toString() ?? '';
                final unitType = item['unit_type']?.toString() ?? '';
                final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
                final area = (item['area'] as num?)?.toDouble() ?? 0;
                // meter uchun dona soni notes da saqlanadi: '3ta'
                final notes = item['notes']?.toString() ?? '';
                final pieceCount = unitType == 'meter'
                    ? (int.tryParse(notes.replaceAll(RegExp(r'[^0-9]'), '')) ??
                          0)
                    : 0;
                if (grouped.containsKey(name)) {
                  grouped[name]!['qty'] += qty;
                  grouped[name]!['area'] += area;
                  grouped[name]!['count'] =
                      (grouped[name]!['count'] as int) + 1;
                  grouped[name]!['pieceCount'] =
                      (grouped[name]!['pieceCount'] as int) + pieceCount;
                } else {
                  grouped[name] = {
                    'qty': qty,
                    'area': area,
                    'unitType': unitType,
                    'count': 1,
                    'pieceCount': pieceCount,
                  };
                }
              }
              return grouped.entries.map((e) {
                final name = e.key;
                final unitType = e.value['unitType'] as String;
                final qty = e.value['qty'] as double;
                final area = e.value['area'] as double;
                final count = e.value['count'] as int;
                final pieceCount = e.value['pieceCount'] as int;

                String qtyText;
                if (unitType == 'sqm') {
                  qtyText = '$count dona  •  ${area.toStringAsFixed(1)} m²';
                } else if (unitType == 'meter') {
                  final pc = pieceCount > 0 ? pieceCount : count;
                  qtyText = '$pc dona  •  ${qty.toStringAsFixed(1)} m';
                } else {
                  qtyText = '${qty.toInt()} dona';
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.layers_outlined,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.read<ThemeProvider>().language ==
                                      AppLanguage.uzCyrillic
                                  ? latinToCyrillic(name)
                                  : name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              qtyText,
                              style: TextStyle(
                                fontSize: 14,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            }(),
          ],
        ],
      ),
    );
  }
}
