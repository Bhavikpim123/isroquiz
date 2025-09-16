import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz.dart';
import '../models/firebase_user.dart' as firebase_models;
import '../providers/auth_provider.dart';
import '../providers/quiz_provider.dart' hide userStatsProvider;
import '../providers/user_stats_provider.dart';
import '../providers/local_profile_provider.dart';
import '../services/local_profile_service.dart';
import 'quiz_result_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(currentUserProvider);
    final appUser = ref.watch(currentAppUserProvider);
    final userStatsState = ref.watch(userStatsProvider);
    final userStats = userStatsState.stats;
    final recentResults = userStatsState.recentResults;
    final quizResults = ref.watch(quizResultsProvider);

    // Local profile data (fallback when database is not working)
    final localProfile = ref.watch(localProfileProvider);
    final hasLocalData = ref.watch(hasLocalProfileDataProvider);

    // Load user stats when the screen builds
    ref.listen(currentAppUserProvider, (previous, next) {
      if (next != null && previous != next) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(userStatsProvider.notifier).loadUserStats();
        });
      }
    });

    // Use local data if database is not working and we have local data
    final effectiveStats = userStatsState.isLoading && hasLocalData
        ? localProfile.stats
        : userStats;
    final effectiveResults = userStatsState.isLoading && hasLocalData
        ? localProfile.quizResults
        : recentResults;
    final dataSource =
        hasLocalData &&
            (userStatsState.isLoading || userStatsState.error != null)
        ? 'Local'
        : 'Database';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (hasLocalData)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Chip(
                label: Text(dataSource, style: TextStyle(fontSize: 12)),
                backgroundColor: dataSource == 'Local'
                    ? Colors.orange[100]
                    : Colors.green[100],
              ),
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('No user data available'))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            user.name?.substring(0, 1).toUpperCase() ?? 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.name ?? 'Space Explorer',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        if (user.joinDate != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Member since ${_formatDate(user.joinDate!)}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Statistics Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quiz Statistics',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Stats Grid
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.2,
                          children: [
                            _StatCard(
                              icon: Icons.quiz,
                              title: 'Total Quizzes',
                              value: '${effectiveStats['totalQuizzes']}',
                              color: theme.colorScheme.primary,
                            ),
                            _StatCard(
                              icon: Icons.emoji_events,
                              title: 'Best Score',
                              value:
                                  '${effectiveStats['bestScore'].toStringAsFixed(0)}%',
                              color: Colors.amber,
                            ),
                            _StatCard(
                              icon: Icons.trending_up,
                              title: 'Average Score',
                              value:
                                  '${effectiveStats['averageScore'].toStringAsFixed(0)}%',
                              color: theme.colorScheme.secondary,
                            ),
                            _StatCard(
                              icon: Icons.check_circle,
                              title: 'Correct Answers',
                              value: '${effectiveStats['totalCorrectAnswers']}',
                              color: Colors.green,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Recent Activity
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Quiz Results',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (effectiveResults.isNotEmpty)
                              TextButton(
                                onPressed: () => _showAllFirebaseResults(
                                  context,
                                  appUser?.id ?? '',
                                ),
                                child: const Text('View All'),
                              ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        if (effectiveResults.isEmpty)
                          _EmptyState()
                        else if (dataSource == 'Local')
                          Column(
                            children: effectiveResults.take(5).map<Widget>((
                              result,
                            ) {
                              return _LocalQuizResultTile(
                                result: result as Map<String, dynamic>,
                                onTap: () => _showLocalResultDetails(
                                  context,
                                  result as Map<String, dynamic>,
                                ),
                              );
                            }).toList(),
                          )
                        else
                          Column(
                            children: effectiveResults.take(5).map<Widget>((
                              result,
                            ) {
                              return _FirebaseQuizResultTile(
                                result: result as firebase_models.QuizResult,
                                onTap: () => _showFirebaseResultDetails(
                                  context,
                                  result as firebase_models.QuizResult,
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showFirebaseResultDetails(
    BuildContext context,
    firebase_models.QuizResult result,
  ) {
    // TODO: Implement Firebase-specific result detail screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.quizTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${result.score}/${result.totalQuestions}'),
            Text('Percentage: ${result.percentage.toStringAsFixed(1)}%'),
            Text('Category: ${result.category}'),
            Text('Completed: ${result.completedAt}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLocalResultDetails(
    BuildContext context,
    Map<String, dynamic> result,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result['quizTitle'] ?? 'Quiz Result'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${result['score']}/${result['totalQuestions']}'),
            Text(
              'Percentage: ${(result['percentage'] as double).toStringAsFixed(1)}%',
            ),
            Text('Category: ${result['category']}'),
            Text('Completed: ${DateTime.parse(result['completedAt'])}'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storage, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Local Data',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAllFirebaseResults(BuildContext context, String userId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _AllFirebaseResultsScreen(userId: userId),
      ),
    );
  }

  void _showResultDetails(BuildContext context, QuizResult result) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => QuizResultScreen(result: result)),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizResultTile extends StatelessWidget {
  final QuizResult result;
  final VoidCallback? onTap;

  const _QuizResultTile({required this.result, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getGradeColor(result.grade).withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Center(
            child: Text(
              result.grade,
              style: TextStyle(
                color: _getGradeColor(result.grade),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          '${result.score}/${result.questions.length} Questions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${result.percentage.toStringAsFixed(1)}% • ${result.category}',
            ),
            Text(
              _formatDateTime(result.completedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.red;
      case 'F':
        return Colors.red[800]!;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Quiz Results Yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take your first quiz to see your results here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AllResultsScreen extends StatelessWidget {
  final List<QuizResult> results;

  const _AllResultsScreen({required this.results});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('All Quiz Results')),
      body: results.isEmpty
          ? _EmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final result = results[index];
                return _QuizResultTile(
                  result: result,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => QuizResultScreen(result: result),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

class _FirebaseQuizResultTile extends StatelessWidget {
  final firebase_models.QuizResult result;
  final VoidCallback? onTap;

  const _FirebaseQuizResultTile({required this.result, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final grade = _getGradeFromPercentage(result.percentage);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getGradeColor(grade),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              grade,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          '${result.score}/${result.totalQuestions} Questions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${result.percentage.toStringAsFixed(1)}% • ${result.category}',
            ),
            Text(
              _formatDateTime(result.completedAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  String _getGradeFromPercentage(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.red;
      case 'F':
        return Colors.red[800]!;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}

class _AllFirebaseResultsScreen extends ConsumerWidget {
  final String userId;

  const _AllFirebaseResultsScreen({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizResultsAsync = ref.watch(quizResultsStreamProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text('All Quiz Results')),
      body: quizResultsAsync.when(
        data: (results) => results.isEmpty
            ? _EmptyState()
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  return _FirebaseQuizResultTile(
                    result: result,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(result.quizTitle),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Score: ${result.score}/${result.totalQuestions}',
                              ),
                              Text(
                                'Percentage: ${result.percentage.toStringAsFixed(1)}%',
                              ),
                              Text('Category: ${result.category}'),
                              Text(
                                'Time Taken: ${_formatDuration(result.timeTaken)}',
                              ),
                              Text('Completed: ${result.completedAt}'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading results: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(quizResultsStreamProvider(userId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes}m ${seconds}s';
  }
}

class _LocalQuizResultTile extends StatelessWidget {
  final Map<String, dynamic> result;
  final VoidCallback? onTap;

  const _LocalQuizResultTile({required this.result, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = result['score'] as int;
    final totalQuestions = result['totalQuestions'] as int;
    final percentage = result['percentage'] as double;
    final completedAt = DateTime.parse(result['completedAt'] as String);
    final category = result['category'] as String;

    Color scoreColor;
    if (percentage >= 80) {
      scoreColor = Colors.green;
    } else if (percentage >= 60) {
      scoreColor = Colors.orange;
    } else {
      scoreColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(Icons.quiz, color: scoreColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            result['quizTitle'] as String? ?? 'Quiz',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[300]!),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.storage,
                                size: 12,
                                color: Colors.orange[700],
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Local',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '$score/$totalQuestions',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${percentage.toStringAsFixed(0)}%)',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scoreColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDateTime(completedAt),
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
