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

  factory User.fromJson(Map<String, dynamic> j) => User(
        id: j['id'] as int,
        username: j['username'] as String,
        bio: j['bio'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        location: j['location'] as String?,
        profileTagline: j['profile_tagline'] as String?,
        personaSpecialty: j['persona_specialty'] as String?,
        profileTraits: (j['profile_traits'] as List?)?.cast<String>(),
        reliabilityScore: (j['reliability_score'] as int?) ?? 0,
        role: (j['role'] as String?) ?? 'user',
        status: (j['status'] as String?) ?? 'active',
        isAiPersona: (j['is_ai_persona'] as bool?) ?? false,
        isShadowBanned: (j['is_shadow_banned'] as bool?) ?? false,
      );
}
