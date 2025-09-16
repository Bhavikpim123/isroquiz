import 'dart:math';
import '../models/quiz.dart';
import '../models/isro_data.dart';
import 'isro_api_service.dart';

class EnhancedQuizService {
  final IsroApiService _apiService;
  final Random _random = Random();

  EnhancedQuizService(this._apiService);

  // Direct method to generate sample quiz without API dependency
  ApiQuiz generateSampleQuizDirect({
    required int questionCount,
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
  }) {
    return _generateSampleQuiz(
      questionCount: questionCount,
      difficulty: difficulty,
    );
  }

  // Generate quiz questions using API endpoints with fallback
  Future<ApiQuiz> generateQuizFromAPI({
    required int questionCount,
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
  }) async {
    try {
      // Fetch all ISRO data from the specific endpoints
      final allData = await _apiService.getAllIsroData();

      final List<ApiQuizQuestion> questions = [];

      // Generate questions from different data types
      final questionsPerType = questionCount ~/ 4;
      final remainder = questionCount % 4;

      // Generate spacecraft questions
      questions.addAll(
        await _generateSpacecraftAPIQuestions(
          allData['spacecrafts'] as List<Spacecraft>,
          questionsPerType + (remainder > 0 ? 1 : 0),
        ),
      );

      // Generate launcher questions
      questions.addAll(
        await _generateLauncherAPIQuestions(
          allData['launchers'] as List<Launcher>,
          questionsPerType + (remainder > 1 ? 1 : 0),
        ),
      );

      // Generate satellite questions
      questions.addAll(
        await _generateSatelliteAPIQuestions(
          allData['satellites'] as List<Satellite>,
          questionsPerType + (remainder > 2 ? 1 : 0),
        ),
      );

      // Generate centre questions
      questions.addAll(
        await _generateCentreAPIQuestions(
          allData['centres'] as List<Centre>,
          questionsPerType,
        ),
      );

      // Shuffle questions and limit to requested count
      questions.shuffle(_random);
      final finalQuestions = questions.take(questionCount).toList();

      // Ensure we have at least some questions
      if (finalQuestions.isEmpty) {
        throw Exception(
          'Unable to generate any quiz questions from the available data',
        );
      }

      // If we have fewer questions than requested, adjust the time limit accordingly
      final adjustedQuestionCount = finalQuestions.length;
      final timeLimit = Duration(minutes: adjustedQuestionCount * 2);

      return ApiQuiz(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'ISRO Knowledge Quiz',
        description:
            'Test your knowledge about Indian Space Research Organisation',
        questions: finalQuestions,
        difficulty: difficulty,
        category: 'ISRO',
        timeLimit: timeLimit,
      );
    } catch (e) {
      // Fallback to sample quiz when API fails
      print('API failed, generating sample quiz: $e');
      return _generateSampleQuiz(
        questionCount: questionCount,
        difficulty: difficulty,
      );
    }
  }

  // Generate sample quiz with hardcoded ISRO data when API fails
  ApiQuiz _generateSampleQuiz({
    required int questionCount,
    QuestionDifficulty difficulty = QuestionDifficulty.medium,
  }) {
    final List<ApiQuizQuestion> allSampleQuestions = _getSampleQuestions();

    // Shuffle and select requested number of questions
    allSampleQuestions.shuffle(_random);
    final selectedQuestions = allSampleQuestions.take(questionCount).toList();

    return ApiQuiz(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'ISRO Knowledge Quiz (Sample)',
      description:
          'Test your knowledge about Indian Space Research Organisation with sample questions',
      questions: selectedQuestions,
      difficulty: difficulty,
      category: 'ISRO_SAMPLE',
      timeLimit: Duration(minutes: questionCount * 2),
    );
  }

