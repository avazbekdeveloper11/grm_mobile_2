// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../l10n/strings.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/theme_provider.dart';
import '../../services/sms_service.dart';
import '../../utils/order_number.dart';
import '../../utils/phone_utils.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/call_button.dart';
import '../../widgets/paginated_list.dart';
import '../../widgets/select_driver_dialog.dart';
import '../../widgets/status_badge.dart';
import '../profile_screen.dart';
import '../worker/worker_home.dart' show WorkerOrderDetailScreen;

class UpakovchikHome extends StatefulWidget {
  const UpakovchikHome({super.key});

  @override
  State<UpakovchikHome> createState() => _UpakovchikHomeState();
}

class _UpakovchikHomeState extends State<UpakovchikHome> {
  int _navIndex = 0;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
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
    final isDark = theme.brightness == Brightness.dark;

    final source = provider.searchQuery.isNotEmpty
        ? provider.searchItems
        : provider.orders;

    // Barcha upakovka zakazlar — umumiy navbat
    final active =
        source.where((o) => o.status == OrderStatus.upakovka).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    // Faqat o'zi paketlagan bajarilgan zakazlar
    final done =
        source
            .where(
              (o) =>
                  (o.status == OrderStatus.tayyor ||
                      o.status == OrderStatus.yetkazildi) &&
                  o.assignedUpakovchikId == user.id,
            )
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
                  SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.statusUpakovka.withValues(
                        alpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      s.upakovchikLabel,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.statusUpakovka,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (active.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.statusUpakovka.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.statusUpakovka.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                      child: Text(
                        '${active.length} vazifa',
                        style: const TextStyle(
                          color: AppColors.statusUpakovka,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(52),
                child: Padding(
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
                                  context.read<OrderProvider>().setSearch('');
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
                  child: _UpakovchikTaskList(
                    active: active,
                    done: done,
                    hasMore: provider.searchQuery.isNotEmpty
                        ? provider.searchHasMore
                        : false,
                    isLoadingMore: provider.searchQuery.isNotEmpty
                        ? provider.searchLoadingMore
                        : false,
                    onLoadMore: provider.searchQuery.isNotEmpty
                        ? provider.loadMoreSearch
                        : _upakovNoop,
                    onRefresh: provider.searchQuery.isNotEmpty
                        ? provider.reloadSearch
                        : provider.loadOrders,
                  ),
                ),
                const ProfileBody(),
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
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2),
            label: 'Vazifalar',
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
}

Future<void> _upakovNoop() async {}

class _UpakovchikTaskList extends StatelessWidget {
  final List<OrderModel> active;
  final List<OrderModel> done;
  final bool hasMore;
  final bool isLoadingMore;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;
  const _UpakovchikTaskList({
    required this.active,
    required this.done,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore = _upakovNoop,
    this.onRefresh = _upakovNoop,
  });

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    if (active.isEmpty && done.isEmpty) {
      return AppEmptyState(
        icon: Icons.inventory_2_outlined,
        title: s.noUpakovchikTasks,
        subtitle: 'Sizga tayinlangan upakovka vazifalari yo\'q',
      );
    }

    final all = [...active, ...done];
    if (hasMore || isLoadingMore) {
      return ServerPaginatedList<OrderModel>(
        items: all,
        totalCount: hasMore ? all.length + 1 : all.length,
        isLoading: false,
        isLoadingMore: isLoadingMore,
        onRefresh: onRefresh,
        onLoadMore: onLoadMore,
        padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.lg),
        itemBuilder: (ctx, order, _) => _UpakovchikCard(order: order),
      );
    }
    return PaginatedList<OrderModel>(
      items: all,
      pageSize: 20,
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, AppSpacing.lg),
      itemBuilder: (ctx, order, _) => _UpakovchikCard(order: order),
    );
  }
}

class _UpakovchikCard extends StatelessWidget {
  final OrderModel order;
  const _UpakovchikCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fmt = DateFormat('dd.MM.yyyy');
    final statusColor = Color(order.status.colorValue);
    final isDone = order.status != OrderStatus.upakovka;

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
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => WorkerOrderDetailScreen(order: order),
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
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
                            StatusBadge(status: order.status),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _InfoRow(
                          Icons.phone_outlined,
                          formatPhone(order.phone),
                          isPhone: true,
                          phone: order.phone,
                        ),
                        if (order.itemsSummary != null &&
                            order.itemsSummary!.hasItems)
                          _InfoRow(
                            Icons.inventory_2_outlined,
                            order.itemsSummary!.displayText,
                          ),
                        _InfoRow(Icons.location_on_outlined, order.address),
                        _InfoRow(
                          Icons.event_outlined,
                          '${s.deliveryDatePrefix}${fmt.format(order.deliveryDate)}',
                        ),
                        if (!isDone) ...[
                          const SizedBox(height: AppSpacing.md),
                          _AnimatedPackButton(
                            label:
                                '${OrderStatus.tayyor.labelOf(s)}${s.moveTo}',
                            onPressed: () => _moveToTayyor(context),
                          ),
                        ] else ...[
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
                                  s.packagingDone,
                                  style: TextStyle(
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

  Future<void> _moveToTayyor(BuildContext context) async {
    final s = S(context.read<ThemeProvider>().language);
    final provider = context.read<OrderProvider>();

    // Confirm bottom sheet
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
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
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.success,
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
                    colors: [
                      AppColors.success,
                      AppColors.success.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: AppRadius.lgAll,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.3),
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
                            '${s.statusTayyor} ${s.moveTo}',
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

    if (confirm != true || !context.mounted) return;

    // Driver tanlash
    final driverResult = await showSelectDriverDialog(
      context,
      currentDriverId: order.assignedDriverId,
    );
    if (!context.mounted) return;
    if (!driverResult.confirmed) return;

    final myId = context.read<AuthProvider>().currentUser?.id;
    final smsResult = await provider.updateOrderStatus(
      order.id,
      OrderStatus.tayyor,
      driverId: driverResult.driver?.id,
      upakovchikId: myId,
    );

    if (context.mounted) {
      final msg = smsResult == SmsResult.sent
          ? s.readySmsSent
          : smsResult == SmsResult.permissionDenied
          ? s.readySmsNoPermit
          : s.readyOk;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isPhone;
  final String? phone;
  const _InfoRow(this.icon, this.text, {this.isPhone = false, this.phone});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(icon, size: 13, color: c),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 13, color: c),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isPhone && phone != null) ...[
            const SizedBox(width: 6),
            CallButton(phone: phone!, mini: true),
          ],
        ],
      ),
    );
  }
}

class _AnimatedPackButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  const _AnimatedPackButton({required this.label, required this.onPressed});

  @override
  State<_AnimatedPackButton> createState() => _AnimatedPackButtonState();
}

class _AnimatedPackButtonState extends State<_AnimatedPackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

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
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _ctrl,
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
              colors: [
                AppColors.success,
                AppColors.success.withValues(alpha: 0.75),
              ],
            ),
            borderRadius: AppRadius.lgAll,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Colors.white,
                size: 16,
              ),
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
