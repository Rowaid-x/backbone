class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String crewRole;
  final String country;
  final String state;
  final String city;
  final String avatarUrl;
  final String faaLevel;
  final String mmacLevel;
  final bool isActive;
  final int showsCount;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.crewRole = '',
    this.country = '',
    this.state = '',
    this.city = '',
    this.avatarUrl = '',
    this.faaLevel = '',
    this.mmacLevel = '',
    this.isActive = true,
    this.showsCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        role: json['role'] as String? ?? '',
        crewRole: json['crew_role'] as String? ?? '',
        country: json['country'] as String? ?? '',
        state: json['state'] as String? ?? '',
        city: json['city'] as String? ?? '',
        avatarUrl: json['avatar_url'] as String? ?? '',
        faaLevel: json['faa_level'] as String? ?? '',
        mmacLevel: json['mmac_level'] as String? ?? '',
        isActive: json['is_active'] as bool? ?? true,
        showsCount: json['shows_count'] as int? ?? 0,
      );

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return fullName.substring(0, fullName.length.clamp(0, 2)).toUpperCase();
  }

  String get locationDisplay {
    final parts = [city, country].where((s) => s.isNotEmpty).toList();
    return parts.join(', ');
  }
}
