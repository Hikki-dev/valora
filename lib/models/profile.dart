class Profile {
  final String id;
  final String? lastSeenVersion;
  final int seenChangelogCount;
  final DateTime? onboardedAt;

  Profile({
    required this.id,
    this.lastSeenVersion,
    this.seenChangelogCount = 0,
    this.onboardedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'],
      lastSeenVersion: json['last_seen_version'],
      seenChangelogCount: json['seen_changelog_count'] ?? 0,
      onboardedAt: json['onboarded_at'] != null
          ? DateTime.parse(json['onboarded_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'last_seen_version': lastSeenVersion,
      'seen_changelog_count': seenChangelogCount,
      'onboarded_at': onboardedAt?.toIso8601String(),
    };
  }
}
