import 'package:flutter/material.dart';

/// Local in-memory pagination (backwards compat).
class PaginatedList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final int pageSize;
  final EdgeInsets? padding;
  final Future<void> Function()? onRefresh;
  final Widget? emptyWidget;

  const PaginatedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.pageSize = 20,
    this.padding,
    this.onRefresh,
    this.emptyWidget,
  });

  @override
  State<PaginatedList<T>> createState() => _PaginatedListState<T>();
}

class _PaginatedListState<T> extends State<PaginatedList<T>> {
  late int _visibleCount;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _visibleCount = widget.pageSize;
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant PaginatedList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _visibleCount = widget.pageSize;
      if (_scrollCtrl.hasClients) _scrollCtrl.jumpTo(0);
    }
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      if (_visibleCount < widget.items.length) {
        setState(() => _visibleCount += widget.pageSize);
      }
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    final total = items.length;

    if (total == 0) {
      return widget.emptyWidget ?? const SizedBox.shrink();
    }

    final visible = _visibleCount.clamp(0, total);
    final hasMore = visible < total;

    Widget list = ListView.builder(
      controller: _scrollCtrl,
      padding: widget.padding ?? const EdgeInsets.only(bottom: 16),
      itemCount: visible + 1,
      itemBuilder: (ctx, i) {
        if (i < visible) return widget.itemBuilder(ctx, items[i], i);
        if (hasMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        return const SizedBox(height: 80);
      },
    );

    if (widget.onRefresh != null) {
      list = RefreshIndicator(onRefresh: widget.onRefresh!, child: list);
    }
    return list;
  }
}

/// Server-side paginated list with infinite scroll.
class ServerPaginatedList<T> extends StatefulWidget {
  final List<T> items;
  final int totalCount;
  final bool isLoading;
  final bool isLoadingMore;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final Widget? emptyWidget;
  final EdgeInsets? padding;

  const ServerPaginatedList({
    super.key,
    required this.items,
    required this.totalCount,
    required this.isLoading,
    required this.isLoadingMore,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    this.emptyWidget,
    this.padding,
  });

  @override
  State<ServerPaginatedList<T>> createState() => _ServerPaginatedListState<T>();
}

class _ServerPaginatedListState<T> extends State<ServerPaginatedList<T>> {
  final _scrollCtrl = ScrollController();
  bool _loadingMoreLock = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      if (!widget.isLoadingMore && !_loadingMoreLock && widget.items.length < widget.totalCount) {
        _loadingMoreLock = true;
        widget.onLoadMore().whenComplete(() {
          if (mounted) setState(() => _loadingMoreLock = false);
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.items.isEmpty) {
      return widget.emptyWidget ?? const SizedBox.shrink();
    }

    final hasMore = widget.items.length < widget.totalCount;

    Widget list = ListView.builder(
      controller: _scrollCtrl,
      padding: widget.padding ?? const EdgeInsets.only(bottom: 16),
      itemCount: widget.items.length + 1,
      itemBuilder: (ctx, i) {
        if (i < widget.items.length) return widget.itemBuilder(ctx, widget.items[i], i);
        if (hasMore || widget.isLoadingMore) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        return const SizedBox(height: 80);
      },
    );

    return RefreshIndicator(onRefresh: widget.onRefresh, child: list);
  }
}
