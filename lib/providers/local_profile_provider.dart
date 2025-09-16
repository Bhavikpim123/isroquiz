import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_profile_service.dart';
import '../services/enhanced_quiz_service.dart';
import '../models/firebase_user.dart';
import 'auth_provider.dart';

// Local profile service provider
final localProfileServiceProvider = Provider<LocalProfileService>((ref) {
  return LocalProfileService();
});

// Local profile state
class LocalProfileState {
  final AppUser? profile;
  final List<Map<String, dynamic>> quizResults;
  final Map<String, dynamic> stats;
  final bool isLoading;
  final String? error;

  LocalProfileState({
    this.profile,
    this.quizResults = const [],
    this.stats = const {},
    this.isLoading = false,
    this.error,
  });

  LocalProfileState copyWith({
    AppUser? profile,
    List<Map<String, dynamic>>? quizResults,
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
  }) {
    return LocalProfileState(
      profile: profile ?? this.profile,
      quizResults: quizResults ?? this.quizResults,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Local profile notifier
class LocalProfileNotifier extends StateNotifier<LocalProfileState> {
  LocalProfileNotifier(this.ref) : super(LocalProfileState());

  final Ref ref;

  // Initialize and load profile data
  Future<void> initializeProfile() async {
    state = state.copyWith(isLoading: true);

    try {
      final localService = ref.read(localProfileServiceProvider);

      // Check if session is active
      final isSessionActive = await localService.isSessionActive();
      if (!isSessionActive) {
        state = LocalProfileState(); // Clear state if no active session
        return;
      }

      // Load profile
      final profile = await localService.loadProfile();
      if (profile != null) {
        // Load quiz results and stats
        final quizResults = await localService.getRecentResults(profile.id);
        final stats = await localService.calculateLocalStats(profile.id);

        state = state.copyWith(
          profile: profile,
          quizResults: quizResults,
          stats: stats,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize profile: $e',
      );
    }
  }

  // Save user profile (on login)
  Future<void> saveProfile(AppUser user) async {
    try {
      final localService = ref.read(localProfileServiceProvider);
      await localService.saveProfile(user);

      // Update state
      state = state.copyWith(profile: user);

      // Load existing data
      await _loadUserData(user.id);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save profile: $e');
    }
  }

  // Save quiz result (after completing a test)
  Future<void> saveQuizResult(ApiQuizResult result) async {
    if (state.profile == null) return;

    try {
      final localService = ref.read(localProfileServiceProvider);
      await localService.saveQuizResult(result);

      // Refresh data
      await _loadUserData(state.profile!.id);
    } catch (e) {
      state = state.copyWith(error: 'Failed to save quiz result: $e');
    }
  }

  // Update profile information
  Future<void> updateProfile(AppUser updatedUser) async {
    try {
      final localService = ref.read(localProfileServiceProvider);
      await localService.updateProfile(updatedUser);

      state = state.copyWith(profile: updatedUser);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update profile: $e');
    }
  }

  // Clear all local data (on logout)
  Future<void> clearProfile() async {
    try {
      final localService = ref.read(localProfileServiceProvider);
      await localService.clearLocalData();

      // Reset state
      state = LocalProfileState();
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear profile: $e');
    }
  }

  // Load user data (quiz results and stats)
  Future<void> _loadUserData(String userId) async {
    try {
      final localService = ref.read(localProfileServiceProvider);

      final quizResults = await localService.getRecentResults(userId);
      final stats = await localService.calculateLocalStats(userId);

      state = state.copyWith(quizResults: quizResults, stats: stats);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load user data: $e');
    }
  }

  // Refresh all data
  Future<void> refreshData() async {
    if (state.profile != null) {
      await _loadUserData(state.profile!.id);
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Local profile provider
final localProfileProvider =
    StateNotifierProvider<LocalProfileNotifier, LocalProfileState>((ref) {
      final notifier = LocalProfileNotifier(ref);

      // Listen to auth changes and sync with local profile
      ref.listen(authProvider, (previous, next) {
        if (next.status == AuthStatus.authenticated && next.appUser != null) {
          // Save profile when user logs in
          notifier.saveProfile(next.appUser!);
        } else if (next.status == AuthStatus.unauthenticated &&
            previous?.status == AuthStatus.authenticated) {
          // Clear profile when user logs out
          notifier.clearProfile();
        }
      });

      // Initialize on provider creation
      notifier.initializeProfile();

      return notifier;
    });

// Convenience providers for accessing specific data
final localProfileUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(localProfileProvider).profile;
});

final localQuizResultsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(localProfileProvider).quizResults;
});

final localUserStatsProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.watch(localProfileProvider).stats;
});

// Check if profile has local data
final hasLocalProfileDataProvider = Provider<bool>((ref) {
  final profile = ref.watch(localProfileProvider);
  return profile.profile != null && profile.quizResults.isNotEmpty;
});
