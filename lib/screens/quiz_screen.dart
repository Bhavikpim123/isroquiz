import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz.dart';
import '../providers/enhanced_quiz_provider.dart';
import '../services/enhanced_quiz_service.dart';
import '../widgets/shimmer_loading.dart';
import 'enhanced_quiz_taking_screen.dart';
import 'enhanced_quiz_result_screen.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  QuestionDifficulty _selectedDifficulty = QuestionDifficulty.medium;
  int _questionCount = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final quizGenerationState = ref.watch(apiQuizGenerationProvider);
    final quizResults = ref.watch(apiQuizResultsProvider);
    final userStats = ref.watch(enhancedUserStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ISRO Quiz')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.quiz, color: Colors.white, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Test Your Knowledge',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Challenge yourself with ISRO questions',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.quiz,
                        label: 'Quizzes',
                        value: '${userStats['totalQuizzes']}',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.emoji_events,
                        label: 'Best Score',
                        value: '${userStats['bestScore'].toStringAsFixed(0)}%',
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.trending_up,
                        label: 'Average',
                        value:
                            '${userStats['averageScore'].toStringAsFixed(0)}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quiz Configuration
            Text(
              'Create New Quiz',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Difficulty Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Difficulty Level',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: QuestionDifficulty.values.map((difficulty) {
                        final isSelected = _selectedDifficulty == difficulty;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                difficulty.name.toUpperCase(),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : null,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedDifficulty = difficulty;
                                  });
                                }
                              },
                              selectedColor: theme.colorScheme.primary,
                              backgroundColor: theme.colorScheme.surface,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Question Count Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Number of Questions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _questionCount.toDouble(),
                      min: 5,
                      max: 20,
                      divisions: 3,
                      label: '$_questionCount questions',
                      onChanged: (value) {
                        setState(() {
                          _questionCount = value.round();
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('5 questions', style: theme.textTheme.bodySmall),
                        Text('20 questions', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Start Quiz Buttons
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    quizGenerationState.status ==
                        ApiQuizGenerationStatus.loading
                    ? null
                    : () => _startQuiz(),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    quizGenerationState.status ==
                        ApiQuizGenerationStatus.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow),
                          const SizedBox(width: 8),
                          Text(
                            'Start Quiz (API + Fallback)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // Sample Quiz Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed:
                    quizGenerationState.status ==
                        ApiQuizGenerationStatus.loading
                    ? null
                    : () => _startSampleQuiz(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.quiz_outlined),
                    const SizedBox(width: 8),
                    Text(
                      'Start Sample Quiz',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Error Message
            if (quizGenerationState.error != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        quizGenerationState.error!,
                        style: TextStyle(color: Colors.red[700], fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            // Recent Quiz Results
            if (quizResults.isNotEmpty) ...[
              Text(
                'Recent Quiz Results',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              ...quizResults
                  .take(3)
                  .map(
                    (result) => EnhancedQuizResultCard(
                      result: result,
                      onTap: () => _showResultDetails(result),
                    ),
                  ),

              if (quizResults.length > 3) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    // Navigate to all results page
                  },
                  child: const Text('View All Results'),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _startQuiz() async {
    try {
      // Clear any previous quiz session
      ref.read(apiQuizSessionProvider.notifier).clearSession();

      // Generate new quiz
      await ref
          .read(apiQuizGenerationProvider.notifier)
          .generateQuiz(
            difficulty: _selectedDifficulty,
            questionCount: _questionCount,
          );

      final quizState = ref.read(apiQuizGenerationProvider);
      if (quizState.status == ApiQuizGenerationStatus.success &&
          quizState.quiz != null) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  EnhancedQuizTakingScreen(quiz: quizState.quiz!),
            ),
          );
        }
      } else if (quizState.status == ApiQuizGenerationStatus.error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to generate quiz: ${quizState.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startSampleQuiz() async {
    try {
      // Clear any previous quiz session
      ref.read(apiQuizSessionProvider.notifier).clearSession();

      // Generate sample quiz directly
      ref
          .read(apiQuizGenerationProvider.notifier)
          .generateSampleQuiz(
            difficulty: _selectedDifficulty,
            questionCount: _questionCount,
          );

      final quizState = ref.read(apiQuizGenerationProvider);
      if (quizState.status == ApiQuizGenerationStatus.success &&
          quizState.quiz != null) {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  EnhancedQuizTakingScreen(quiz: quizState.quiz!),
            ),
          );
        }
      } else if (quizState.status == ApiQuizGenerationStatus.error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to generate sample quiz: ${quizState.error}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting sample quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResultDetails(ApiQuizResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnhancedQuizResultScreen(result: result),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
