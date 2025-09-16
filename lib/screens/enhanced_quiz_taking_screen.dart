import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../services/enhanced_quiz_service.dart';
import '../providers/enhanced_quiz_provider.dart';
import 'enhanced_quiz_result_screen.dart';

class EnhancedQuizTakingScreen extends ConsumerStatefulWidget {
  final ApiQuiz quiz;

  const EnhancedQuizTakingScreen({super.key, required this.quiz});

  @override
  ConsumerState<EnhancedQuizTakingScreen> createState() =>
      _EnhancedQuizTakingScreenState();
}

class _EnhancedQuizTakingScreenState
    extends ConsumerState<EnhancedQuizTakingScreen> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;
  bool _isQuizCompleted = false;

  @override
  void initState() {
    super.initState();
    // Defer the provider state update to avoid modification during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(apiQuizSessionProvider.notifier).startQuiz(widget.quiz);
    });

    _timeRemaining = widget.quiz.timeLimit;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining.inSeconds <= 0) {
        _completeQuiz();
      } else {
        setState(() {
          _timeRemaining = Duration(seconds: _timeRemaining.inSeconds - 1);
        });
        ref
            .read(apiQuizSessionProvider.notifier)
            .updateTimeRemaining(_timeRemaining);
      }
    });
  }

  void _completeQuiz() async {
    if (_isQuizCompleted) return;

    setState(() {
      _isQuizCompleted = true;
    });

    _timer?.cancel();

    // Show loading dialog during API evaluation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Evaluating answers using ISRO API...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final result = await ref
          .read(apiQuizSessionProvider.notifier)
          .completeQuiz();

      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (result != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => EnhancedQuizResultScreen(result: result),
            ),
          );
        } else {
          // Handle error case
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to evaluate quiz. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error evaluating quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Quiz'),
        content: const Text(
          'Are you sure you want to submit your quiz? Your answers will be evaluated using the ISRO API.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _completeQuiz();
            },
            child: const Text('Submit & Evaluate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quizSession = ref.watch(apiQuizSessionProvider);

    if (quizSession.quiz == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Safety check for empty questions list
    if (quizSession.quiz!.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Error')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'No questions available for this quiz.',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Please try generating a new quiz.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Ensure currentQuestionIndex is within bounds
    final validIndex = quizSession.currentQuestionIndex.clamp(
      0,
      quizSession.quiz!.questions.length - 1,
    );
    if (validIndex != quizSession.currentQuestionIndex) {
      // Fix the index if it's out of bounds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(apiQuizSessionProvider.notifier).goToQuestion(validIndex);
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion = quizSession.quiz!.questions[validIndex];
    final totalQuestions = quizSession.quiz!.questions.length;
    final currentIndex = validIndex + 1;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          _showExitDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Question $currentIndex of $totalQuestions'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _showExitDialog,
          ),
          actions: [
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _timeRemaining.inMinutes < 5
                    ? Colors.red.withOpacity(0.1)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _timeRemaining.inMinutes < 5
                      ? Colors.red
                      : Colors.white,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: _timeRemaining.inMinutes < 5
                        ? Colors.red
                        : Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_timeRemaining),
                    style: TextStyle(
                      color: _timeRemaining.inMinutes < 5
                          ? Colors.red
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: currentIndex / totalQuestions,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),

            // Question Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Details
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            currentQuestion.category,
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'API Evaluated',
                            style: TextStyle(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Question Text
                    Text(
                      currentQuestion.question,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.api,
                            color: theme.colorScheme.tertiary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Answer will be validated against ${currentQuestion.endpoint}',
                              style: TextStyle(
                                color: theme.colorScheme.tertiary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Answer Options
                    ...currentQuestion.options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final isSelected =
                          quizSession.userAnswers[currentQuestion.id]?.contains(
                            option,
                          ) ??
                          false;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AnswerOption(
                          index: index,
                          option: option,
                          isSelected: isSelected,
                          onTap: () =>
                              _selectAnswer(currentQuestion.id, option),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Navigation Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (quizSession.currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          ref
                              .read(apiQuizSessionProvider.notifier)
                              .previousQuestion();
                        },
                        child: const Text('Previous'),
                      ),
                    ),

                  if (quizSession.currentQuestionIndex > 0)
                    const SizedBox(width: 16),

                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (quizSession.currentQuestionIndex <
                            totalQuestions - 1) {
                          ref
                              .read(apiQuizSessionProvider.notifier)
                              .nextQuestion();
                        } else {
                          _showConfirmDialog();
                        }
                      },
                      child: Text(
                        quizSession.currentQuestionIndex < totalQuestions - 1
                            ? 'Next'
                            : 'Submit & Evaluate',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectAnswer(String questionId, String selectedOption) {
    final quizSession = ref.read(apiQuizSessionProvider);
    List<String> currentAnswers = List.from(
      quizSession.userAnswers[questionId] ?? [],
    );

    // For API-based quiz, we use single selection for simplicity
    currentAnswers = [selectedOption];

    ref
        .read(apiQuizSessionProvider.notifier)
        .answerQuestion(questionId, currentAnswers);
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz'),
        content: const Text(
          'Are you sure you want to exit? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(apiQuizSessionProvider.notifier).clearSession();
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

class _AnswerOption extends StatelessWidget {
  final int index;
  final String option;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.index,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final optionLabels = ['A', 'B', 'C', 'D', 'E'];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  optionLabels[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                option,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
