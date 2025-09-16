import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/firebase_user.dart';
import '../services/enhanced_quiz_service.dart';

class LocalProfileService {
  static const String _profileKey = 'user_profile';
  static const String _quizResultsKey = 'quiz_results';
  static const String _sessionActiveKey = 'session_active';

  // Save user profile to local storage
  Future<void> saveProfile(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(user.toJson());
      await prefs.setString(_profileKey, profileJson);
      await prefs.setBool(_sessionActiveKey, true);

      if (kDebugMode) {
        print('Profile saved locally: ${user.email}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save profile locally: $e');
      }
    }
  }

  // Load user profile from local storage
  Future<AppUser?> loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isSessionActive = prefs.getBool(_sessionActiveKey) ?? false;

      if (!isSessionActive) {
        return null; // Session expired or user logged out
      }

      final profileJson = prefs.getString(_profileKey);
      if (profileJson != null) {
        final profileData = jsonDecode(profileJson) as Map<String, dynamic>;
        return AppUser.fromJson(profileData);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load profile locally: $e');
      }
    }

    return null;
  }

  // Save quiz result to local storage
  Future<void> saveQuizResult(ApiQuizResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingResults = await loadQuizResults();

      // Convert ApiQuizResult to a serializable format
      final resultData = {
        'id': result.id,
        'userId': result.userId,
        'quizTitle': result.quiz.title,
        'score': result.score,
        'totalQuestions': result.totalQuestions,
        'percentage': result.percentage,
        'completedAt': result.completedAt.toIso8601String(),
        'timeTaken': result.timeTaken.inSeconds,
        'category': result.category,
        'difficulty': result.quiz.difficulty.toString(),
        'questions': result.quiz.questions
            .map(
              (q) => {
                'id': q.id,
                'question': q.question,
                'options': q.options,
                'category': q.category,
              },
            )
            .toList(),
        'userAnswers': result.userAnswers,
        'evaluations': result.evaluations
            .map(
              (e) => {
                'isCorrect': e.isCorrect,
                'correctAnswer': e.correctAnswer,
                'explanation': e.explanation,
                'userAnswer': e.userAnswer,
              },
            )
            .toList(),
      };

      existingResults.add(resultData);

      // Keep only the latest 50 results to prevent storage bloat
      if (existingResults.length > 50) {
        existingResults.removeRange(0, existingResults.length - 50);
      }

      final resultsJson = jsonEncode(existingResults);
      await prefs.setString(_quizResultsKey, resultsJson);

      if (kDebugMode) {
        print(
          'Quiz result saved locally: ${result.score}/${result.totalQuestions}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save quiz result locally: $e');
      }
    }
  }

  // Load quiz results from local storage
  Future<List<Map<String, dynamic>>> loadQuizResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isSessionActive = prefs.getBool(_sessionActiveKey) ?? false;

      if (!isSessionActive) {
        return []; // Session expired or user logged out
      }

      final resultsJson = prefs.getString(_quizResultsKey);
      if (resultsJson != null) {
        final resultsList = jsonDecode(resultsJson) as List;
        return resultsList.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load quiz results locally: $e');
      }
    }

    return [];
  }

  // Calculate user statistics from local data
  Future<Map<String, dynamic>> calculateLocalStats(String userId) async {
    try {
      final results = await loadQuizResults();
      final userResults = results.where((r) => r['userId'] == userId).toList();

      if (userResults.isEmpty) {
        return {
          'totalQuizzes': 0,
          'averageScore': 0.0,
          'totalCorrectAnswers': 0,
          'totalQuestions': 0,
          'bestScore': 0.0,
          'recentScores': <double>[],
          'categoryStats': <String, Map<String, dynamic>>{},
        };
      }

      final totalQuizzes = userResults.length;
      final totalCorrect = userResults.fold<int>(
        0,
        (sum, r) => sum + (r['score'] as int),
      );
      final totalQuestions = userResults.fold<int>(
        0,
        (sum, r) => sum + (r['totalQuestions'] as int),
      );
      final averageScore = totalQuestions > 0
          ? (totalCorrect / totalQuestions) * 100
          : 0.0;
      final bestScore = userResults.fold<double>(
        0.0,
        (max, r) =>
            (r['percentage'] as double) > max ? r['percentage'] as double : max,
      );
      final recentScores = userResults
          .map((r) => r['percentage'] as double)
          .take(10)
          .toList();

      // Calculate category statistics
      final categoryStats = <String, Map<String, dynamic>>{};
      for (final result in userResults) {
        final category = result['category'] as String;
        if (!categoryStats.containsKey(category)) {
          categoryStats[category] = {
            'totalQuizzes': 0,
            'totalScore': 0,
            'totalQuestions': 0,
            'averageScore': 0.0,
          };
        }

        categoryStats[category]!['totalQuizzes'] =
            (categoryStats[category]!['totalQuizzes'] as int) + 1;
        categoryStats[category]!['totalScore'] =
            (categoryStats[category]!['totalScore'] as int) +
            (result['score'] as int);
        categoryStats[category]!['totalQuestions'] =
            (categoryStats[category]!['totalQuestions'] as int) +
            (result['totalQuestions'] as int);
      }

      // Calculate average scores for categories
      categoryStats.forEach((category, stats) {
        final totalQuestions = stats['totalQuestions'] as int;
        final totalScore = stats['totalScore'] as int;
        stats['averageScore'] = totalQuestions > 0
            ? (totalScore / totalQuestions) * 100
            : 0.0;
      });

      return {
        'totalQuizzes': totalQuizzes,
        'averageScore': averageScore,
        'totalCorrectAnswers': totalCorrect,
        'totalQuestions': totalQuestions,
        'bestScore': bestScore,
        'recentScores': recentScores,
        'categoryStats': categoryStats,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Failed to calculate local stats: $e');
      }
      return {
        'totalQuizzes': 0,
        'averageScore': 0.0,
        'totalCorrectAnswers': 0,
        'totalQuestions': 0,
        'bestScore': 0.0,
        'recentScores': <double>[],
        'categoryStats': <String, Map<String, dynamic>>{},
      };
    }
  }

  // Clear all local data (on logout)
  Future<void> clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_profileKey);
      await prefs.remove(_quizResultsKey);
      await prefs.setBool(_sessionActiveKey, false);

      if (kDebugMode) {
        print('Local profile data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to clear local data: $e');
      }
    }
  }

  // Check if session is active
  Future<bool> isSessionActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_sessionActiveKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Update profile data
  Future<void> updateProfile(AppUser updatedUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isSessionActive = prefs.getBool(_sessionActiveKey) ?? false;

      if (isSessionActive) {
        final profileJson = jsonEncode(updatedUser.toJson());
        await prefs.setString(_profileKey, profileJson);

        if (kDebugMode) {
          print('Profile updated locally: ${updatedUser.email}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update profile locally: $e');
      }
    }
  }

  // Get recent quiz results for display
  Future<List<Map<String, dynamic>>> getRecentResults(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final allResults = await loadQuizResults();
      final userResults = allResults
          .where((r) => r['userId'] == userId)
          .toList();

      // Sort by completion date (most recent first)
      userResults.sort((a, b) {
        final dateA = DateTime.parse(a['completedAt'] as String);
        final dateB = DateTime.parse(b['completedAt'] as String);
        return dateB.compareTo(dateA);
      });

      return userResults.take(limit).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Failed to get recent results: $e');
      }
      return [];
    }
  }
}
