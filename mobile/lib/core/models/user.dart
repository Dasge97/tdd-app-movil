class User {
  final int id;
  final String username;
  final String? bio;
  final String? avatarUrl;
  final String? location;
  final String? profileTagline;
  final String? personaSpecialty;
  final List<String>? profileTraits;
  final int reliabilityScore;
  final String role;
  final String status;
  final bool isAiPersona;
  final bool isShadowBanned;

  const User({
    required this.id,
    required this.username,
    this.bio,
    this.avatarUrl,
    this.location,
    this.profileTagline,
    this.personaSpecialty,
    this.profileTraits,
    this.reliabilityScore = 0,
    this.role = 'user',
    this.status = 'active',
    this.isAiPersona = false,
    this.isShadowBanned = false,
  });

  User copyWith({
    String? bio,
    String? avatarUrl,
    String? location,
    String? profileTagline,
  }) =>
      User(
        id: id,
        username: username,
        bio: bio ?? this.bio,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        location: location ?? this.location,
        profileTagline: profileTagline ?? this.profileTagline,
        personaSpecialty: personaSpecialty,
        profileTraits: profileTraits,
        reliabilityScore: reliabilityScore,
        role: role,
        status: status,
        isAiPersona: isAiPersona,
        isShadowBanned: isShadowBanned,
      );

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as int,
        username: j['username'] as String,
        bio: j['bio'] as String?,
        avatarUrl: j['avatarUrl'] as String?,
        location: j['location'] as String?,
        profileTagline: j['profileTagline'] as String?,
        personaSpecialty: j['personaSpecialty'] as String?,
        profileTraits: (j['profileTraits'] as List?)?.cast<String>(),
        reliabilityScore: (j['reliabilityScore'] as int?) ?? 0,
        role: (j['role'] as String?) ?? 'user',
        status: (j['status'] as String?) ?? 'active',
        isAiPersona: (j['isAiPersona'] as bool?) ?? false,
        isShadowBanned: (j['isShadowBanned'] as bool?) ?? false,
      );
}
