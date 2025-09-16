// Helper function to safely parse double values
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

class Spacecraft {
  final String id;
  final String name;
  final String? description;
  final String? launchDate;
  final String? mission;
  final String? status;
  final String? imageUrl;
  final List<String> objectives;

  Spacecraft({
    required this.id,
    required this.name,
    this.description,
    this.launchDate,
    this.mission,
    this.status,
    this.imageUrl,
    this.objectives = const [],
  });

  factory Spacecraft.fromJson(Map<String, dynamic> json) {
    return Spacecraft(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      description: json['description'],
      launchDate: json['launch_date'],
      mission: json['mission'],
      status: json['status'],
      imageUrl: json['image_url'],
      objectives: json['objectives'] != null
          ? List<String>.from(json['objectives'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'launch_date': launchDate,
      'mission': mission,
      'status': status,
      'image_url': imageUrl,
      'objectives': objectives,
    };
  }
}

class Launcher {
  final String id;
  final String name;
  final String? description;
  final String? firstFlight;
  final String? status;
  final String? imageUrl;
  final String? type;
  final double? height;
  final double? mass;

  Launcher({
    required this.id,
    required this.name,
    this.description,
    this.firstFlight,
    this.status,
    this.imageUrl,
    this.type,
    this.height,
    this.mass,
  });

  factory Launcher.fromJson(Map<String, dynamic> json) {
    return Launcher(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      description: json['description'],
      firstFlight: json['first_flight'],
      status: json['status'],
      imageUrl: json['image_url'],
      type: json['type'],
      height: _parseDouble(json['height']),
      mass: _parseDouble(json['mass']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'first_flight': firstFlight,
      'status': status,
      'image_url': imageUrl,
      'type': type,
      'height': height,
      'mass': mass,
    };
  }
}

class Satellite {
  final String id;
  final String name;
  final String? description;
  final String? launchDate;
  final String? application;
  final String? status;
  final String? imageUrl;
  final String? orbit;
  final double? mass;

  Satellite({
    required this.id,
    required this.name,
    this.description,
    this.launchDate,
    this.application,
    this.status,
    this.imageUrl,
    this.orbit,
    this.mass,
  });

  factory Satellite.fromJson(Map<String, dynamic> json) {
    return Satellite(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      description: json['description'],
      launchDate: json['launch_date'],
      application: json['application'],
      status: json['status'],
      imageUrl: json['image_url'],
      orbit: json['orbit'],
      mass: _parseDouble(json['mass']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'launch_date': launchDate,
      'application': application,
      'status': status,
      'image_url': imageUrl,
      'orbit': orbit,
      'mass': mass,
    };
  }
}

class Centre {
  final String id;
  final String name;
  final String? description;
  final String? location;
  final String? established;
  final String? imageUrl;
  final List<String> facilities;

  Centre({
    required this.id,
    required this.name,
    this.description,
    this.location,
    this.established,
    this.imageUrl,
    this.facilities = const [],
  });

  factory Centre.fromJson(Map<String, dynamic> json) {
    return Centre(
      id: (json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      description: json['description'],
      location: json['location'],
      established: json['established'],
      imageUrl: json['image_url'],
      facilities: json['facilities'] != null
          ? List<String>.from(json['facilities'])
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'established': established,
      'image_url': imageUrl,
      'facilities': facilities,
    };
  }
}
