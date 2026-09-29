/// Role names that may open the agent dashboard (web `isAgentPanelRole`).
const Set<String> agentPanelRoles = <String>{
  'agent',
  'super_admin',
  'sub_super_admin',
};

bool isAgentPanelRole(String? roleName) {
  return agentPanelRoles.contains((roleName ?? '').trim().toLowerCase());
}

final class AgentUser {
  const AgentUser({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.photoUrl,
    this.roleName,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? photoUrl;
  final String? roleName;

  String get displayName {
    final String combined =
        '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (combined.isNotEmpty) return combined;
    return email;
  }

  String get firstDisplayName {
    final String first = (firstName ?? '').trim();
    if (first.isNotEmpty) return first;
    if (email.trim().isNotEmpty) return email.trim();
    return 'there';
  }

  String get initials {
    final String first = (firstName ?? '').trim();
    final String last = (lastName ?? '').trim();
    if (first.isNotEmpty && last.isNotEmpty) {
      return '${first[0]}${last[0]}'.toUpperCase();
    }
    if (first.isNotEmpty) return first[0].toUpperCase();
    if (email.isNotEmpty) return email[0].toUpperCase();
    return 'A';
  }

  bool get canAccessAgentPanel => isAgentPanelRole(roleName);

  AgentUser copyWith({
    String? firstName,
    String? lastName,
    String? photoUrl,
    String? roleName,
  }) {
    return AgentUser(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photoUrl: photoUrl ?? this.photoUrl,
      roleName: roleName ?? this.roleName,
    );
  }

  factory AgentUser.fromJson(Map<String, dynamic> json) {
    final dynamic role = json['role'];
    String? roleName;
    if (role is Map<String, dynamic>) {
      roleName = (role['name'] ?? role['roleName']) as String?;
    } else if (role is String) {
      roleName = role;
    }

    return AgentUser(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      email: (json['email'] as String?) ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      roleName: roleName,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      '_id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'photoUrl': photoUrl,
      'role': <String, dynamic>{'name': roleName},
    };
  }
}

final class AgentSession {
  const AgentSession({required this.token, required this.user});

  final String token;
  final AgentUser user;
}
