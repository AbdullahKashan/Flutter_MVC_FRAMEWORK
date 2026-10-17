import 'dart:async';
import '../core/mvc_controller.dart';
import '../core/mvc_model.dart';
import '../core/request_state.dart';

/// Encapsulates paginated results along with navigation metadata.
class PaginatedResponse<T> {
  /// The collection of items for the current page.
  final List<T> items;

  /// The current page index (1-based).
  final int page;

  /// The maximum number of items requested per page.
  final int pageSize;

  /// The total number of items available across all pages, if provided by the backend.
  final int? totalItems;

  /// The total number of pages available, if provided by the backend.
  final int? totalPages;

  /// Whether additional pages can be loaded.
  final bool hasMore;

  const PaginatedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    this.totalItems,
    this.totalPages,
    required this.hasMore,
  });

  /// Factory to construct a [PaginatedResponse] from common REST API pagination schemas.
  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    JsonParser<T> itemParser, {
    int defaultPage = 1,
    int defaultPageSize = 20,
  }) {
    final rawItems = json['items'] ??
        json['data'] ??
        json['results'] ??
        json['records'] ??
        [];

    final items = MVCModel.fromJsonList<T>(rawItems, itemParser);

    final page = int.tryParse((json['page'] ?? json['current_page'] ?? defaultPage).toString()) ??
        defaultPage;
    final pageSize = int.tryParse(
            (json['page_size'] ?? json['per_page'] ?? json['limit'] ?? defaultPageSize)
                .toString()) ??
        defaultPageSize;

    final totalItems = int.tryParse(
        (json['total'] ?? json['total_count'] ?? json['total_items'] ?? '').toString());
    final totalPages = int.tryParse((json['total_pages'] ?? '').toString());

    bool hasMore;
    if (json.containsKey('has_more') && json['has_more'] is bool) {
      hasMore = json['has_more'];
    } else if (totalPages != null) {
      hasMore = page < totalPages;
    } else if (totalItems != null) {
      hasMore = (page * pageSize) < totalItems;
    } else {
      // Default heuristic: if items received equals page size, more may exist
      hasMore = items.length >= pageSize;
    }

    return PaginatedResponse<T>(
      items: items,
      page: page,
      pageSize: pageSize,
      totalItems: totalItems,
      totalPages: totalPages,
      hasMore: hasMore,
    );
  }
}

/// Function signature for loading a page of items.
typedef PaginationFetcher<T> = Future<PaginatedResponse<T>> Function(
  int page,
  int pageSize,
);

/// Controller specialized for managing paginated data collections, infinite scrolling,
/// and pull-to-refresh workflows.
class PaginationController<T> extends MVCController<List<T>> {
  final PaginationFetcher<T> fetcher;
  final int pageSize;
  final int initialPage;

  int _currentPage;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  dynamic _loadMoreError;

  PaginationController({
    required this.fetcher,
    this.pageSize = 20,
    this.initialPage = 1,
    bool autoLoad = true,
  })  : _currentPage = initialPage,
        super(initialState: const RequestState.idle()) {
    if (autoLoad) {
      // Defer slightly to allow listeners or bindings to attach
      scheduleMicrotask(loadInitial);
    }
  }

  /// The current page index.
  int get currentPage => _currentPage;

  /// Whether there are more items to fetch.
  bool get hasMore => _hasMore;

  /// Whether a background load-more request is currently in flight.
  bool get isLoadingMore => _isLoadingMore;

  /// Error encountered during the most recent [loadMore] invocation, if any.
  dynamic get loadMoreError => _loadMoreError;

  /// Convenience getter for the loaded items list.
  List<T> get items => state.dataOrNull ?? const [];

  /// Loads the initial page, wiping previous items.
  Future<void> loadInitial() async {
    _currentPage = initialPage;
    _hasMore = true;
    _loadMoreError = null;

    setLoading();
    try {
      final response = await fetcher(_currentPage, pageSize);
      _hasMore = response.hasMore;
      setSuccess(List<T>.unmodifiable(response.items));
    } catch (e, st) {
      setError(e, st);
    }
  }

  /// Loads the next page and appends new items to the existing list.
  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore || state.isLoading) {
      return;
    }

    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await fetcher(nextPage, pageSize);

      _currentPage = nextPage;
      _hasMore = response.hasMore;

      final currentItems = List<T>.from(state.dataOrNull ?? const []);
      currentItems.addAll(response.items);
      setSuccess(List<T>.unmodifiable(currentItems));
    } catch (e) {
      _loadMoreError = e;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Refreshes the list from the first page without necessarily blanking the UI immediately.
  Future<void> refresh() async {
    try {
      final response = await fetcher(initialPage, pageSize);
      _currentPage = initialPage;
      _hasMore = response.hasMore;
      _loadMoreError = null;
      setSuccess(List<T>.unmodifiable(response.items));
    } catch (e, st) {
      setError(e, st);
    }
  }
}
