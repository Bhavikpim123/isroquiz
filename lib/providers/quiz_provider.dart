import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz.dart';
import '../models/user.dart';
import '../services/quiz_service.dart';
import 'isro_data_provider.dart';
import 'auth_provider.dart';

// Quiz service provider
final quizServiceProvider = Provider<QuizService>((ref) {
  return QuizService();
});

// Quiz generation state
enum QuizGenerationStatus { idle, loading, success, error }

class QuizGenerationState {
  final QuizGenerationStatus status;
  final Quiz? quiz;
  final String? error;

  QuizGenerationState({
    this.status = QuizGenerationStatus.idle,
    this.quiz,
    this.error,
  });

  QuizGenerationState copyWith({
    QuizGenerationStatus? status,
    Quiz? quiz,
    String? error,
  }) {
    return QuizGenerationState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      error: error ?? this.error,
    );
  }
}

// Quiz generation notifier
class QuizGenerationNotifier extends StateNotifier<QuizGenerationState> {
  QuizGenerationNotifier(this.ref) : super(QuizGenerationState());

  final Ref ref;

  Future<void> generateQuiz({
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
    int questionCount = 10,
  }) async {
    state = state.copyWith(status: QuizGenerationStatus.loading);

    try {
      final quizService = ref.read(quizServiceProvider);
      final isroData = await ref.read(allIsroDataProvider.future);

      final quiz = await quizService.generateQuiz(
        spacecrafts: isroData['spacecrafts'],
        launchers: isroData['launchers'],
        satellites: isroData['satellites'],
        centres: isroData['centres'],
        difficulty: difficulty,
        questionCount: questionCount,
      );

      state = state.copyWith(
        status: QuizGenerationStatus.success,
        quiz: quiz,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: QuizGenerationStatus.error,
        error: e.toString(),
      );
    }
  }

  void clearQuiz() {
    state = QuizGenerationState();
  }
}

// Quiz generation provider
final quizGenerationProvider =
    StateNotifierProvider<QuizGenerationNotifier, QuizGenerationState>((ref) {
      return QuizGenerationNotifier(ref);
    });

// Current quiz provider (the quiz being taken)
final currentQuizProvider = StateProvider<Quiz?>((ref) => null);

// Quiz session state
class QuizSessionState {
  final Quiz? quiz;
  final Map<String, List<int>> userAnswers;
  final int currentQuestionIndex;
  final DateTime? startTime;
  final Duration? timeRemaining;
  final bool isCompleted;

  QuizSessionState({
    this.quiz,
    this.userAnswers = const {},
    this.currentQuestionIndex = 0,
    this.startTime,
    this.timeRemaining,
    this.isCompleted = false,
  });

  QuizSessionState copyWith({
    Quiz? quiz,
    Map<String, List<int>>? userAnswers,
    int? currentQuestionIndex,
    DateTime? startTime,
    Duration? timeRemaining,
    bool? isCompleted,
  }) {
    return QuizSessionState(
      quiz: quiz ?? this.quiz,
      userAnswers: userAnswers ?? this.userAnswers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      startTime: startTime ?? this.startTime,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

// Quiz session notifier
class QuizSessionNotifier extends StateNotifier<QuizSessionState> {
  QuizSessionNotifier(this.ref) : super(QuizSessionState());

  final Ref ref;

  void startQuiz(Quiz quiz) {
    state = QuizSessionState(
      quiz: quiz,
      startTime: DateTime.now(),
      timeRemaining: quiz.isTimeLimited ? quiz.timeLimit : null,
    );
  }

  void answerQuestion(String questionId, List<int> selectedIndices) {
    final updatedAnswers = Map<String, List<int>>.from(state.userAnswers);
    updatedAnswers[questionId] = selectedIndices;

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

  QuizResult? completeQuiz() {
    if (state.quiz == null || state.startTime == null) return null;

    state = state.copyWith(isCompleted: true);

    final user = ref.read(currentUserProvider);
    if (user == null) return null;

    final quizService = ref.read(quizServiceProvider);
    final result = quizService.calculateResult(
      userId: user.id,
      questions: state.quiz!.questions,
      userAnswers: state.userAnswers,
      startTime: state.startTime!,
      endTime: DateTime.now(),
      category: state.quiz!.category,
    );

    // Add result to user's quiz history
    ref.read(quizResultsProvider.notifier).addResult(result);

    return result;
  }

  void updateTimeRemaining(Duration timeRemaining) {
    state = state.copyWith(timeRemaining: timeRemaining);
  }

  void clearSession() {
    state = QuizSessionState();
  }
}

// Quiz session provider
final quizSessionProvider =
    StateNotifierProvider<QuizSessionNotifier, QuizSessionState>((ref) {
      return QuizSessionNotifier(ref);
    });

// Quiz results notifier
class QuizResultsNotifier extends StateNotifier<List<QuizResult>> {
  QuizResultsNotifier() : super([]);

  void addResult(QuizResult result) {
    state = [result, ...state];
  }

  void clearResults() {
    state = [];
  }

  List<QuizResult> getResultsByCategory(String category) {
    return state.where((result) => result.category == category).toList();
  }

  QuizResult? getLatestResult() {
    return state.isEmpty ? null : state.first;
  }

  double getAverageScore() {
    if (state.isEmpty) return 0.0;
    final totalScore = state.fold<int>(0, (sum, result) => sum + result.score);
    final totalQuestions = state.fold<int>(
      0,
      (sum, result) => sum + result.questions.length,
    );
    return totalQuestions > 0 ? (totalScore / totalQuestions) * 100 : 0.0;
  }
}

// Quiz results provider
final quizResultsProvider =
    StateNotifierProvider<QuizResultsNotifier, List<QuizResult>>((ref) {
      return QuizResultsNotifier();
    });

// User statistics provider
final userStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final results = ref.watch(quizResultsProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return {
      'totalQuizzes': 0,
      'averageScore': 0.0,
      'totalCorrectAnswers': 0,
      'totalQuestions': 0,
      'bestScore': 0,
      'worstScore': 0,
    };
  }

  final totalQuizzes = results.length;
  final totalQuestions = results.fold<int>(
    0,
    (sum, result) => sum + result.questions.length,
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

  return {
    'totalQuizzes': totalQuizzes,
    'averageScore': averageScore,
    'totalCorrectAnswers': totalCorrectAnswers,
    'totalQuestions': totalQuestions,
    'bestScore': bestScore,
    'worstScore': worstScore,
  };
});
