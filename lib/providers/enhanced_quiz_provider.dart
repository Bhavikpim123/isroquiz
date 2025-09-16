import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/enhanced_quiz_service.dart';
import '../services/isro_api_service.dart';
import '../services/firestore_service.dart';
import '../services/local_profile_service.dart';
import '../models/quiz.dart';
import '../models/firebase_user.dart' as firebase_models;
import 'auth_provider.dart';
import 'isro_data_provider.dart';
import 'user_stats_provider.dart';

// Enhanced quiz service provider
final enhancedQuizServiceProvider = Provider<EnhancedQuizService>((ref) {
  final apiService = ref.read(isroApiServiceProvider);
  return EnhancedQuizService(apiService);
});

// API Quiz generation state
enum ApiQuizGenerationStatus { idle, loading, success, error }

class ApiQuizGenerationState {
  final ApiQuizGenerationStatus status;
  final ApiQuiz? quiz;
  final String? error;

  ApiQuizGenerationState({
    this.status = ApiQuizGenerationStatus.idle,
    this.quiz,
    this.error,
  });

  ApiQuizGenerationState copyWith({
    ApiQuizGenerationStatus? status,
    ApiQuiz? quiz,
    String? error,
  }) {
    return ApiQuizGenerationState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      error: error ?? this.error,
    );
  }
}

// API Quiz generation notifier
class ApiQuizGenerationNotifier extends StateNotifier<ApiQuizGenerationState> {
  ApiQuizGenerationNotifier(this.ref) : super(ApiQuizGenerationState());

  final Ref ref;

  Future<void> generateQuiz({
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
    int questionCount = 10,
  }) async {
    state = state.copyWith(status: ApiQuizGenerationStatus.loading);

    try {
      final quizService = ref.read(enhancedQuizServiceProvider);

      // Try API first, fallback to sample quiz automatically
      final quiz = await quizService.generateQuizFromAPI(
        questionCount: questionCount,
        difficulty: difficulty,
      );

      state = state.copyWith(
        status: ApiQuizGenerationStatus.success,
        quiz: quiz,
        error: null,
      );
    } catch (e) {
      // If API fails completely, try generating sample quiz directly
      try {
        final quizService = ref.read(enhancedQuizServiceProvider);
        final sampleQuiz = quizService.generateSampleQuizDirect(
          questionCount: questionCount,
          difficulty: difficulty,
        );

        state = state.copyWith(
          status: ApiQuizGenerationStatus.success,
          quiz: sampleQuiz,
          error: null,
        );
      } catch (sampleError) {
        state = state.copyWith(
          status: ApiQuizGenerationStatus.error,
          error: 'Failed to generate quiz: Unable to create sample questions',
        );
      }
    }
  }

  // Generate sample quiz directly when needed
  void generateSampleQuiz({
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
    int questionCount = 10,
  }) {
    state = state.copyWith(status: ApiQuizGenerationStatus.loading);

    try {
      final quizService = ref.read(enhancedQuizServiceProvider);
      final sampleQuiz = quizService.generateSampleQuizDirect(
        questionCount: questionCount,
        difficulty: difficulty,
      );

      state = state.copyWith(
        status: ApiQuizGenerationStatus.success,
        quiz: sampleQuiz,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: ApiQuizGenerationStatus.error,
        error: 'Failed to generate sample quiz: $e',
      );
    }
  }

  void clearQuiz() {
    state = ApiQuizGenerationState();
  }
}

// API Quiz generation provider
final apiQuizGenerationProvider =
    StateNotifierProvider<ApiQuizGenerationNotifier, ApiQuizGenerationState>((
      ref,
    ) {
      return ApiQuizGenerationNotifier(ref);
    });

// API Quiz session state
class ApiQuizSessionState {
  final ApiQuiz? quiz;
  final Map<String, List<String>> userAnswers;
  final int currentQuestionIndex;
  final DateTime? startTime;
  final Duration? timeRemaining;
  final bool isCompleted;
  final List<EvaluationResult> evaluations;

  ApiQuizSessionState({
    this.quiz,
    this.userAnswers = const {},
    this.currentQuestionIndex = 0,
    this.startTime,
    this.timeRemaining,
    this.isCompleted = false,
    this.evaluations = const [],
  });

  ApiQuizSessionState copyWith({
    ApiQuiz? quiz,
    Map<String, List<String>>? userAnswers,
    int? currentQuestionIndex,
    DateTime? startTime,
    Duration? timeRemaining,
    bool? isCompleted,
    List<EvaluationResult>? evaluations,
  }) {
    return ApiQuizSessionState(
      quiz: quiz ?? this.quiz,
      userAnswers: userAnswers ?? this.userAnswers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      startTime: startTime ?? this.startTime,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isCompleted: isCompleted ?? this.isCompleted,
      evaluations: evaluations ?? this.evaluations,
    );
  }
}

