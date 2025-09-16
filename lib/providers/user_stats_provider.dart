import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/firebase_user.dart';
import '../services/firestore_service.dart';
import 'auth_provider.dart';

// User stats state
class UserStatsState {
  final Map<String, dynamic> stats;
  final List<QuizResult> recentResults;
  final bool isLoading;
  final String? error;

  UserStatsState({
    this.stats = const {},
    this.recentResults = const [],
    this.isLoading = false,
    this.error,
  });

  UserStatsState copyWith({
    Map<String, dynamic>? stats,
    List<QuizResult>? recentResults,
    bool? isLoading,
    String? error,
  }) {
    return UserStatsState(
      stats: stats ?? this.stats,
      recentResults: recentResults ?? this.recentResults,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// User stats notifier
class UserStatsNotifier extends StateNotifier<UserStatsState> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  UserStatsNotifier(this._firestoreService, this._ref)
    : super(UserStatsState());

  // Load user statistics
  Future<void> loadUserStats() async {
    final appUser = _ref.read(currentAppUserProvider);
    if (appUser == null) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final stats = await _firestoreService.getUserStats(appUser.id);
      final recentResults = await _firestoreService.getUserQuizResults(
        appUser.id,
        limit: 10,
      );

      state = state.copyWith(
        stats: stats,
        recentResults: recentResults,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Save quiz result
  Future<void> saveQuizResult(QuizResult quizResult) async {
    try {
      await _firestoreService.saveQuizResult(quizResult);
      // Reload stats after saving
      await loadUserStats();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Get user's best score in a category
  double getBestScoreInCategory(String category) {
    final categoryStats = state.stats['categoryStats'] as Map<String, dynamic>?;
    if (categoryStats == null || !categoryStats.containsKey(category)) {
      return 0.0;
    }
    return (categoryStats[category]['bestScore'] as num?)?.toDouble() ?? 0.0;
  }

  // Get user's total quizzes in a category
  int getTotalQuizzesInCategory(String category) {
    final categoryStats = state.stats['categoryStats'] as Map<String, dynamic>?;
    if (categoryStats == null || !categoryStats.containsKey(category)) {
      return 0;
    }
    return (categoryStats[category]['count'] as int?) ?? 0;
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Providers
final userStatsProvider =
    StateNotifierProvider<UserStatsNotifier, UserStatsState>((ref) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return UserStatsNotifier(firestoreService, ref);
    });

// Derived providers
final userTotalQuizzesProvider = Provider<int>((ref) {
  return ref.watch(userStatsProvider).stats['totalQuizzes'] as int? ?? 0;
});

final userAverageScoreProvider = Provider<double>((ref) {
  return ref.watch(userStatsProvider).stats['averageScore'] as double? ?? 0.0;
});

final userBestScoreProvider = Provider<double>((ref) {
  return ref.watch(userStatsProvider).stats['bestScore'] as double? ?? 0.0;
});

final userStreakProvider = Provider<int>((ref) {
  return ref.watch(userStatsProvider).stats['streakCount'] as int? ?? 0;
});

final recentQuizResultsProvider = Provider<List<QuizResult>>((ref) {
  return ref.watch(userStatsProvider).recentResults;
});

// Category-specific providers
final categoryStatsProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(userStatsProvider).stats['categoryStats']
          as Map<String, dynamic>? ??
      {};
});

// Quiz results stream provider
final quizResultsStreamProvider =
    StreamProvider.family<List<QuizResult>, String?>((ref, userId) {
      if (userId == null) return Stream.value([]);

      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.getUserQuizResultsStream(userId);
    });
