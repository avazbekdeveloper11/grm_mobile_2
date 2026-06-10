import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/strings.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/order_card.dart';
import 'order_detail_screen.dart';
import 'orders_screen.dart';
import 'worker_stats_screen.dart';
import 'finance_screen.dart';
import 'settings_screen.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    _DashboardScreen(),
    OrdersScreen(),
    FinanceScreen(),
    SettingsScreen(),
  ];

  List<NavigationDestination> _buildDestinations(BuildContext context) {
    final s = S(context.read<ThemeProvider>().language);
    return [
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: s.home,
      ),
      NavigationDestination(
        icon: const Icon(Icons.receipt_long_outlined),
        selectedIcon: const Icon(Icons.receipt_long),
        label: s.orders,
      ),
      NavigationDestination(
        icon: const Icon(Icons.bar_chart_outlined),
        selectedIcon: const Icon(Icons.bar_chart),
        label: s.finance,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: s.settings,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        destinations: _buildDestinations(context),
      ),
    );
  }
}

class _DashboardScreen extends StatelessWidget {
  const _DashboardScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<OrderProvider>();
    final userProvider = context.watch<UserProvider>();
    final s = S(context.watch<ThemeProvider>().language);
    final fmt = NumberFormat('#,###');

    final now = DateTime.now();
    final todayOrders = provider.ordersForDay(now);
    final monthOrders = provider.ordersForMonth(now.year, now.month);
    final newOrders = provider.orders
        .where((o) => o.status == OrderStatus.yangi)
        .toList();
    final readyOrders = provider.orders
        .where((o) => o.status == OrderStatus.tayyor)
        .toList();

    final isDark = theme.brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final adminName = auth.currentUser?.name ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: AppRadius.mdAll,
              ),
              child: Center(
                child: Text(
                  adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${s.hello} $adminName',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0A1628),
                  ),
                ),
                Text(
                  s.managementSystem,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF6BAEFF) : AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(child: RefreshIndicator(
        onRefresh: () => provider.loadOrders(),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.2,
                    children: [
                      _DashCard(
                        title: s.todayOrders,
                        value: '${todayOrders.length}',
                        icon: Icons.today_outlined,
                        color: AppColors.info,
                        onTap: () => _openOrders(
                          context,
                          title: s.todayOrders,
                          isToday: true,
                        ),
                      ),
                      _DashCard(
                        title: s.monthOrders,
                        value: '${monthOrders.length}',
                        icon: Icons.calendar_month_outlined,
                        color: AppColors.primary,
                        onTap: () => _openOrders(
                          context,
                          title: s.monthOrders,
                          isMonth: true,
                        ),
                      ),
                      _DashCard(
                        title: s.newOrders,
                        value: '${newOrders.length}',
                        icon: Icons.fiber_new_outlined,
                        color: AppColors.warning,
                        onTap: () => _openOrders(
                          context,
                          title: s.newOrders,
                          filter: OrderStatus.yangi,
                        ),
                      ),
                      _DashCard(
                        title: s.readyOrders,
                        value: '${readyOrders.length}',
                        icon: Icons.done_all,
                        color: AppColors.success,
                        onTap: () => _openOrders(
                          context,
                          title: s.readyOrders,
                          filter: OrderStatus.tayyor,
                        ),
                      ),
                      _DashCard(
                        title: s.todayIncome,
                        value:
                            "${fmt.format(provider.incomeForDay(now))} ${s.sum}",
                        icon: Icons.attach_money,
                        color: AppColors.accent,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FinanceScreen(),
                          ),
                        ),
                      ),
                      _DashCard(
                        title: s.debt,
                        value: "${fmt.format(provider.pendingIncome)} ${s.sum}",
                        icon: Icons.pending_outlined,
                        color: AppColors.error,
                        onTap: () => _openOrders(
                          context,
                          title: s.debt,
                          orders: provider.orders
                              .where(
                                (o) =>
                                    o.paymentStatus ==
                                        PaymentStatus.tolanmagan ||
                                    o.paymentStatus == PaymentStatus.qarz,
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x2l),
                  Text(
                    s.workersActivity,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0A1628),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (userProvider.isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ...userProvider.activeWorkers.map((w) {
                      final workerOrders = provider.ordersForWorker(w.id);
                      final active = workerOrders
                          .where((o) => o.status != OrderStatus.yetkazildi && o.status != OrderStatus.tayyor)
                          .length;
                      return _WorkerCard(
                        isDark: isDark,
                        name: w.name,
                        totalOrders: workerOrders.length,
                        active: active,
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => WorkerStatsScreen(workerId: w.id, name: w.name),
                        )),
                      );
                    }),
                  if (userProvider.activeUpakovchilar.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.x2l),
                    Text(
                      s.upakovchilarActivity,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0A1628),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...userProvider.activeUpakovchilar.map((u) {
                      final uOrders = provider.ordersForUpakovchik(u.id);
                      final active = uOrders
                          .where((o) => o.status == OrderStatus.upakovka)
                          .length;
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardDark : AppColors.cardLight,
                          borderRadius: AppRadius.lgAll,
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                          boxShadow: isDark ? null : AppShadows.card,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.xs,
                          ),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFF5722).withValues(alpha: isDark ? 0.4 : 0.15),
                                  const Color(0xFFFF8A65).withValues(alpha: isDark ? 0.3 : 0.1),
                                ],
                              ),
                              borderRadius: AppRadius.mdAll,
                            ),
                            child: Center(
                              child: Text(
                                u.name[0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: isDark ? const Color(0xFFFF8A65) : const Color(0xFFFF5722),
                                ),
                              ),
                            ),
                          ),
                          title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(
                            '${uOrders.length} ${s.totalOrders}',
                            style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                          ),
                          trailing: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: active > 0
                                  ? AppColors.warning.withValues(alpha: isDark ? 0.2 : 0.1)
                                  : AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1),
                              borderRadius: AppRadius.x2lAll,
                            ),
                            child: Text(
                              '$active ${s.activeOrders}',
                              style: TextStyle(
                                color: active > 0 ? AppColors.warning : AppColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                  const SizedBox(height: 80),
                ]),
              ),
            ),
          ],
        ),
      )),
        ],
      ),
    );
  }
}