  // Sample ISRO questions for fallback
  List<ApiQuizQuestion> _getSampleQuestions() {
    return [
      // Spacecraft Questions
      ApiQuizQuestion(
        id: 'sample_001',
        question: 'Which was India\'s first successful Mars mission?',
        options: ['Mangalyaan (MOM)', 'Chandrayaan-1', 'Aryabhata', 'INSAT-1A'],
        questionType: 'name_identification',
        endpoint: '/api/spacecrafts',
        itemId: 'MOM',
        category: 'Spacecrafts',
        explanation:
            'Mangalyaan (Mars Orbiter Mission) was India\'s first successful Mars mission launched in 2013.',
      ),

      ApiQuizQuestion(
        id: 'sample_002',
        question: 'What was the primary objective of Chandrayaan-1?',
        options: [
          'Lunar exploration',
          'Mars exploration',
          'Venus study',
          'Sun observation',
        ],
        questionType: 'mission_purpose',
        endpoint: '/api/spacecrafts',
        itemId: 'CH1',
        category: 'Spacecrafts',
        explanation:
            'Chandrayaan-1 was India\'s first lunar probe, launched in 2008 for lunar exploration.',
      ),

      ApiQuizQuestion(
        id: 'sample_003',
        question: 'Which spacecraft discovered water on the Moon?',
        options: ['Chandrayaan-1', 'Mangalyaan', 'Aryabhata', 'ASTROSAT'],
        questionType: 'name_identification',
        endpoint: '/api/spacecrafts',
        itemId: 'CH1',
        category: 'Spacecrafts',
        explanation:
            'Chandrayaan-1 confirmed the presence of water molecules on the Moon\'s surface.',
      ),

      // Launcher Questions
      ApiQuizQuestion(
        id: 'sample_004',
        question: 'Which is ISRO\'s heaviest rocket?',
        options: ['GSLV Mk III', 'PSLV', 'GSLV Mk II', 'SLV-3'],
        questionType: 'launcher_type',
        endpoint: '/api/launchers',
        itemId: 'GSLV_MK3',
        category: 'Launchers',
        explanation:
            'GSLV Mk III (now LVM3) is ISRO\'s most powerful rocket, capable of launching 4-ton satellites to GTO.',
      ),

      ApiQuizQuestion(
        id: 'sample_005',
        question: 'What does PSLV stand for?',
        options: [
          'Polar Satellite Launch Vehicle',
          'Primary Space Launch Vehicle',
          'Propulsion System Launch Vehicle',
          'Planetary Space Launch Vehicle',
        ],
        questionType: 'name_identification',
        endpoint: '/api/launchers',
        itemId: 'PSLV',
        category: 'Launchers',
        explanation:
            'PSLV stands for Polar Satellite Launch Vehicle, ISRO\'s workhorse rocket.',
      ),

      ApiQuizQuestion(
        id: 'sample_006',
        question: 'Which rocket was used to launch Chandrayaan-1?',
        options: ['PSLV-C11', 'GSLV Mk II', 'GSLV Mk III', 'SLV-3'],
        questionType: 'launch_vehicle',
        endpoint: '/api/launchers',
        itemId: 'PSLV',
        category: 'Launchers',
        explanation:
            'Chandrayaan-1 was launched using PSLV-C11 in October 2008.',
      ),

      // Satellite Questions
      ApiQuizQuestion(
        id: 'sample_007',
        question: 'What is the primary application of INSAT satellites?',
        options: [
          'Communication and Broadcasting',
          'Navigation',
          'Earth Observation',
          'Astronomy',
        ],
        questionType: 'mission_purpose',
        endpoint: '/api/customer_satellites',
        itemId: 'INSAT',
        category: 'Satellites',
        explanation:
            'INSAT (Indian National Satellite) series is primarily used for communication and broadcasting services.',
      ),

      ApiQuizQuestion(
        id: 'sample_008',
        question: 'Which satellite series is used for weather forecasting?',
        options: ['INSAT', 'IRS', 'CARTOSAT', 'ASTROSAT'],
        questionType: 'mission_purpose',
        endpoint: '/api/customer_satellites',
        itemId: 'INSAT',
        category: 'Satellites',
        explanation:
            'INSAT satellites provide meteorological services including weather forecasting.',
      ),

      ApiQuizQuestion(
        id: 'sample_009',
        question: 'What does IRS stand for?',
        options: [
          'Indian Remote Sensing',
          'Indian Radio Satellite',
          'Indian Research Satellite',
          'Indian Relay Station',
        ],
        questionType: 'name_identification',
        endpoint: '/api/customer_satellites',
        itemId: 'IRS',
        category: 'Satellites',
        explanation:
            'IRS stands for Indian Remote Sensing, used for earth observation and mapping.',
      ),

      // Centre Questions
      ApiQuizQuestion(
        id: 'sample_010',
        question: 'Where is ISRO\'s headquarters located?',
        options: ['Bengaluru', 'Thiruvananthapuram', 'Hyderabad', 'Mumbai'],
        questionType: 'location',
        endpoint: '/api/centres',
        itemId: 'HQ',
        category: 'Centres',
        explanation: 'ISRO\'s headquarters is located in Bengaluru, Karnataka.',
      ),

      ApiQuizQuestion(
        id: 'sample_011',
        question: 'Which centre is responsible for satellite launches?',
        options: [
          'SHAR (Sriharikota)',
          'VSSC (Thiruvananthapuram)',
          'ISAC (Bengaluru)',
          'SAC (Ahmedabad)',
        ],
        questionType: 'name_identification',
        endpoint: '/api/centres',
        itemId: 'SHAR',
        category: 'Centres',
        explanation:
            'Satish Dhawan Space Centre (SHAR) at Sriharikota is India\'s primary spaceport.',
      ),

      ApiQuizQuestion(
        id: 'sample_012',
        question: 'What does VSSC stand for?',
        options: [
          'Vikram Sarabhai Space Centre',
          'Vehicle Systems Space Centre',
          'Vertical Space Systems Centre',
          'Virtual Space Science Centre',
        ],
        questionType: 'name_identification',
        endpoint: '/api/centres',
        itemId: 'VSSC',
        category: 'Centres',
        explanation:
            'VSSC stands for Vikram Sarabhai Space Centre, located in Thiruvananthapuram.',
      ),

      // Additional ISRO Knowledge Questions
      ApiQuizQuestion(
        id: 'sample_013',
        question: 'Who is known as the father of Indian space program?',
        options: [
          'Dr. Vikram Sarabhai',
          'Dr. A.P.J. Abdul Kalam',
          'Dr. Satish Dhawan',
          'Dr. K. Radhakrishnan',
        ],
        questionType: 'name_identification',
        endpoint: '/api/personalities',
        itemId: 'VS',
        category: 'History',
        explanation:
            'Dr. Vikram Sarabhai is regarded as the father of the Indian space program.',
      ),

      ApiQuizQuestion(
        id: 'sample_014',
        question: 'In which year was ISRO established?',
        options: ['1969', '1962', '1972', '1975'],
        questionType: 'historical_date',
        endpoint: '/api/history',
        itemId: 'ISRO_EST',
        category: 'History',
        explanation: 'ISRO was established on August 15, 1969.',
      ),

      ApiQuizQuestion(
        id: 'sample_015',
        question: 'What was India\'s first satellite?',
        options: ['Aryabhata', 'Bhaskara-1', 'INSAT-1A', 'IRS-1A'],
        questionType: 'name_identification',
        endpoint: '/api/spacecrafts',
        itemId: 'ARYABHATA',
        category: 'Spacecrafts',
        explanation:
            'Aryabhata was India\'s first satellite, launched on April 19, 1975.',
      ),

      ApiQuizQuestion(
        id: 'sample_016',
        question:
            'Which mission made India the fourth country to land on the Moon?',
        options: [
          'Chandrayaan-3',
          'Chandrayaan-2',
          'Chandrayaan-1',
          'Mangalyaan',
        ],
        questionType: 'name_identification',
        endpoint: '/api/spacecrafts',
        itemId: 'CH3',
        category: 'Spacecrafts',
        explanation:
            'Chandrayaan-3 successfully landed on the Moon in August 2023, making India the fourth country to achieve this feat.',
      ),

      ApiQuizQuestion(
        id: 'sample_017',
        question:
            'What is the name of India\'s space-based astronomy observatory?',
        options: ['ASTROSAT', 'INSAT-3D', 'CARTOSAT-2', 'RESOURCESAT-2'],
        questionType: 'name_identification',
        endpoint: '/api/spacecrafts',
        itemId: 'ASTROSAT',
        category: 'Spacecrafts',
        explanation:
            'ASTROSAT is India\'s first dedicated multi-wavelength space observatory.',
      ),

      ApiQuizQuestion(
        id: 'sample_018',
        question:
            'Which ISRO mission holds the record for the most satellites launched in a single mission?',
        options: [
          'PSLV-C37 (104 satellites)',
          'PSLV-C34 (20 satellites)',
          'PSLV-C28 (5 satellites)',
          'GSLV-C25 (1 satellite)',
        ],
        questionType: 'record_achievement',
        endpoint: '/api/missions',
        itemId: 'PSLV_C37',
        category: 'Achievements',
        explanation:
            'PSLV-C37 launched 104 satellites in a single mission in February 2017, setting a world record.',
      ),

      ApiQuizQuestion(
        id: 'sample_019',
        question: 'What does GSLV stand for?',
        options: [
          'Geosynchronous Satellite Launch Vehicle',
          'Geostationary Space Launch Vehicle',
          'Global Satellite Launch Vehicle',
          'Guided Space Launch Vehicle',
        ],
        questionType: 'name_identification',
        endpoint: '/api/launchers',
        itemId: 'GSLV',
        category: 'Launchers',
        explanation: 'GSLV stands for Geosynchronous Satellite Launch Vehicle.',
      ),

      ApiQuizQuestion(
        id: 'sample_020',
        question: 'Which orbit is typically used by communication satellites?',
        options: [
          'Geostationary Earth Orbit (GEO)',
          'Low Earth Orbit (LEO)',
          'Medium Earth Orbit (MEO)',
          'Highly Elliptical Orbit (HEO)',
        ],
        questionType: 'satellite_orbit',
        endpoint: '/api/orbits',
        itemId: 'GEO',
        category: 'Orbital Mechanics',
        explanation:
            'Communication satellites typically use Geostationary Earth Orbit (GEO) at 36,000 km altitude.',
      ),
    ];
  }

