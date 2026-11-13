final class InspectorProfile {
  const InspectorProfile({
    required this.id,
    required this.slug,
    required this.status,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.companyName,
    this.phone = '',
    this.photoUrl = '',
    this.bio = '',
    this.yearsExperience = 0,
    this.licenseNumber = '',
    this.cities = const <String>[],
    this.states = const <String>[],
    this.services = const <String>[],
  });

  final String id;
  final String slug;
  final String status;
  final String firstName;
  final String lastName;
  final String email;
  final String companyName;
  final String phone;
  final String photoUrl;
  final String bio;
  final int yearsExperience;
  final String licenseNumber;
  final List<String> cities;
  final List<String> states;
  final List<String> services;

  String get displayName {
    final String name = '$firstName $lastName'.trim();
    return name.isEmpty ? email : name;
  }

  factory InspectorProfile.fromJson(Map<String, dynamic> json) {
    return InspectorProfile(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      companyName: json['companyName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
      bio: json['bio']?.toString() ?? '',
      yearsExperience: json['yearsExperience'] is num
          ? (json['yearsExperience'] as num).round()
          : int.tryParse('${json['yearsExperience']}') ?? 0,
      licenseNumber: json['licenseNumber']?.toString() ?? '',
      cities: _strings(json['cities']),
      states: _strings(json['states']),
      services: _strings(json['services']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'slug': slug,
        'status': status,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'companyName': companyName,
        'phone': phone,
        'photoUrl': photoUrl,
        'bio': bio,
        'yearsExperience': yearsExperience,
        'licenseNumber': licenseNumber,
        'cities': cities,
        'states': states,
        'services': services,
      };
}

final class InspectorSession {
  const InspectorSession({
    required this.token,
    required this.email,
    required this.name,
    required this.inspector,
  });

  final String token;
  final String email;
  final String name;
  final InspectorProfile inspector;

  factory InspectorSession.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> user =
        (json['user'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    final Map<String, dynamic> inspector =
        (json['inspector'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{};
    return InspectorSession(
      token: json['token']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      name: user['name']?.toString() ?? '',
      inspector: InspectorProfile.fromJson(inspector),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'token': token,
        'user': <String, dynamic>{'email': email, 'name': name},
        'inspector': inspector.toJson(),
      };
}

List<String> _strings(Object? value) {
  if (value is! List) return const <String>[];
  return value
      .map((dynamic item) => '$item'.trim())
      .where((String item) => item.isNotEmpty)
      .toList();
}
