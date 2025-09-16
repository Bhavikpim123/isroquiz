import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/quiz.dart';
import '../providers/quiz_provider.dart';
import 'quiz_result_screen.dart';

class QuizTakingScreen extends ConsumerStatefulWidget {
  final Quiz quiz;

  const QuizTakingScreen({super.key, required this.quiz});

  @override
  ConsumerState<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends ConsumerState<QuizTakingScreen> {
  Timer? _timer;
  Duration _timeRemaining = Duration.zero;
  bool _isQuizCompleted = false;

  @override
  void initState() {
    super.initState();
    ref.read(quizSessionProvider.notifier).startQuiz(widget.quiz);

    if (widget.quiz.isTimeLimited) {
      _timeRemaining = widget.quiz.timeLimit;
      _startTimer();
    }
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
            .read(quizSessionProvider.notifier)
            .updateTimeRemaining(_timeRemaining);
      }
    });
  }

  void _completeQuiz() {
    if (_isQuizCompleted) return;

    setState(() {
      _isQuizCompleted = true;
    });

    _timer?.cancel();

    final result = ref.read(quizSessionProvider.notifier).completeQuiz();
    if (result != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(result: result),
        ),
      );
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Quiz'),
        content: const Text(
          'Are you sure you want to submit your quiz? You cannot change your answers after submission.',
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
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quizSession = ref.watch(quizSessionProvider);

    if (quizSession.quiz == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion =
        quizSession.quiz!.questions[quizSession.currentQuestionIndex];
    final totalQuestions = quizSession.quiz!.questions.length;
    final currentIndex = quizSession.currentQuestionIndex + 1;

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
            if (widget.quiz.isTimeLimited)
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
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
                    // Question Number and Category
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
                            currentQuestion.type == QuestionType.singleChoice
                                ? 'Single Choice'
                                : 'Multiple Choice',
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

                    if (currentQuestion.type ==
                        QuestionType.multipleChoice) ...[
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
                              Icons.info_outline,
                              color: theme.colorScheme.tertiary,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Select all correct answers',
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
                    ],

                    const SizedBox(height: 32),

                    // Answer Options
                    ...currentQuestion.options.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final isSelected =
                          quizSession.userAnswers[currentQuestion.id]?.contains(
                            index,
                          ) ??
                          false;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AnswerOption(
                          index: index,
                          option: option,
                          isSelected: isSelected,
                          questionType: currentQuestion.type,
                          onTap: () => _selectAnswer(currentQuestion.id, index),
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
                              .read(quizSessionProvider.notifier)
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
                          ref.read(quizSessionProvider.notifier).nextQuestion();
                        } else {
                          _showConfirmDialog();
                        }
                      },
                      child: Text(
                        quizSession.currentQuestionIndex < totalQuestions - 1
                            ? 'Next'
                            : 'Submit Quiz',
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

  void _selectAnswer(String questionId, int answerIndex) {
    final quizSession = ref.read(quizSessionProvider);
    final question = quizSession.quiz!.questions.firstWhere(
      (q) => q.id == questionId,
    );

    List<int> currentAnswers = List.from(
      quizSession.userAnswers[questionId] ?? [],
    );

    if (question.type == QuestionType.singleChoice) {
      // Single choice - replace previous selection
      currentAnswers = [answerIndex];
    } else {
      // Multiple choice - toggle selection
      if (currentAnswers.contains(answerIndex)) {
        currentAnswers.remove(answerIndex);
      } else {
        currentAnswers.add(answerIndex);
      }
    }

    ref
        .read(quizSessionProvider.notifier)
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
              ref.read(quizSessionProvider.notifier).clearSession();
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
  final QuestionType questionType;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.index,
    required this.option,
    required this.isSelected,
    required this.questionType,
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
                child: questionType == QuestionType.singleChoice
                    ? Text(
                        optionLabels[index],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[600],
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Icon(
                        isSelected ? Icons.check : null,
                        color: Colors.white,
                        size: 16,
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
