import 'dart:math';
import '../models/quiz.dart';
import '../models/isro_data.dart';

class QuizService {
  final Random _random = Random();

  // Generate quiz from ISRO data
  Future<Quiz> generateQuiz({
    required List<Spacecraft> spacecrafts,
    required List<Launcher> launchers,
    required List<Satellite> satellites,
    required List<Centre> centres,
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
    int questionCount = 10,
  }) async {
    final List<QuizQuestion> questions = [];

    // Generate questions from different data types
    final questionsPerType = questionCount ~/ 4;
    final remainder = questionCount % 4;

    questions.addAll(
      await _generateSpacecraftQuestions(
        spacecrafts,
        questionsPerType + (remainder > 0 ? 1 : 0),
        difficulty,
      ),
    );
    questions.addAll(
      await _generateLauncherQuestions(
        launchers,
        questionsPerType + (remainder > 1 ? 1 : 0),
        difficulty,
      ),
    );
    questions.addAll(
      await _generateSatelliteQuestions(
        satellites,
        questionsPerType + (remainder > 2 ? 1 : 0),
        difficulty,
      ),
    );
    questions.addAll(
      await _generateCentreQuestions(centres, questionsPerType, difficulty),
    );

    // Shuffle questions
    questions.shuffle(_random);

    // Take only the required number of questions
    final finalQuestions = questions.take(questionCount).toList();

    return Quiz(
      title: 'ISRO Knowledge Quiz',
      description:
          'Test your knowledge about Indian Space Research Organisation',
      questions: finalQuestions,
      difficulty: difficulty,
      category: 'ISRO',
      timeLimit: Duration(minutes: questionCount * 2), // 2 minutes per question
    );
  }