  // Generate spacecraft questions with API evaluation
  Future<List<ApiQuizQuestion>> _generateSpacecraftAPIQuestions(
    List<Spacecraft> spacecrafts,
    int count,
  ) async {
    if (spacecrafts.isEmpty) return [];

    final List<ApiQuizQuestion> questions = [];
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

      // Generate different types of questions
      final questionTypes = [
        () => _createSpacecraftNameQuestion(spacecraft, spacecrafts),
        () => _createSpacecraftMissionQuestion(spacecraft, spacecrafts),
        () => _createSpacecraftDateQuestion(spacecraft, spacecrafts),
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

  // Generate launcher questions with API evaluation
  Future<List<ApiQuizQuestion>> _generateLauncherAPIQuestions(
    List<Launcher> launchers,
    int count,
  ) async {
    if (launchers.isEmpty) return [];

    final List<ApiQuizQuestion> questions = [];
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

  // Generate satellite questions with API evaluation
  Future<List<ApiQuizQuestion>> _generateSatelliteAPIQuestions(
    List<Satellite> satellites,
    int count,
  ) async {
    if (satellites.isEmpty) return [];

    final List<ApiQuizQuestion> questions = [];
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

  // Generate centre questions with API evaluation
  Future<List<ApiQuizQuestion>> _generateCentreAPIQuestions(
    List<Centre> centres,
    int count,
  ) async {
    if (centres.isEmpty) return [];

    final List<ApiQuizQuestion> questions = [];
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

  // Create spacecraft name identification question
  ApiQuizQuestion? _createSpacecraftNameQuestion(
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

    return ApiQuizQuestion(
      id:
          DateTime.now().millisecondsSinceEpoch.toString() +
          _random.nextInt(1000).toString(),
      question: 'Which spacecraft is described as: "${target.description}"?',
      options: options,
      questionType: 'name_identification',
      endpoint: '/api/spacecrafts',
      itemId: target.id.toString(),
      category: 'Spacecrafts',
      explanation: 'The ${target.name} is described as: ${target.description}',
    );
  }

  // Create spacecraft mission question
  ApiQuizQuestion? _createSpacecraftMissionQuestion(
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
      ]);
    }

    options.addAll(wrongOptions.take(3));
    options.shuffle(_random);

    return ApiQuizQuestion(
      id:
          DateTime.now().millisecondsSinceEpoch.toString() +
          _random.nextInt(1000).toString(),
      question: 'What is the mission of ${target.name}?',
      options: options,
      questionType: 'mission_purpose',
      endpoint: '/api/spacecrafts',
      itemId: target.id.toString(),
      category: 'Spacecrafts',
      explanation: 'The mission of ${target.name} is ${target.mission}',
    );
  }

  // Create spacecraft launch date question
  ApiQuizQuestion? _createSpacecraftDateQuestion(
    Spacecraft target,
    List<Spacecraft> allSpacecrafts,
  ) {
    if (target.launchDate == null || target.launchDate!.isEmpty) return null;

    final options = [target.launchDate!, '2019', '2020', '2021'];
    options.shuffle(_random);

    return ApiQuizQuestion(
      id:
          DateTime.now().millisecondsSinceEpoch.toString() +
          _random.nextInt(1000).toString(),
      question: 'When was ${target.name} launched?',
      options: options,
      questionType: 'launch_date',
      endpoint: '/api/spacecrafts',
      itemId: target.id.toString(),
      category: 'Spacecrafts',
      explanation: '${target.name} was launched on ${target.launchDate}',
    );
  }

  // Create launcher name question
  ApiQuizQuestion? _createLauncherNameQuestion(
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

    return ApiQuizQuestion(
      id:
          DateTime.now().millisecondsSinceEpoch.toString() +
          _random.nextInt(1000).toString(),
      question: 'Which launcher is described as: "${target.description}"?',
      options: options,
      questionType: 'name_identification',
      endpoint: '/api/launchers',
      itemId: target.id.toString(),
      category: 'Launchers',
      explanation: 'The ${target.name} is described as: ${target.description}',
    );
  }

  // Create launcher type question
  ApiQuizQuestion? _createLauncherTypeQuestion(
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
      wrongOptions.addAll(['Heavy Lift', 'Medium Lift', 'Small Lift']);
    }

    options.addAll(wrongOptions.take(3));
    options.shuffle(_random);

    return ApiQuizQuestion(
      id:
          DateTime.now().millisecondsSinceEpoch.toString() +
          _random.nextInt(1000).toString(),
      question: 'What type of launcher is ${target.name}?',
      options: options,
      questionType: 'launcher_type',
      endpoint: '/api/launchers',
      itemId: target.id.toString(),
      category: 'Launchers',
      explanation: '${target.name} is a ${target.type} launcher',
    );
  }

  // Create satellite application question
  ApiQuizQuestion? _createSatelliteApplicationQuestion(
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
      wrongOptions.addAll(['Communication', 'Navigation', 'Earth Observation']);
    }

    options.addAll(wrongOptions.take(3));
    options.shuffle(_random);

    return ApiQuizQuestion(
      id:
          DateTime.now().millisecondsSinceEpoch.toString() +
          _random.nextInt(1000).toString(),
      question: 'What is the primary application of ${target.name}?',
      options: options,
      questionType: 'mission_purpose',
      endpoint: '/api/customer_satellites',
      itemId: target.id.toString(),
      category: 'Satellites',
      explanation: '${target.name} is used for ${target.application}',
    );
  }

