import 'package:uuid/uuid.dart';

enum QuestionType { singleChoice, multipleChoice }

enum QuestionDifficulty { easy, medium, hard }

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final List<int> correctAnswerIndices;
  final QuestionType type;
  final QuestionDifficulty difficulty;
  final String category;
  final String? explanation;

  QuizQuestion({
    String? id,
    required this.question,
    required this.options,
    required this.correctAnswerIndices,
    required this.type,
    this.difficulty = QuestionDifficulty.medium,
    this.category = 'General',
    this.explanation,
  }) : id = id ?? const Uuid().v4();

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      correctAnswerIndices: List<int>.from(json['correctAnswerIndices']),
      type: QuestionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => QuestionType.singleChoice,
      ),
      difficulty: QuestionDifficulty.values.firstWhere(
        (e) => e.toString() == json['difficulty'],
        orElse: () => QuestionDifficulty.medium,
      ),
      category: json['category'] ?? 'General',
      explanation: json['explanation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'correctAnswerIndices': correctAnswerIndices,
      'type': type.toString(),
      'difficulty': difficulty.toString(),
      'category': category,
      'explanation': explanation,
    };
  }

  bool isCorrect(List<int> selectedIndices) {
    if (selectedIndices.length != correctAnswerIndices.length) {
      return false;
    }
    for (int index in selectedIndices) {
      if (!correctAnswerIndices.contains(index)) {
        return false;
      }
    }
    return true;
  }
}

class QuizResult {
  final String id;
  final String userId;
  final List<QuizQuestion> questions;
  final Map<String, List<int>> userAnswers;
  final int score;
  final DateTime completedAt;
  final Duration timeTaken;
  final String category;

  QuizResult({
    String? id,
    required this.userId,
    required this.questions,
    required this.userAnswers,
    required this.score,
    required this.completedAt,
    required this.timeTaken,
    this.category = 'General',
  }) : id = id ?? const Uuid().v4();

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: json['id'],
      userId: json['userId'],
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
      userAnswers: Map<String, List<int>>.from(
        json['userAnswers'].map(
          (key, value) => MapEntry(key, List<int>.from(value)),
        ),
      ),
      score: json['score'],
      completedAt: DateTime.parse(json['completedAt']),
      timeTaken: Duration(milliseconds: json['timeTaken']),
      category: json['category'] ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'questions': questions.map((q) => q.toJson()).toList(),
      'userAnswers': userAnswers.map((key, value) => MapEntry(key, value)),
      'score': score,
      'completedAt': completedAt.toIso8601String(),
      'timeTaken': timeTaken.inMilliseconds,
      'category': category,
    };
  }

  double get percentage => (score / questions.length) * 100;

  String get grade {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }
}

class Quiz {
  final String id;
  final String title;
  final String description;
  final List<QuizQuestion> questions;
  final QuestionDifficulty difficulty;
  final String category;
  final Duration timeLimit;
  final bool isTimeLimited;

  Quiz({
    String? id,
    required this.title,
    required this.description,
    required this.questions,
    this.difficulty = QuestionDifficulty.medium,
    this.category = 'General',
    this.timeLimit = const Duration(minutes: 30),
    this.isTimeLimited = true,
  }) : id = id ?? const Uuid().v4();

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      questions: (json['questions'] as List)
          .map((q) => QuizQuestion.fromJson(q))
          .toList(),
      difficulty: QuestionDifficulty.values.firstWhere(
        (e) => e.toString() == json['difficulty'],
        orElse: () => QuestionDifficulty.medium,
      ),
      category: json['category'] ?? 'General',
      timeLimit: Duration(milliseconds: json['timeLimit']),
      isTimeLimited: json['isTimeLimited'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'difficulty': difficulty.toString(),
      'category': category,
      'timeLimit': timeLimit.inMilliseconds,
      'isTimeLimited': isTimeLimited,
    };
  }
}
