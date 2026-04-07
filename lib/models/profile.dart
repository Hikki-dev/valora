class Profile {
  final String id;
  final String? lastSeenVersion;
  final DateTime? onboardedAt;

  Profile({
    required this.id,
    this.lastSeenVersion,
    this.onboardedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      lastSeenVersion: json['last_seen_version'],
      onboardedAt: json['onboarded_at'] != null ? DateTime.parse(json['onboarded_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'last_seen_version': lastSeenVersion,
      'onboarded_at': onboardedAt?.toIso8601String(),
    };
  }
}