  // Create satellite orbit question
  ApiQuizQuestion? _createSatelliteOrbitQuestion(
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
      wrongOptions.addAll(['LEO', 'GEO', 'MEO']);
    }

    options.addAll(wrongOptions.take(3));
    options.shuffle(_random);

    return ApiQuizQuestion(
      id:
          DateTime.now().millisecondsSinceEpoch.toString() +
          _random.nextInt(1000).toString(),
      question: 'In which orbit does ${target.name} operate?',
      options: options,
      questionType: 'satellite_orbit',
      endpoint: '/api/customer_satellites',
      itemId: target.id.toString(),
      category: 'Satellites',
      explanation: '${target.name} operates in ${target.orbit} orbit',
    );
  }

  // Create centre location question
  ApiQuizQuestion? _createCentreLocationQuestion(
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

    return ApiQuizQuestion(
      id:
          DateTime.now().millisecondsSinceEpoch.toString() +
          _random.nextInt(1000).toString(),
      question: 'Where is ${target.name} located?',
      options: options,
      questionType: 'location',
      endpoint: '/api/centres',
      itemId: target.id.toString(),
      category: 'Centres',
      explanation: '${target.name} is located in ${target.location}',
    );
  }

  // Create centre name question
  ApiQuizQuestion? _createCentreNameQuestion(
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

    return ApiQuizQuestion(
      id:
          DateTime.now().millisecondsSinceEpoch.toString() +
          _random.nextInt(1000).toString(),
      question: 'Which ISRO centre is described as: "${target.description}"?',
      options: options,
      questionType: 'name_identification',
      endpoint: '/api/centres',
      itemId: target.id.toString(),
      category: 'Centres',
      explanation: '${target.name} is described as: ${target.description}',
    );
  }

  // Evaluate answer using API endpoint with fallback to hardcoded answers
  Future<EvaluationResult> evaluateAnswer({
    required ApiQuizQuestion question,
    required List<String> userAnswers,
  }) async {
    try {
      // For sample questions, use hardcoded evaluation
      if (question.id.startsWith('sample_')) {
        return _evaluateSampleQuestion(question, userAnswers);
      }

      // Fetch the specific item from the API endpoint to validate
      final response = await _apiService.getSpecificItem(
        question.endpoint,
        question.itemId,
      );

      if (response == null) {
        throw Exception('Item not found for evaluation');
      }

      // Perform evaluation based on question type
      final isCorrect = _evaluateAnswerAgainstData(
        response,
        userAnswers,
        question.questionType,
      );

      return EvaluationResult(
        isCorrect: isCorrect,
        correctAnswer: _getCorrectAnswer(response, question.questionType),
        explanation: question.explanation ?? 'No explanation available',
        userAnswer: userAnswers.isNotEmpty ? userAnswers.first : '',
      );
    } catch (e) {
      // Fallback to sample question evaluation if API fails
      return _evaluateSampleQuestion(question, userAnswers);
    }
  }

  // Evaluate sample questions with hardcoded correct answers
  EvaluationResult _evaluateSampleQuestion(
    ApiQuizQuestion question,
    List<String> userAnswers,
  ) {
    if (userAnswers.isEmpty) {
      return EvaluationResult(
        isCorrect: false,
        correctAnswer: question.options.first,
        explanation: question.explanation ?? 'No answer provided',
        userAnswer: '',
      );
    }

    final userAnswer = userAnswers.first;
    final correctAnswer = _getSampleCorrectAnswer(question.id);
    final isCorrect = userAnswer == correctAnswer;

    return EvaluationResult(
      isCorrect: isCorrect,
      correctAnswer: correctAnswer,
      explanation: question.explanation ?? 'Sample question evaluation',
      userAnswer: userAnswer,
    );
  }

  // Get correct answers for sample questions
  String _getSampleCorrectAnswer(String questionId) {
    final Map<String, String> sampleAnswers = {
      'sample_001': 'Mangalyaan (MOM)',
      'sample_002': 'Lunar exploration',
      'sample_003': 'Chandrayaan-1',
      'sample_004': 'GSLV Mk III',
      'sample_005': 'Polar Satellite Launch Vehicle',
      'sample_006': 'PSLV-C11',
      'sample_007': 'Communication and Broadcasting',
      'sample_008': 'INSAT',
      'sample_009': 'Indian Remote Sensing',
      'sample_010': 'Bengaluru',
      'sample_011': 'SHAR (Sriharikota)',
      'sample_012': 'Vikram Sarabhai Space Centre',
      'sample_013': 'Dr. Vikram Sarabhai',
      'sample_014': '1969',
      'sample_015': 'Aryabhata',
      'sample_016': 'Chandrayaan-3',
      'sample_017': 'ASTROSAT',
      'sample_018': 'PSLV-C37 (104 satellites)',
      'sample_019': 'Geosynchronous Satellite Launch Vehicle',
      'sample_020': 'Geostationary Earth Orbit (GEO)',
    };

    return sampleAnswers[questionId] ?? 'Unknown';
  }

  // Private method to evaluate answer against API data
  bool _evaluateAnswerAgainstData(
    Map<String, dynamic> itemData,
    List<String> userAnswers,
    String questionType,
  ) {
    if (userAnswers.isEmpty) return false;

    final userAnswer = userAnswers.first.toLowerCase().trim();

    switch (questionType) {
      case 'name_identification':
        return itemData['name']?.toString().toLowerCase() == userAnswer;
      case 'mission_purpose':
        final mission =
            itemData['mission']?.toString().toLowerCase() ??
            itemData['application']?.toString().toLowerCase();
        return mission == userAnswer;
      case 'launch_date':
        final date =
            itemData['launch_date']?.toString() ??
            itemData['first_flight']?.toString();
        return date == userAnswers.first;
      case 'location':
        return itemData['location']?.toString().toLowerCase() == userAnswer;
      case 'launcher_type':
        return itemData['type']?.toString().toLowerCase() == userAnswer;
      case 'satellite_orbit':
        return itemData['orbit']?.toString().toLowerCase() == userAnswer;
      default:
        return false;
    }
  }

  // Get correct answer from API data
  String _getCorrectAnswer(Map<String, dynamic> itemData, String questionType) {
    switch (questionType) {
      case 'name_identification':
        return itemData['name']?.toString() ?? '';
      case 'mission_purpose':
        return itemData['mission']?.toString() ??
            itemData['application']?.toString() ??
            '';
      case 'launch_date':
        return itemData['launch_date']?.toString() ??
            itemData['first_flight']?.toString() ??
            '';
      case 'location':
        return itemData['location']?.toString() ?? '';
      case 'launcher_type':
        return itemData['type']?.toString() ?? '';
      case 'satellite_orbit':
        return itemData['orbit']?.toString() ?? '';
      default:
        return '';
    }
  }

  // Calculate final quiz result with API validation and fallback
  Future<ApiQuizResult> calculateResult({
    required String userId,
    required ApiQuiz quiz,
    required Map<String, List<String>> userAnswers,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final List<EvaluationResult> evaluations = [];
    int totalScore = 0;

    // Evaluate each question using API or fallback
    for (final question in quiz.questions) {
      final userAnswer = userAnswers[question.id] ?? [];
      try {
        final evaluation = await evaluateAnswer(
          question: question,
          userAnswers: userAnswer,
        );

        evaluations.add(evaluation);
        if (evaluation.isCorrect) {
          totalScore++;
        }
      } catch (e) {
        // Fallback evaluation if API fails
        print(
          'Evaluation failed for question ${question.id}, using fallback: $e',
        );
        final fallbackEvaluation = _evaluateSampleQuestion(
          question,
          userAnswer,
        );
        evaluations.add(fallbackEvaluation);
        if (fallbackEvaluation.isCorrect) {
          totalScore++;
        }
      }
    }

    return ApiQuizResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      quiz: quiz,
      userAnswers: userAnswers,
      evaluations: evaluations,
      score: totalScore,
      totalQuestions: quiz.questions.length,
      completedAt: endTime,
      timeTaken: endTime.difference(startTime),
      category: quiz.category,
    );
  }
}