class _DashCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _DashCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.15),
        ),
        boxShadow: isDark ? null : AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.lgAll,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          splashColor: color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.15 : 0.1),
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0A1628),
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper: filtered orders navigation ───────────────────────────────────────

void _openOrders(
  BuildContext context, {
  required String title,
  List<OrderModel>? orders,
  OrderStatus? filter,
  bool isToday = false,
  bool isMonth = false,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          _FilteredOrdersScreen(title: title, orders: orders, filter: filter, isToday: isToday, isMonth: isMonth),
    ),
  );
}

class _FilteredOrdersScreen extends StatelessWidget {
  final String title;
  final List<OrderModel>? orders;
  final OrderStatus? filter;
  final bool isToday;
  final bool isMonth;

  const _FilteredOrdersScreen({required this.title, this.orders, this.filter, this.isToday = false, this.isMonth = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Consumer<OrderProvider>(
        builder: (ctx, provider, _) {
          List<OrderModel> list;
          if (isToday) {
            list = provider.ordersForDay(DateTime.now());
          } else if (isMonth) {
            final now = DateTime.now();
            list = provider.ordersForMonth(now.year, now.month);
          } else if (orders != null) {
            list = orders!;
          } else if (filter != null) {
            list = provider.orders.where((o) => o.status == filter).toList();
          } else {
            list = provider.orders;
          }
          list = [...list]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

          if (list.isEmpty) {
            return const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: "Ma'lumot yo'q",
              subtitle: "Bu bo'limda hozircha buyurtmalar mavjud emas",
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.loadOrders(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
              itemCount: list.length,
              itemBuilder: (ctx, i) => OrderCard(
                order: list[i],
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(order: list[i]),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}


class _WorkerCard extends StatelessWidget {
  final bool isDark;
  final String name;
  final int totalOrders, active;
  final VoidCallback onTap;

  const _WorkerCard({
    required this.isDark,
    required this.name,
    required this.totalOrders,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final s = S(context.read<ThemeProvider>().language);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: AppRadius.lgAll,
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark ? null : AppShadows.card,
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              AppColors.primary.withValues(alpha: isDark ? 0.4 : 0.15),
              AppColors.accent.withValues(alpha: isDark ? 0.3 : 0.1),
            ]),
            borderRadius: AppRadius.mdAll,
          ),
          child: Center(
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: isDark ? const Color(0xFF6BAEFF) : AppColors.primary,
              ),
            ),
          ),
        ),
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text('$totalOrders ${s.orderCountSuffix}',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: active > 0
                ? AppColors.warning.withValues(alpha: isDark ? 0.2 : 0.1)
                : AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: AppRadius.x2lAll,
          ),
          child: Text(
            '$active faol',
            style: TextStyle(
              color: active > 0 ? AppColors.warning : AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
