import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/isro_data.dart';
import '../services/isro_api_service.dart';

// ISRO API service provider
final isroApiServiceProvider = Provider<IsroApiService>((ref) {
  return IsroApiService();
});

// Spacecrafts provider
final spacecraftsProvider = FutureProvider<List<Spacecraft>>((ref) async {
  final apiService = ref.read(isroApiServiceProvider);
  return await apiService.getSpacecrafts();
});

// Launchers provider
final launchersProvider = FutureProvider<List<Launcher>>((ref) async {
  final apiService = ref.read(isroApiServiceProvider);
  return await apiService.getLaunchers();
});

// Customer satellites provider
final customerSatellitesProvider = FutureProvider<List<Satellite>>((ref) async {
  final apiService = ref.read(isroApiServiceProvider);
  return await apiService.getCustomerSatellites();
});

// Centres provider
final centresProvider = FutureProvider<List<Centre>>((ref) async {
  final apiService = ref.read(isroApiServiceProvider);
  return await apiService.getCentres();
});

// All ISRO data provider
final allIsroDataProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final apiService = ref.read(isroApiServiceProvider);
  return await apiService.getAllIsroData();
});

// Search state class
class SearchState {
  final String query;
  final bool isLoading;
  final List<dynamic> results;
  final String? error;

  SearchState({
    this.query = '',
    this.isLoading = false,
    this.results = const [],
    this.error,
  });

  SearchState copyWith({
    String? query,
    bool? isLoading,
    List<dynamic>? results,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      error: error ?? this.error,
    );
  }
}

// Search notifier
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this.ref) : super(SearchState());

  final Ref ref;

  // Search across all ISRO data
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = state.copyWith(query: '', results: [], error: null);
      return;
    }

    state = state.copyWith(query: query, isLoading: true, error: null);

    try {
      final apiService = ref.read(isroApiServiceProvider);

      // Search in parallel
      final futures = await Future.wait([
        apiService.searchSpacecrafts(query),
        apiService.searchLaunchers(query),
        apiService.searchSatellites(query),
        apiService.searchCentres(query),
      ]);

      final List<dynamic> allResults = [
        ...futures[0], // spacecrafts
        ...futures[1], // launchers
        ...futures[2], // satellites
        ...futures[3], // centres
      ];

      state = state.copyWith(
        isLoading: false,
        results: allResults,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Clear search
  void clearSearch() {
    state = SearchState();
  }
}

// Search provider
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  return SearchNotifier(ref);
});

// Paginated data state
class PaginatedState<T> {
  final List<T> items;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  PaginatedState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error ?? this.error,
    );
  }
}

// Paginated spacecrafts notifier
class PaginatedSpacecraftsNotifier
    extends StateNotifier<PaginatedState<Spacecraft>> {
  PaginatedSpacecraftsNotifier(this.ref) : super(PaginatedState<Spacecraft>());

  final Ref ref;
  static const int pageSize = 10;

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final apiService = ref.read(isroApiServiceProvider);
      final newItems = await apiService.getPaginatedData<Spacecraft>(
        () => apiService.getSpacecrafts(),
        state.currentPage,
        pageSize,
      );

      final allItems = [...state.items, ...newItems];
      final hasMore = newItems.length == pageSize;

      state = state.copyWith(
        items: allItems,
        isLoading: false,
        hasMore: hasMore,
        currentPage: state.currentPage + 1,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void refresh() {
    state = PaginatedState<Spacecraft>();
    loadMore();
  }
}

// Paginated spacecrafts provider
final paginatedSpacecraftsProvider =
    StateNotifierProvider<
      PaginatedSpacecraftsNotifier,
      PaginatedState<Spacecraft>
    >((ref) {
      return PaginatedSpacecraftsNotifier(ref);
    });

// Similar providers for other data types can be added as needed
// For simplicity, we'll use the basic providers for now
