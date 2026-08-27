import 'dart:async';

import 'package:flutter/material.dart';

import 'api/models.dart';
import 'api/rastreio_api.dart';
import 'l10n/app_localizations.dart';

typedef PageLoader<T> = Future<Paginated<T>> Function(int page, String query);

/// Lista com scroll infinito sobre o paginador do Laravel.
///
/// A busca pode ser resolvida no servidor ([serverSearch] com o parâmetro
/// `busca`) ou localmente sobre o que já foi carregado, via [localFilter] —
/// `/embarcacoes` não oferece busca, então lá o filtro é local.
class PaginatedList<T> extends StatefulWidget {
  const PaginatedList({
    super.key,
    required this.loader,
    required this.itemBuilder,
    this.serverSearch = false,
    this.localFilter,
    this.onUnauthorized,
  });

  final PageLoader<T> loader;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool serverSearch;
  final bool Function(T item, String query)? localFilter;
  final VoidCallback? onUnauthorized;

  @override
  State<PaginatedList<T>> createState() => _PaginatedListState<T>();
}

class _PaginatedListState<T> extends State<PaginatedList<T>> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final List<T> _items = [];

  int _page = 0;
  bool _hasMore = true;
  bool _loading = false;
  String? _error;
  String _query = '';
  Timer? _debounce;

  bool get _searchEnabled => widget.serverSearch || widget.localFilter != null;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNext();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 320) {
      _loadNext();
    }
  }

  Future<void> _loadNext() async {
    if (_loading || !_hasMore) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.loader(_page + 1, _query);
      if (!mounted) return;
      setState(() {
        _page = result.currentPage;
        _hasMore = result.hasMore;
        _items.addAll(result.items);
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
      if (error.isUnauthorized) widget.onUnauthorized?.call();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reload() async {
    setState(() {
      _items.clear();
      _page = 0;
      _hasMore = true;
      _error = null;
    });
    await _loadNext();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      _query = value.trim();
      if (widget.serverSearch) {
        _reload();
      } else {
        setState(() {});
      }
    });
  }

  List<T> get _visibleItems {
    final filter = widget.localFilter;
    if (widget.serverSearch || filter == null || _query.isEmpty) return _items;
    return _items.where((item) => filter(item, _query)).toList();
  }

  Widget _buildFooter(AppLocalizations localizations) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: _loadNext,
              child: Text(localizations.retryButton),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final items = _visibleItems;
    final showEmpty = items.isEmpty && !_loading && _error == null;

    return Column(
      children: [
        if (_searchEnabled)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _onQueryChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: localizations.searchLabel,
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == items.length) {
                  if (showEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(child: Text(localizations.emptyListMessage)),
                    );
                  }
                  return _buildFooter(localizations);
                }
                return widget.itemBuilder(context, items[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
}
