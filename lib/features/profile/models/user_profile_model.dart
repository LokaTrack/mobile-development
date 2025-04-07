class UserProfile {
  final String phoneNumber;
  final String userId;
  final bool emailVerified;
  final String role;
  final String registrationDate;
  final String lastUpdate;
  final String email;
  final String username;
  final String? profilePictureUrl;
  final int deliveredPackages;
  final int totalDeliveries;
  final double percentage;

  UserProfile({
    required this.phoneNumber,
    required this.userId,
    required this.emailVerified,
    required this.role,
    required this.registrationDate,
    required this.lastUpdate,
    required this.email,
    required this.username,
    this.profilePictureUrl,
    required this.deliveredPackages,
    required this.totalDeliveries,
    required this.percentage,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      phoneNumber: json['phoneNumber'] ?? '',
      userId: json['userId'] ?? '',
      emailVerified: json['emailVerified'] ?? false,
      role: json['role'] ?? '',
      registrationDate: json['registrationDate'] ?? '',
      lastUpdate: json['lastUpdate'] ?? '',
      email: json['email'] ?? '',
      username: json['username'] ?? '',
      profilePictureUrl: json['profilePictureUrl'],
      deliveredPackages: json['deliveredPackages'] ?? 0,
      totalDeliveries: json['totalDeliveries'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}
