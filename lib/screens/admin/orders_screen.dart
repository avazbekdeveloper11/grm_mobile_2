import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_shimmer.dart';
import '../../l10n/strings.dart';
import '../../widgets/order_card.dart';
import '../../widgets/paginated_list.dart';
import 'order_form_screen.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  final OrderStatus? initialFilter;
  final String? title;
  const OrdersScreen({super.key, this.initialFilter, this.title});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  OrderStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _filterStatus = widget.initialFilter;
    // Backend chaqirilmaydi — data allaqachon provider'da bor
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<OrderModel> _tabItems(List<OrderModel> items, bool active) {
    final filtered = _filterStatus != null
        ? items.where((o) => o.status == _filterStatus).toList()
        : items;
    if (active) return filtered.where((o) => o.status != OrderStatus.yetkazildi).toList();
    return filtered.where((o) => o.status == OrderStatus.yetkazildi).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = S(context.watch<ThemeProvider>().language);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? s.orders),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: s.active),
            Tab(text: s.delivered),
          ],
        ),
        actions: [
          PopupMenuButton<OrderStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (v) => setState(() => _filterStatus = v),
            itemBuilder: (_) => [
              PopupMenuItem(value: null, child: Text(s.all)),
              ...OrderStatus.values.map(
                (st) => PopupMenuItem(value: st, child: Text(st.labelOf(s))),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Consumer<OrderProvider>(
              builder: (_, prov, child) => TextField(
                controller: _searchCtrl,
                onChanged: (v) => prov.setSearch(v),
                decoration: InputDecoration(
                  hintText: s.filterHint,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            prov.setSearch('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<OrderProvider>(
              builder: (context, provider, _) {
                final activeItems = _tabItems(provider.searchItems, true);
                final deliveredItems = _tabItems(provider.searchItems, false);
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _SearchOrderList(
                      items: activeItems,
                      totalCount: provider.searchTotal,
                      isLoading: provider.searchLoading,
                      isLoadingMore: provider.searchLoadingMore,
                      hasMore: provider.searchHasMore,
                      emptyMsg: s.noActiveOrders,
                      onRefresh: () => provider.reloadSearch(),
                      onLoadMore: () => provider.loadMoreSearch(),
                    ),
                    _SearchOrderList(
                      items: deliveredItems,
                      totalCount: provider.searchTotal,
                      isLoading: provider.searchLoading,
                      isLoadingMore: provider.searchLoadingMore,
                      hasMore: provider.searchHasMore,
                      emptyMsg: s.noDeliveredOrders,
                      onRefresh: () => provider.reloadSearch(),
                      onLoadMore: () => provider.loadMoreSearch(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const OrderFormScreen())),
        icon: const Icon(Icons.add),
        label: Text(s.newOrder),
      ),
    );
  }
}

class _SearchOrderList extends StatelessWidget {
  final List<OrderModel> items;
  final int totalCount;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String emptyMsg;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;

  const _SearchOrderList({
    required this.items,
    required this.totalCount,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMore,
    required this.emptyMsg,
    required this.onRefresh,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      // Show empty only if no more items could come from server
      if (!hasMore) {
        return AppEmptyState(icon: Icons.inbox_outlined, title: emptyMsg);
      }
      // Items for this tab are empty but server has more — trigger load
      return _LoadMoreTrigger(onLoadMore: onLoadMore, onRefresh: onRefresh);
    }

    return ServerPaginatedList<OrderModel>(
      items: items,
      totalCount: hasMore ? totalCount : items.length,
      isLoading: false,
      isLoadingMore: isLoadingMore,
      onRefresh: onRefresh,
      onLoadMore: hasMore ? onLoadMore : () async {},
      itemBuilder: (ctx, order, _) => OrderCard(
        order: order,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
        ),
      ),
    );
  }
}

class _LoadMoreTrigger extends StatefulWidget {
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRefresh;
  const _LoadMoreTrigger({required this.onLoadMore, required this.onRefresh});
  @override
  State<_LoadMoreTrigger> createState() => _LoadMoreTriggerState();
}

class _LoadMoreTriggerState extends State<_LoadMoreTrigger> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLoadMore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: const SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
