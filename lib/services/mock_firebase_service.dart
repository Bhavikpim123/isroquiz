// Mock Firebase service for development/testing
import '../models/firebase_user.dart';

class MockFirebaseService {
  static final MockFirebaseService _instance = MockFirebaseService._internal();
  factory MockFirebaseService() => _instance;
  MockFirebaseService._internal();

  final List<AppUser> _users = [];
  final List<QuizResult> _quizResults = [];
  final Map<String, String> _userPasswords =
      {}; // Store email -> password mapping
  AppUser? _currentUser;

  // Mock authentication with email only (for OTP flow)
  Future<bool> signInWithEmail(String email) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    // Check if user exists
    var user = _users.firstWhere(
      (u) => u.email == email,
      orElse: () => AppUser(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        displayName: email.split('@')[0],
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      ),
    );

    // Add user if new
    if (!_users.contains(user)) {
      _users.add(user);
    }

    _currentUser = user;
    return true;
  }

  // Mock authentication with email and password
  Future<bool> signInWithEmailPassword(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    // Check if user exists and password matches
    final userExists = _users.any((u) => u.email == email);
    if (!userExists) {
      throw Exception('User not found. Please sign up first.');
    }

    final storedPassword = _userPasswords[email];
    if (storedPassword == null || storedPassword != password) {
      throw Exception('Invalid password.');
    }

    // Get user and update last login
    var user = _users.firstWhere((u) => u.email == email);
    user = user.copyWith(lastLoginAt: DateTime.now());

    // Update user in list
    final userIndex = _users.indexWhere((u) => u.email == email);
    _users[userIndex] = user;

    _currentUser = user;
    return true;
  }

  // Create account with email and password
  Future<bool> createAccountWithEmailPassword(
    String email,
    String password,
  ) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    // Check if user already exists
    final userExists = _users.any((u) => u.email == email);
    if (userExists) {
      throw Exception('Account with this email already exists.');
    }

    // Create new user
    final newUser = AppUser(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      displayName: email.split('@')[0],
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    // Store user and password
    _users.add(newUser);
    _userPasswords[email] = password;

    _currentUser = newUser;
    return true;
  }

  // Check if user exists
  bool userExists(String email) {
    return _users.any((u) => u.email == email);
  }

  // Update user password
  Future<bool> updatePassword(String email, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!userExists(email)) {
      throw Exception('User not found.');
    }

    _userPasswords[email] = newPassword;
    return true;
  }

  // Get all registered users (for demo purposes)
  List<String> getRegisteredEmails() {
    return _users.map((u) => u.email).toList();
  }

  // Check stored password (for demo purposes)
  String? getStoredPassword(String email) {
    return _userPasswords[email];
  }

  // Get current user
  AppUser? get currentUser => _currentUser;

  // Save quiz result
  Future<String> saveQuizResult(QuizResult result) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _quizResults.add(result);
    return result.id;
  }

  // Get user quiz results
  Future<List<QuizResult>> getUserQuizResults(String userId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _quizResults.where((r) => r.userId == userId).toList();
  }

  // Get user stats
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final userResults = _quizResults.where((r) => r.userId == userId).toList();

    if (userResults.isEmpty) {
      return {
        'totalQuizzes': 0,
        'averageScore': 0.0,
        'totalCorrectAnswers': 0,
        'totalQuestions': 0,
        'bestScore': 0.0,
        'categoryStats': {},
        'recentScores': [],
        'streakCount': 0,
      };
    }

    final totalQuizzes = userResults.length;
    final totalCorrect = userResults.fold<int>(0, (sum, r) => sum + r.score);
    final totalQuestions = userResults.fold<int>(
      0,
      (sum, r) => sum + r.totalQuestions,
    );
    final averageScore = totalQuestions > 0
        ? (totalCorrect / totalQuestions) * 100
        : 0.0;
    final bestScore = userResults
        .map((r) => r.percentage)
        .reduce((a, b) => a > b ? a : b);

    return {
      'totalQuizzes': totalQuizzes,
      'averageScore': averageScore,
      'totalCorrectAnswers': totalCorrect,
      'totalQuestions': totalQuestions,
      'bestScore': bestScore,
      'categoryStats': {},
      'recentScores': userResults.take(10).map((r) => r.percentage).toList(),
      'streakCount': 0,
    };
  }

  // Sign out
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentUser = null;
  }

  // Check if signed in
  bool get isSignedIn => _currentUser != null;
}
