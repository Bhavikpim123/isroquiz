import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final int totalQuizzesTaken;
  final int totalCorrectAnswers;
  final int totalQuestions;
  final double averageScore;
  final Map<String, dynamic> preferences;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.lastLoginAt,
    this.totalQuizzesTaken = 0,
    this.totalCorrectAnswers = 0,
    this.totalQuestions = 0,
    this.averageScore = 0.0,
    this.preferences = const {},
  });

  // Create from Firestore document
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      totalQuizzesTaken: data['totalQuizzesTaken'] ?? 0,
      totalCorrectAnswers: data['totalCorrectAnswers'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      averageScore: (data['averageScore'] ?? 0.0).toDouble(),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'totalQuizzesTaken': totalQuizzesTaken,
      'totalCorrectAnswers': totalCorrectAnswers,
      'totalQuestions': totalQuestions,
      'averageScore': averageScore,
      'preferences': preferences,
    };
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'totalQuizzesTaken': totalQuizzesTaken,
      'totalCorrectAnswers': totalCorrectAnswers,
      'totalQuestions': totalQuestions,
      'averageScore': averageScore,
      'preferences': preferences,
    };
  }

  // Create from JSON for local storage
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      photoUrl: json['photoUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
      totalQuizzesTaken: json['totalQuizzesTaken'] ?? 0,
      totalCorrectAnswers: json['totalCorrectAnswers'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      averageScore: (json['averageScore'] ?? 0.0).toDouble(),
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
    );
  }

  // Copy with updated values
  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    int? totalQuizzesTaken,
    int? totalCorrectAnswers,
    int? totalQuestions,
    double? averageScore,
    Map<String, dynamic>? preferences,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      totalQuizzesTaken: totalQuizzesTaken ?? this.totalQuizzesTaken,
      totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      averageScore: averageScore ?? this.averageScore,
      preferences: preferences ?? this.preferences,
    );
  }

  @override
  String toString() {
    return 'AppUser(id: $id, email: $email, displayName: $displayName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class QuizResult {
  final String id;
  final String userId;
  final String quizId;
  final String quizTitle;
  final List<QuizAnswer> answers;
  final int score;
  final int totalQuestions;
  final double percentage;
  final Duration timeTaken;
  final DateTime completedAt;
  final String category;
  final String difficulty;

  QuizResult({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.quizTitle,
    required this.answers,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.timeTaken,
    required this.completedAt,
    required this.category,
    required this.difficulty,
  });

  // Create from Firestore document
  factory QuizResult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QuizResult(
      id: doc.id,
      userId: data['userId'] ?? '',
      quizId: data['quizId'] ?? '',
      quizTitle: data['quizTitle'] ?? '',
      answers: (data['answers'] as List<dynamic>)
          .map((answer) => QuizAnswer.fromMap(answer))
          .toList(),
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      percentage: (data['percentage'] ?? 0.0).toDouble(),
      timeTaken: Duration(seconds: data['timeTakenSeconds'] ?? 0),
      completedAt: (data['completedAt'] as Timestamp).toDate(),
      category: data['category'] ?? '',
      difficulty: data['difficulty'] ?? '',
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'answers': answers.map((answer) => answer.toMap()).toList(),
      'score': score,
      'totalQuestions': totalQuestions,
      'percentage': percentage,
      'timeTakenSeconds': timeTaken.inSeconds,
      'completedAt': Timestamp.fromDate(completedAt),
      'category': category,
      'difficulty': difficulty,
    };
  }
}

class QuizAnswer {
  final String questionId;
  final String question;
  final List<String> selectedAnswers;
  final List<String> correctAnswers;
  final bool isCorrect;
  final String questionType; // 'single' or 'multiple'

  QuizAnswer({
    required this.questionId,
    required this.question,
    required this.selectedAnswers,
    required this.correctAnswers,
    required this.isCorrect,
    required this.questionType,
  });

  // Create from Map
  factory QuizAnswer.fromMap(Map<String, dynamic> map) {
    return QuizAnswer(
      questionId: map['questionId'] ?? '',
      question: map['question'] ?? '',
      selectedAnswers: List<String>.from(map['selectedAnswers'] ?? []),
      correctAnswers: List<String>.from(map['correctAnswers'] ?? []),
      isCorrect: map['isCorrect'] ?? false,
      questionType: map['questionType'] ?? 'single',
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'questionId': questionId,
      'question': question,
      'selectedAnswers': selectedAnswers,
      'correctAnswers': correctAnswers,
      'isCorrect': isCorrect,
      'questionType': questionType,
    };
  }
}
