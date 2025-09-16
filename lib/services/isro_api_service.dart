import 'package:dio/dio.dart';
import '../models/isro_data.dart';

class IsroApiService {
  static const String baseUrl = 'https://isro.vercel.app/api';
  late final Dio _dio;

  IsroApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (obj) => print(obj),
      ),
    );
  }

  // Fetch spacecrafts data
  Future<List<Spacecraft>> getSpacecrafts() async {
    try {
      final response = await _dio.get('/spacecrafts');

      if (response.statusCode == 200) {
        final List<dynamic> data =
            response.data['spacecrafts'] ?? response.data;
        return data.map((json) => Spacecraft.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load spacecrafts: ${response.statusCode}');
      }
    } catch (e) {
      // Return fallback data if API fails
      return _getFallbackSpacecrafts();
    }
  }

  // Fetch launchers data
  Future<List<Launcher>> getLaunchers() async {
    try {
      final response = await _dio.get('/launchers');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['launchers'] ?? response.data;
        return data.map((json) => Launcher.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load launchers: ${response.statusCode}');
      }
    } catch (e) {
      // Return fallback data if API fails
      return _getFallbackLaunchers();
    }
  }

  // Fetch customer satellites data
  Future<List<Satellite>> getCustomerSatellites() async {
    try {
      final response = await _dio.get('/customer_satellites');

      if (response.statusCode == 200) {
        final List<dynamic> data =
            response.data['customer_satellites'] ?? response.data;
        return data.map((json) => Satellite.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load satellites: ${response.statusCode}');
      }
    } catch (e) {
      // Return fallback data if API fails
      return _getFallbackSatellites();
    }
  }

  // Fetch centres data
  Future<List<Centre>> getCentres() async {
    try {
      final response = await _dio.get('/centres');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['centres'] ?? response.data;
        return data.map((json) => Centre.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load centres: ${response.statusCode}');
      }
    } catch (e) {
      // Return fallback data if API fails
      return _getFallbackCentres();
    }
  }

  // Fetch all ISRO data with fallback
  Future<Map<String, dynamic>> getAllIsroData() async {
    try {
      final futures = await Future.wait([
        getSpacecrafts(),
        getLaunchers(),
        getCustomerSatellites(),
        getCentres(),
      ]);

      return {
        'spacecrafts': futures[0] as List<Spacecraft>,
        'launchers': futures[1] as List<Launcher>,
        'satellites': futures[2] as List<Satellite>,
        'centres': futures[3] as List<Centre>,
      };
    } catch (e) {
      // Return fallback data if API fails
      return _getFallbackData();
    }
  }

  // Fallback data for when API is unavailable
  Map<String, dynamic> _getFallbackData() {
    return {
      'spacecrafts': _getFallbackSpacecrafts(),
      'launchers': _getFallbackLaunchers(),
      'satellites': _getFallbackSatellites(),
      'centres': _getFallbackCentres(),
    };
  }

  List<Spacecraft> _getFallbackSpacecrafts() {
    return [
      Spacecraft(
        id: '1',
        name: 'Chandrayaan-3',
        description: 'India\'s third lunar exploration mission',
        mission: 'Lunar exploration and soft landing',
        status: 'Successful',
        launchDate: '2023-07-14',
      ),
      Spacecraft(
        id: '2',
        name: 'Mangalyaan',
        description: 'Mars Orbiter Mission',
        mission: 'Mars exploration',
        status: 'Successful',
        launchDate: '2013-11-05',
      ),
    ];
  }

  List<Launcher> _getFallbackLaunchers() {
    return [
      Launcher(
        id: '1',
        name: 'PSLV',
        description: 'Polar Satellite Launch Vehicle',
        type: 'Medium-lift launch vehicle',
        status: 'Active',
      ),
      Launcher(
        id: '2',
        name: 'GSLV',
        description: 'Geosynchronous Satellite Launch Vehicle',
        type: 'Heavy-lift launch vehicle',
        status: 'Active',
      ),
    ];
  }

  List<Satellite> _getFallbackSatellites() {
    return [
      Satellite(
        id: '1',
        name: 'RISAT-2B',
        description: 'Radar Imaging Satellite',
        application: 'Earth observation',
        status: 'Operational',
      ),
      Satellite(
        id: '2',
        name: 'CARTOSAT-3',
        description: 'Earth observation satellite',
        application: 'Cartography and mapping',
        status: 'Operational',
      ),
    ];
  }

  List<Centre> _getFallbackCentres() {
    return [
      Centre(
        id: '1',
        name: 'SHAR',
        description: 'Satish Dhawan Space Centre',
        location: 'Sriharikota, Andhra Pradesh',
        established: '1971',
      ),
      Centre(
        id: '2',
        name: 'VSSC',
        description: 'Vikram Sarabhai Space Centre',
        location: 'Thiruvananthapuram, Kerala',
        established: '1963',
      ),
    ];
  }

  // Handle Dio exceptions
  String _handleDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Send timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Receive timeout. Please try again.';
      case DioExceptionType.badResponse:
        return 'Server error: ${e.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';
      default:
        return 'Network error occurred. Please try again.';
    }
  }

  // Search spacecrafts by name
  Future<List<Spacecraft>> searchSpacecrafts(String query) async {
    final spacecrafts = await getSpacecrafts();
    return spacecrafts
        .where(
          (spacecraft) =>
              spacecraft.name.toLowerCase().contains(query.toLowerCase()) ||
              (spacecraft.mission?.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  // Search launchers by name
  Future<List<Launcher>> searchLaunchers(String query) async {
    final launchers = await getLaunchers();
    return launchers
        .where(
          (launcher) =>
              launcher.name.toLowerCase().contains(query.toLowerCase()) ||
              (launcher.type?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        )
        .toList();
  }

  // Search satellites by name
  Future<List<Satellite>> searchSatellites(String query) async {
    final satellites = await getCustomerSatellites();
    return satellites
        .where(
          (satellite) =>
              satellite.name.toLowerCase().contains(query.toLowerCase()) ||
              (satellite.application?.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  // Search centres by name
  Future<List<Centre>> searchCentres(String query) async {
    final centres = await getCentres();
    return centres
        .where(
          (centre) =>
              centre.name.toLowerCase().contains(query.toLowerCase()) ||
              (centre.location?.toLowerCase().contains(query.toLowerCase()) ??
                  false),
        )
        .toList();
  }

  // Get paginated data
  Future<List<T>> getPaginatedData<T>(
    Future<List<T>> Function() fetchFunction,
    int page,
    int limit,
  ) async {
    final allData = await fetchFunction();
    final startIndex = page * limit;
    final endIndex = (startIndex + limit).clamp(0, allData.length);

    if (startIndex >= allData.length) {
      return [];
    }

    return allData.sublist(startIndex, endIndex);
  }

  // Get specific item by ID from endpoint
  Future<Map<String, dynamic>?> getSpecificItem(
    String endpoint,
    String itemId,
  ) async {
    try {
      final response = await _dio.get(endpoint);

      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> items;

        // Handle different response structures
        if (data is Map<String, dynamic>) {
          // If response is wrapped in an object, get the array
          final key = data.keys.first;
          items = data[key] as List<dynamic>;
        } else {
          // If response is directly an array
          items = data as List<dynamic>;
        }

        // Find item by ID
        final item = items.firstWhere(
          (item) => item['id'].toString() == itemId,
          orElse: () => null,
        );

        return item != null ? Map<String, dynamic>.from(item) : null;
      } else {
        throw Exception('Failed to fetch item: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    } catch (e) {
      throw Exception('Error fetching specific item: $e');
    }
  }
}

// Exception classes for better error handling
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() =>
      'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
