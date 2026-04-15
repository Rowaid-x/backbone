class UserModel {
  final int id;
  final String email;
  final String name;
  final String sheetName;
  final String region;
  final String fcmToken;

  const UserModel({
    required this.id,
    required this.email,
    this.name = '',
    this.sheetName = '',
    this.region = '',
    this.fcmToken = '',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        email: json['email'] as String,
        name: (json['name'] as String?) ?? '',
        sheetName: (json['sheet_name'] as String?) ?? '',
        region: (json['region'] as String?) ?? '',
        fcmToken: (json['fcm_token'] as String?) ?? '',
      );
}