// API Quiz session notifier
class ApiQuizSessionNotifier extends StateNotifier<ApiQuizSessionState> {
  ApiQuizSessionNotifier(this.ref) : super(ApiQuizSessionState());

  final Ref ref;

  void startQuiz(ApiQuiz quiz) {
    // Clear any existing state before starting new quiz
    state = ApiQuizSessionState(
      quiz: quiz,
      startTime: DateTime.now(),
      timeRemaining: quiz.timeLimit,
      userAnswers: {},
      currentQuestionIndex: 0,
      isCompleted: false,
      evaluations: [],
    );
  }

  void answerQuestion(String questionId, List<String> selectedAnswers) {
    final updatedAnswers = Map<String, List<String>>.from(state.userAnswers);
    updatedAnswers[questionId] = selectedAnswers;

    state = state.copyWith(userAnswers: updatedAnswers);
  }

  void nextQuestion() {
    if (state.quiz != null &&
        state.currentQuestionIndex < state.quiz!.questions.length - 1) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
      );
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex - 1,
      );
    }
  }

  void goToQuestion(int index) {
    if (state.quiz != null &&
        index >= 0 &&
        index < state.quiz!.questions.length) {
      state = state.copyWith(currentQuestionIndex: index);
    }
  }

  // Complete quiz with API evaluation
  Future<ApiQuizResult?> completeQuiz() async {
    if (state.quiz == null || state.startTime == null) return null;

    state = state.copyWith(isCompleted: true);

    final user = ref.read(currentUserProvider);
    final appUser = ref.read(currentAppUserProvider);
    if (user == null || appUser == null) return null;

    try {
      final quizService = ref.read(enhancedQuizServiceProvider);
      final result = await quizService.calculateResult(
        userId: user.id,
        quiz: state.quiz!,
        userAnswers: state.userAnswers,
        startTime: state.startTime!,
        endTime: DateTime.now(),
      );

      // Convert to Firestore model and save
      final quizResult = firebase_models.QuizResult(
        id: result.id,
        userId: appUser.id,
        quizId: result.quiz.id,
        quizTitle: result.quiz.title,
        answers: state.quiz!.questions.asMap().entries.map((entry) {
          final index = entry.key;
          final question = entry.value;
          final evaluation = index < result.evaluations.length
              ? result.evaluations[index]
              : null;

          return firebase_models.QuizAnswer(
            questionId: question.id,
            question: question.question,
            selectedAnswers: state.userAnswers[question.id] ?? [],
            correctAnswers: evaluation != null
                ? [evaluation.correctAnswer]
                : [],
            isCorrect: evaluation?.isCorrect ?? false,
            questionType: question.questionType,
          );
        }).toList(),
        score: result.score,
        totalQuestions: result.totalQuestions,
        percentage: result.percentage,
        timeTaken: result.timeTaken,
        completedAt: result.completedAt,
        category: result.category,
        difficulty: result.quiz.difficulty.toString().split('.').last,
      );

      // Save to Firestore through user stats provider
      try {
        await ref.read(userStatsProvider.notifier).saveQuizResult(quizResult);
      } catch (e) {
        print('Failed to save to Firestore: $e');
      }

      // Always save to local storage as backup
      try {
        final localProfileService = LocalProfileService();
        await localProfileService.saveQuizResult(result);
      } catch (e) {
        print('Failed to save to local storage: $e');
      }

      // Add result to local quiz history
      ref.read(apiQuizResultsProvider.notifier).addResult(result);

      return result;
    } catch (e) {
      // Handle evaluation error
      print('Error completing quiz: $e');
      return null;
    }
  }

  void updateTimeRemaining(Duration timeRemaining) {
    state = state.copyWith(timeRemaining: timeRemaining);
  }

  void clearSession() {
    state = ApiQuizSessionState();
  }
}

// API Quiz session provider
final apiQuizSessionProvider =
    StateNotifierProvider<ApiQuizSessionNotifier, ApiQuizSessionState>((ref) {
      return ApiQuizSessionNotifier(ref);
    });

// API Quiz results notifier
class ApiQuizResultsNotifier extends StateNotifier<List<ApiQuizResult>> {
  ApiQuizResultsNotifier() : super([]);

  void addResult(ApiQuizResult result) {
    state = [result, ...state];
  }

  void clearResults() {
    state = [];
  }

  List<ApiQuizResult> getResultsByCategory(String category) {
    return state.where((result) => result.category == category).toList();
  }