  // Generate spacecraft questions
  Future<List<QuizQuestion>> _generateSpacecraftQuestions(
    List<Spacecraft> spacecrafts,
    int count,
    QuestionDifficulty difficulty,
  ) async {
    if (spacecrafts.isEmpty) return [];

    final List<QuizQuestion> questions = [];
    final usedSpacecrafts = <Spacecraft>{};

    for (
      int i = 0;
      i < count && usedSpacecrafts.length < spacecrafts.length;
      i++
    ) {
      Spacecraft spacecraft;
      do {
        spacecraft = spacecrafts[_random.nextInt(spacecrafts.length)];
      } while (usedSpacecrafts.contains(spacecraft));

      usedSpacecrafts.add(spacecraft);

      final questionTypes = [
        () => _createSpacecraftNameQuestion(spacecraft, spacecrafts),
        () => _createSpacecraftMissionQuestion(spacecraft, spacecrafts),
        () => _createSpacecraftLaunchDateQuestion(spacecraft, spacecrafts),
      ];

      final questionGenerator =
          questionTypes[_random.nextInt(questionTypes.length)];
      final question = questionGenerator();
      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }

  // Generate launcher questions
  Future<List<QuizQuestion>> _generateLauncherQuestions(
    List<Launcher> launchers,
    int count,
    QuestionDifficulty difficulty,
  ) async {
    if (launchers.isEmpty) return [];

    final List<QuizQuestion> questions = [];
    final usedLaunchers = <Launcher>{};

    for (int i = 0; i < count && usedLaunchers.length < launchers.length; i++) {
      Launcher launcher;
      do {
        launcher = launchers[_random.nextInt(launchers.length)];
      } while (usedLaunchers.contains(launcher));

      usedLaunchers.add(launcher);

      final questionTypes = [
        () => _createLauncherNameQuestion(launcher, launchers),
        () => _createLauncherTypeQuestion(launcher, launchers),
      ];

      final questionGenerator =
          questionTypes[_random.nextInt(questionTypes.length)];
      final question = questionGenerator();
      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }

  // Generate satellite questions
  Future<List<QuizQuestion>> _generateSatelliteQuestions(
    List<Satellite> satellites,
    int count,
    QuestionDifficulty difficulty,
  ) async {
    if (satellites.isEmpty) return [];

    final List<QuizQuestion> questions = [];
    final usedSatellites = <Satellite>{};

    for (
      int i = 0;
      i < count && usedSatellites.length < satellites.length;
      i++
    ) {
      Satellite satellite;
      do {
        satellite = satellites[_random.nextInt(satellites.length)];
      } while (usedSatellites.contains(satellite));

      usedSatellites.add(satellite);

      final questionTypes = [
        () => _createSatelliteApplicationQuestion(satellite, satellites),
        () => _createSatelliteOrbitQuestion(satellite, satellites),
      ];

      final questionGenerator =
          questionTypes[_random.nextInt(questionTypes.length)];
      final question = questionGenerator();
      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }

  // Generate centre questions
  Future<List<QuizQuestion>> _generateCentreQuestions(
    List<Centre> centres,
    int count,
    QuestionDifficulty difficulty,
  ) async {
    if (centres.isEmpty) return [];

    final List<QuizQuestion> questions = [];
    final usedCentres = <Centre>{};

    for (int i = 0; i < count && usedCentres.length < centres.length; i++) {
      Centre centre;
      do {
        centre = centres[_random.nextInt(centres.length)];
      } while (usedCentres.contains(centre));

      usedCentres.add(centre);

      final questionTypes = [
        () => _createCentreLocationQuestion(centre, centres),
        () => _createCentreNameQuestion(centre, centres),
      ];

      final questionGenerator =
          questionTypes[_random.nextInt(questionTypes.length)];
      final question = questionGenerator();
      if (question != null) {
        questions.add(question);
      }
    }

    return questions;
  }

  // Create spacecraft-related questions
  QuizQuestion? _createSpacecraftNameQuestion(
    Spacecraft target,
    List<Spacecraft> allSpacecrafts,
  ) {
    if (target.description == null || target.description!.isEmpty) return null;

    final options = <String>[target.name];
    final wrongOptions =
        allSpacecrafts
            .where((s) => s.name != target.name)
            .map((s) => s.name)
            .toList()
          ..shuffle(_random);

    options.addAll(wrongOptions.take(3));
    options.shuffle(_random);

    return QuizQuestion(
      question: 'Which spacecraft is described as: "${target.description}"?',
      options: options,
      correctAnswerIndices: [options.indexOf(target.name)],
      type: QuestionType.singleChoice,
      category: 'Spacecrafts',
      explanation: 'The ${target.name} is described as: ${target.description}',
    );
  }

  QuizQuestion? _createSpacecraftMissionQuestion(
    Spacecraft target,
    List<Spacecraft> allSpacecrafts,
  ) {
    if (target.mission == null || target.mission!.isEmpty) return null;

    final options = <String>[target.mission!];
    final wrongOptions =
        allSpacecrafts
            .where((s) => s.mission != null && s.mission != target.mission)
            .map((s) => s.mission!)
            .toSet()
            .toList()
          ..shuffle(_random);

    if (wrongOptions.length < 3) {
      wrongOptions.addAll([
        'Lunar exploration',
        'Mars mission',
        'Earth observation',
        'Communication relay',
      ]);
    }

    options.addAll(wrongOptions.take(3));
    options.shuffle(_random);

    return QuizQuestion(
      question: 'What is the mission of ${target.name}?',
      options: options,
      correctAnswerIndices: [options.indexOf(target.mission!)],
      type: QuestionType.singleChoice,
      category: 'Spacecrafts',
      explanation: 'The mission of ${target.name} is ${target.mission}',
    );
  }

  QuizQuestion? _createSpacecraftLaunchDateQuestion(
    Spacecraft target,
    List<Spacecraft> allSpacecrafts,
  ) {
    if (target.launchDate == null || target.launchDate!.isEmpty) return null;

    return QuizQuestion(
      question: 'When was ${target.name} launched?',
      options: [target.launchDate!, '2019', '2020', '2021'],
      correctAnswerIndices: [0],
      type: QuestionType.singleChoice,
      category: 'Spacecrafts',
      explanation: '${target.name} was launched on ${target.launchDate}',
    );
  }

  // Create launcher-related questions
  QuizQuestion? _createLauncherNameQuestion(
    Launcher target,
    List<Launcher> allLaunchers,
  ) {
    if (target.description == null || target.description!.isEmpty) return null;

    final options = <String>[target.name];
    final wrongOptions =
        allLaunchers
            .where((l) => l.name != target.name)
            .map((l) => l.name)
            .toList()
          ..shuffle(_random);

    options.addAll(wrongOptions.take(3));
    options.shuffle(_random);

    return QuizQuestion(
      question: 'Which launcher is described as: "${target.description}"?',
      options: options,
      correctAnswerIndices: [options.indexOf(target.name)],
      type: QuestionType.singleChoice,
      category: 'Launchers',
      explanation: 'The ${target.name} is described as: ${target.description}',
    );
  }

  QuizQuestion? _createLauncherTypeQuestion(
    Launcher target,
    List<Launcher> allLaunchers,
  ) {
    if (target.type == null || target.type!.isEmpty) return null;

    final options = <String>[target.type!];
    final wrongOptions =
        allLaunchers
            .where((l) => l.type != null && l.type != target.type)
            .map((l) => l.type!)
            .toSet()
            .toList()
          ..shuffle(_random);

    if (wrongOptions.length < 3) {
      wrongOptions.addAll([
        'Heavy Lift',
        'Medium Lift',
        'Small Lift',
        'Super Heavy',
      ]);
    }

    options.addAll(wrongOptions.take(3));
    options.shuffle(_random);

    return QuizQuestion(
      question: 'What type of launcher is ${target.name}?',
      options: options,
      correctAnswerIndices: [options.indexOf(target.type!)],
      type: QuestionType.singleChoice,
      category: 'Launchers',
      explanation: '${target.name} is a ${target.type} launcher',
    );
  }

  // Create satellite-related questions
  QuizQuestion? _createSatelliteApplicationQuestion(
    Satellite target,
    List<Satellite> allSatellites,
  ) {
    if (target.application == null || target.application!.isEmpty) return null;

    final options = <String>[target.application!];
    final wrongOptions =
        allSatellites
            .where(
              (s) =>
                  s.application != null && s.application != target.application,
            )
            .map((s) => s.application!)
            .toSet()
            .toList()
          ..shuffle(_random);

    if (wrongOptions.length < 3) {
      wrongOptions.addAll([
        'Communication',
        'Navigation',
        'Earth Observation',
        'Weather Monitoring',
      ]);
    }

    options.addAll(wrongOptions.take(3));
    options.shuffle(_random);

    return QuizQuestion(
      question: 'What is the primary application of ${target.name}?',
      options: options,
      correctAnswerIndices: [options.indexOf(target.application!)],
      type: QuestionType.singleChoice,
      category: 'Satellites',
      explanation: '${target.name} is used for ${target.application}',
    );
  }

  QuizQuestion? _createSatelliteOrbitQuestion(
    Satellite target,
    List<Satellite> allSatellites,
  ) {
    if (target.orbit == null || target.orbit!.isEmpty) return null;

    final options = <String>[target.orbit!];
    final wrongOptions =
        allSatellites
            .where((s) => s.orbit != null && s.orbit != target.orbit)
            .map((s) => s.orbit!)
            .toSet()
            .toList()
          ..shuffle(_random);

    if (wrongOptions.length < 3) {
      wrongOptions.addAll(['LEO', 'GEO', 'MEO', 'Polar']);
    }

    options.addAll(wrongOptions.take(3));
    options.shuffle(_random);

    return QuizQuestion(
      question: 'In which orbit does ${target.name} operate?',
      options: options,
      correctAnswerIndices: [options.indexOf(target.orbit!)],
      type: QuestionType.singleChoice,
      category: 'Satellites',
      explanation: '${target.name} operates in ${target.orbit} orbit',
    );
  }

  // Create centre-related questions
  QuizQuestion? _createCentreLocationQuestion(
    Centre target,
    List<Centre> allCentres,
  ) {
    if (target.location == null || target.location!.isEmpty) return null;

    final options = <String>[target.location!];
    final wrongOptions =
        allCentres
            .where((c) => c.location != null && c.location != target.location)
            .map((c) => c.location!)
            .toSet()
            .toList()
          ..shuffle(_random);

    options.addAll(wrongOptions.take(3));
    options.shuffle(_random);

    return QuizQuestion(
      question: 'Where is ${target.name} located?',
      options: options,
      correctAnswerIndices: [options.indexOf(target.location!)],
      type: QuestionType.singleChoice,
      category: 'Centres',
      explanation: '${target.name} is located in ${target.location}',
    );
  }

  QuizQuestion? _createCentreNameQuestion(
    Centre target,
    List<Centre> allCentres,
  ) {
    if (target.description == null || target.description!.isEmpty) return null;

    final options = <String>[target.name];
    final wrongOptions =
        allCentres
            .where((c) => c.name != target.name)
            .map((c) => c.name)
            .toList()
          ..shuffle(_random);

    options.addAll(wrongOptions.take(3));
    options.shuffle(_random);

    return QuizQuestion(
      question: 'Which ISRO centre is described as: "${target.description}"?',
      options: options,
      correctAnswerIndices: [options.indexOf(target.name)],
      type: QuestionType.singleChoice,
      category: 'Centres',
      explanation: '${target.name} is described as: ${target.description}',
    );
  }

  // Calculate quiz result
  QuizResult calculateResult({
    required String userId,
    required List<QuizQuestion> questions,
    required Map<String, List<int>> userAnswers,
    required DateTime startTime,
    required DateTime endTime,
    String category = 'ISRO',
  }) {
    int score = 0;

    for (final question in questions) {
      final selectedAnswers = userAnswers[question.id] ?? [];
      if (question.isCorrect(selectedAnswers)) {
        score++;
      }
    }

    return QuizResult(
      userId: userId,
      questions: questions,
      userAnswers: userAnswers,
      score: score,
      completedAt: endTime,
      timeTaken: endTime.difference(startTime),
      category: category,
    );
  }
}