// Enhanced models for API-based quiz system
class ApiQuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final String questionType;
  final String endpoint;
  final String itemId;
  final String category;
  final String? explanation;

  ApiQuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.questionType,
    required this.endpoint,
    required this.itemId,
    required this.category,
    this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'options': options,
      'questionType': questionType,
      'endpoint': endpoint,
      'itemId': itemId,
      'category': category,
      'explanation': explanation,
    };
  }

  factory ApiQuizQuestion.fromJson(Map<String, dynamic> json) {
    return ApiQuizQuestion(
      id: json['id'],
      question: json['question'],
      options: List<String>.from(json['options']),
      questionType: json['questionType'],
      endpoint: json['endpoint'],
      itemId: json['itemId'],
      category: json['category'],
      explanation: json['explanation'],
    );
  }
}

class ApiQuiz {
  final String id;
  final String title;
  final String description;
  final List<ApiQuizQuestion> questions;
  final QuestionDifficulty difficulty;
  final String category;
  final Duration timeLimit;

  ApiQuiz({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.difficulty,
    required this.category,
    required this.timeLimit,
  });
}

class EvaluationResult {
  final bool isCorrect;
  final String correctAnswer;
  final String explanation;
  final String userAnswer;

  EvaluationResult({
    required this.isCorrect,
    required this.correctAnswer,
    required this.explanation,
    required this.userAnswer,
  });
}

class ApiQuizResult {
  final String id;
  final String userId;
  final ApiQuiz quiz;
  final Map<String, List<String>> userAnswers;
  final List<EvaluationResult> evaluations;
  final int score;
  final int totalQuestions;
  final DateTime completedAt;
  final Duration timeTaken;
  final String category;

  ApiQuizResult({
    required this.id,
    required this.userId,
    required this.quiz,
    required this.userAnswers,
    required this.evaluations,
    required this.score,
    required this.totalQuestions,
    required this.completedAt,
    required this.timeTaken,
    required this.category,
  });

  double get percentage => (score / totalQuestions) * 100;

  String get grade {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B';
    if (percentage >= 60) return 'C';
    if (percentage >= 50) return 'D';
    return 'F';
  }
}