  ApiQuizResult? getLatestResult() {
    return state.isEmpty ? null : state.first;
  }

  double getAverageScore() {
    if (state.isEmpty) return 0.0;
    final totalScore = state.fold<int>(0, (sum, result) => sum + result.score);
    final totalQuestions = state.fold<int>(
      0,
      (sum, result) => sum + result.totalQuestions,
    );
    return totalQuestions > 0 ? (totalScore / totalQuestions) * 100 : 0.0;
  }
}

// API Quiz results provider
final apiQuizResultsProvider =
    StateNotifierProvider<ApiQuizResultsNotifier, List<ApiQuizResult>>((ref) {
      return ApiQuizResultsNotifier();
    });

// Enhanced user statistics provider
final enhancedUserStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final results = ref.watch(apiQuizResultsProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return {
      'totalQuizzes': 0,
      'averageScore': 0.0,
      'totalCorrectAnswers': 0,
      'totalQuestions': 0,
      'bestScore': 0,
      'worstScore': 0,
      'apiEvaluationAccuracy': 0.0,
    };
  }

  final totalQuizzes = results.length;
  final totalQuestions = results.fold<int>(
    0,
    (sum, result) => sum + result.totalQuestions,
  );
  final totalCorrectAnswers = results.fold<int>(
    0,
    (sum, result) => sum + result.score,
  );
  final averageScore = totalQuestions > 0
      ? (totalCorrectAnswers / totalQuestions) * 100
      : 0.0;

  final scores = results.map((r) => r.percentage).toList();
  final bestScore = scores.isEmpty
      ? 0.0
      : scores.reduce((a, b) => a > b ? a : b);
  final worstScore = scores.isEmpty
      ? 0.0
      : scores.reduce((a, b) => a < b ? a : b);

  // Calculate API evaluation accuracy (how many questions were successfully evaluated)
  final totalEvaluations = results.fold<int>(
    0,
    (sum, result) => sum + result.evaluations.length,
  );
  final apiEvaluationAccuracy = totalQuestions > 0
      ? (totalEvaluations / totalQuestions) * 100
      : 0.0;

  return {
    'totalQuizzes': totalQuizzes,
    'averageScore': averageScore,
    'totalCorrectAnswers': totalCorrectAnswers,
    'totalQuestions': totalQuestions,
    'bestScore': bestScore,
    'worstScore': worstScore,
    'apiEvaluationAccuracy': apiEvaluationAccuracy,
  };
});

// Question evaluation provider for real-time feedback
final questionEvaluationProvider =
    FutureProvider.family<EvaluationResult, Map<String, dynamic>>((
      ref,
      params,
    ) async {
      final quizService = ref.read(enhancedQuizServiceProvider);
      final question = params['question'] as ApiQuizQuestion;
      final userAnswers = params['userAnswers'] as List<String>;

      return await quizService.evaluateAnswer(
        question: question,
        userAnswers: userAnswers,
      );
    });

// Quiz performance analytics provider
final quizPerformanceProvider = Provider<Map<String, dynamic>>((ref) {
  final results = ref.watch(apiQuizResultsProvider);

  if (results.isEmpty) {
    return {
      'totalAttempts': 0,
      'categoryPerformance': <String, double>{},
      'difficultyPerformance': <String, double>{},
      'improvementTrend': <double>[],
      'averageTimePerQuestion': 0.0,
    };
  }

  // Category performance analysis
  final categoryPerformance = <String, double>{};
  final categoryGroups = <String, List<ApiQuizResult>>{};

  for (final result in results) {
    final category = result.category;
    if (!categoryGroups.containsKey(category)) {
      categoryGroups[category] = [];
    }
    categoryGroups[category]!.add(result);
  }

  categoryGroups.forEach((category, categoryResults) {
    final avgScore =
        categoryResults.fold<double>(
          0,
          (sum, result) => sum + result.percentage,
        ) /
        categoryResults.length;
    categoryPerformance[category] = avgScore;
  });

  // Improvement trend (last 10 quiz scores)
  final recentScores = results
      .take(10)
      .map((r) => r.percentage)
      .toList()
      .reversed
      .toList();

  // Average time per question
  final totalTime = results.fold<Duration>(
    Duration.zero,
    (sum, result) => sum + result.timeTaken,
  );
  final totalQuestions = results.fold<int>(
    0,
    (sum, result) => sum + result.totalQuestions,
  );
  final averageTimePerQuestion = totalQuestions > 0
      ? totalTime.inSeconds / totalQuestions
      : 0.0;

  return {
    'totalAttempts': results.length,
    'categoryPerformance': categoryPerformance,
    'improvementTrend': recentScores,
    'averageTimePerQuestion': averageTimePerQuestion,
  };
});
