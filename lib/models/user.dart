class User {
  final String id;
  final String email;
  final String? name;
  final DateTime? joinDate;
  final int totalQuizzesTaken;
  final int totalCorrectAnswers;
  final double averageScore;

  User({
    required this.id,
    required this.email,
    this.name,
    this.joinDate,
    this.totalQuizzesTaken = 0,
    this.totalCorrectAnswers = 0,
    this.averageScore = 0.0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'],
      joinDate: json['joinDate'] != null
          ? DateTime.parse(json['joinDate'])
          : null,
      totalQuizzesTaken: json['totalQuizzesTaken'] ?? 0,
      totalCorrectAnswers: json['totalCorrectAnswers'] ?? 0,
      averageScore: (json['averageScore'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'joinDate': joinDate?.toIso8601String(),
      'totalQuizzesTaken': totalQuizzesTaken,
      'totalCorrectAnswers': totalCorrectAnswers,
      'averageScore': averageScore,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? joinDate,
    int? totalQuizzesTaken,
    int? totalCorrectAnswers,
    double? averageScore,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      joinDate: joinDate ?? this.joinDate,
      totalQuizzesTaken: totalQuizzesTaken ?? this.totalQuizzesTaken,
      totalCorrectAnswers: totalCorrectAnswers ?? this.totalCorrectAnswers,
      averageScore: averageScore ?? this.averageScore,
    );
  }
}
