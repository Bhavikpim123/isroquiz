import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firebase_user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  static const String usersCollection = 'users';
  static const String quizResultsCollection = 'quiz_results';

  // User operations
  Future<void> createUser(AppUser user) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(user.id)
          .set(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  Future<AppUser?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .get();

      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<void> updateUser(AppUser user) async {
    try {
      await _firestore
          .collection(usersCollection)
          .doc(user.id)
          .update(user.toFirestore());
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection(usersCollection).doc(userId).update({
        'lastLoginAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update last login: $e');
    }
  }

  Stream<AppUser?> getUserStream(String userId) {
    return _firestore
        .collection(usersCollection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }

  // Quiz result operations
  Future<String> saveQuizResult(QuizResult quizResult) async {
    try {
      final docRef = await _firestore
          .collection(quizResultsCollection)
          .add(quizResult.toFirestore());

      // Update user statistics
      await _updateUserStats(quizResult);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save quiz result: $e');
    }
  }

  Future<List<QuizResult>> getUserQuizResults(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final query = await _firestore
          .collection(quizResultsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('completedAt', descending: true)
          .limit(limit)
          .get();

      return query.docs.map((doc) => QuizResult.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Failed to get user quiz results: $e');
    }
  }

  Stream<List<QuizResult>> getUserQuizResultsStream(
    String userId, {
    int limit = 20,
  }) {
    return _firestore
        .collection(quizResultsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (query) =>
              query.docs.map((doc) => QuizResult.fromFirestore(doc)).toList(),
        );
  }

  Future<QuizResult?> getQuizResult(String resultId) async {
    try {
      final doc = await _firestore
          .collection(quizResultsCollection)
          .doc(resultId)
          .get();

      if (doc.exists) {
        return QuizResult.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get quiz result: $e');
    }
  }

  // User statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final user = await getUser(userId);
      if (user == null) return {};

      final quizResults = await getUserQuizResults(userId, limit: 1000);

      // Calculate additional stats
      final categoryStats = <String, Map<String, dynamic>>{};
      final recentScores = <double>[];

      for (final result in quizResults) {
        // Category statistics
        if (!categoryStats.containsKey(result.category)) {
          categoryStats[result.category] = {
            'count': 0,
            'totalScore': 0,
            'bestScore': 0.0,
          };
        }

        categoryStats[result.category]!['count']++;
        categoryStats[result.category]!['totalScore'] += result.score;
        categoryStats[result.category]!['bestScore'] =
            (categoryStats[result.category]!['bestScore'] as double).compareTo(
                  result.percentage,
                ) <
                0
            ? result.percentage
            : categoryStats[result.category]!['bestScore'];

        // Recent scores (last 10)
        if (recentScores.length < 10) {
          recentScores.add(result.percentage);
        }
      }

      return {
        'totalQuizzes': user.totalQuizzesTaken,
        'totalCorrectAnswers': user.totalCorrectAnswers,
        'totalQuestions': user.totalQuestions,
        'averageScore': user.averageScore,
        'categoryStats': categoryStats,
        'recentScores': recentScores,
        'bestScore': quizResults.isEmpty
            ? 0.0
            : quizResults
                  .map((r) => r.percentage)
                  .reduce((a, b) => a > b ? a : b),
        'streakCount': _calculateStreak(quizResults),
      };
    } catch (e) {
      throw Exception('Failed to get user stats: $e');
    }
  }

  // Private helper methods
  Future<void> _updateUserStats(QuizResult quizResult) async {
    try {
      final userRef = _firestore
          .collection(usersCollection)
          .doc(quizResult.userId);

      await _firestore.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);

        if (userDoc.exists) {
          final currentData = userDoc.data()!;
          final currentTotalQuizzes = currentData['totalQuizzesTaken'] ?? 0;
          final currentTotalCorrect = currentData['totalCorrectAnswers'] ?? 0;
          final currentTotalQuestions = currentData['totalQuestions'] ?? 0;

          final newTotalQuizzes = currentTotalQuizzes + 1;
          final newTotalCorrect = currentTotalCorrect + quizResult.score;
          final newTotalQuestions =
              currentTotalQuestions + quizResult.totalQuestions;
          final newAverageScore = newTotalQuestions > 0
              ? (newTotalCorrect / newTotalQuestions) * 100
              : 0.0;

          transaction.update(userRef, {
            'totalQuizzesTaken': newTotalQuizzes,
            'totalCorrectAnswers': newTotalCorrect,
            'totalQuestions': newTotalQuestions,
            'averageScore': newAverageScore,
            'lastLoginAt': Timestamp.now(),
          });
        }
      });
    } catch (e) {
      throw Exception('Failed to update user stats: $e');
    }
  }

  int _calculateStreak(List<QuizResult> results) {
    if (results.isEmpty) return 0;

    int streak = 0;
    for (final result in results) {
      if (result.percentage >= 70.0) {
        // Consider 70% as passing
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // Delete user data (GDPR compliance)
  Future<void> deleteUserData(String userId) async {
    try {
      final batch = _firestore.batch();

      // Delete user document
      batch.delete(_firestore.collection(usersCollection).doc(userId));

      // Delete quiz results
      final quizResults = await _firestore
          .collection(quizResultsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      for (final doc in quizResults.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }

  // Backup user data
  Future<Map<String, dynamic>> exportUserData(String userId) async {
    try {
      final user = await getUser(userId);
      final quizResults = await getUserQuizResults(userId, limit: 1000);

      return {
        'user': user?.toFirestore(),
        'quizResults': quizResults.map((r) => r.toFirestore()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to export user data: $e');
    }
  }
}
