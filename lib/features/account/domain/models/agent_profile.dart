import '../../../../core/constants/env_config.dart';
import '../../../auth/domain/models/agent_user.dart';

const List<String> profileLanguages = <String>[
  'English',
  'Spanish',
  'Mandarin',
  'Cantonese',
  'Hindi',
  'Punjabi',
  'Urdu',
  'Arabic',
  'French',
  'German',
  'Portuguese',
  'Vietnamese',
  'Korean',
  'Japanese',
  'Tagalog',
  'Russian',
];

enum VideoIntroStatus { none, pending, approved, rejected }

final class AgentProfile {
  const AgentProfile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.mobileNumber,
    this.licenseNumber,
    this.description,
    this.photoUrl,
    this.videoIntroUrl,
    this.videoIntroStatus = VideoIntroStatus.none,
    this.brokerageName,
    this.brokerageLogoUrl,
    this.languages = const <String>[],
    this.publicSlug,
    this.publicProfileVisible = true,
    this.listAgentKeyNumeric,
    this.listAgentMlsId,
  });

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? mobileNumber;
  final String? licenseNumber;
  final String? description;
  final String? photoUrl;
  final String? videoIntroUrl;
  final VideoIntroStatus videoIntroStatus;
  final String? brokerageName;
  final String? brokerageLogoUrl;
  final List<String> languages;
  final String? publicSlug;
  final bool publicProfileVisible;
  final num? listAgentKeyNumeric;
  final num? listAgentMlsId;

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();

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

  bool get hasPhoto => (photoUrl ?? '').trim().isNotEmpty;
  bool get hasBio => (description ?? '').trim().isNotEmpty;
  bool get hasVideo => (videoIntroUrl ?? '').trim().isNotEmpty;
  bool get hasBrokerage => (brokerageName ?? '').trim().isNotEmpty;
  bool get hasBasicInfo =>
      fullName.isNotEmpty && email.trim().isNotEmpty && (mobileNumber ?? '').trim().isNotEmpty;

  int get completedChecks {
    int count = 0;
    if (hasBasicInfo) count += 1;
    if (hasPhoto) count += 1;
    if (hasBio) count += 1;
    if (hasVideo) count += 1;
    if (hasBrokerage) count += 1;
    return count;
  }

  int get completionPercent => ((completedChecks / 5) * 100).round();

  String? get publicPathId {
    final String slug = (publicSlug ?? '').trim();
    if (slug.isNotEmpty) return slug;
    if (id.trim().isNotEmpty) return id;
    return null;
  }

  String? get publicUrl {
    final String? pathId = publicPathId;
    if (pathId == null) return null;
    final String origin = EnvConfig.buyerAppUrl.replaceAll(RegExp(r'/$'), '');
    return '$origin/agent/$pathId';
  }

  AgentUser get asUser => AgentUser(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        photoUrl: photoUrl,
      );

  AgentProfile copyWith({
    String? firstName,
    String? lastName,
    String? mobileNumber,
    String? licenseNumber,
    String? description,
    String? photoUrl,
    String? videoIntroUrl,
    bool clearVideo = false,
    VideoIntroStatus? videoIntroStatus,
    String? brokerageName,
    String? brokerageLogoUrl,
    List<String>? languages,
    String? publicSlug,
    bool? publicProfileVisible,
    num? listAgentKeyNumeric,
    num? listAgentMlsId,
    bool clearMlsKey = false,
    bool clearMlsId = false,
  }) {
    return AgentProfile(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      videoIntroUrl: clearVideo ? null : (videoIntroUrl ?? this.videoIntroUrl),
      videoIntroStatus: videoIntroStatus ?? this.videoIntroStatus,
      brokerageName: brokerageName ?? this.brokerageName,
      brokerageLogoUrl: brokerageLogoUrl ?? this.brokerageLogoUrl,
      languages: languages ?? this.languages,
      publicSlug: publicSlug ?? this.publicSlug,
      publicProfileVisible: publicProfileVisible ?? this.publicProfileVisible,
      listAgentKeyNumeric:
          clearMlsKey ? null : (listAgentKeyNumeric ?? this.listAgentKeyNumeric),
      listAgentMlsId: clearMlsId ? null : (listAgentMlsId ?? this.listAgentMlsId),
    );
  }

  factory AgentProfile.fromJson(Map<String, dynamic> json) {
    final List<String> languages = <String>[];
    final dynamic rawLang = json['languages'];
    if (rawLang is List) {
      languages.addAll(rawLang.map((dynamic e) => e.toString()));
    }
    return AgentProfile(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      email: (json['email'] as String?) ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      mobileNumber: json['mobileNumber'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      description: json['description'] as String?,
      photoUrl: json['photoUrl'] as String?,
      videoIntroUrl: json['videoIntroUrl'] as String?,
      videoIntroStatus: _status(json['videoIntroStatus'] as String?),
      brokerageName: json['brokerageName'] as String?,
      brokerageLogoUrl: json['brokerageLogoUrl'] as String?,
      languages: languages,
      publicSlug: json['publicSlug'] as String?,
      publicProfileVisible: json['publicProfileVisible'] != false,
      listAgentKeyNumeric: json['listAgentKeyNumeric'] as num?,
      listAgentMlsId: json['listAgentMlsId'] as num?,
    );
  }

  static VideoIntroStatus _status(String? raw) {
    return VideoIntroStatus.values.firstWhere(
      (VideoIntroStatus s) => s.name == raw,
      orElse: () => VideoIntroStatus.none,
    );
  }
}

final class AccountDraft {
  const AccountDraft({
    required this.name,
    required this.phone,
    required this.license,
    required this.bio,
    required this.languages,
    required this.brokerageName,
    required this.publicProfileVisible,
    required this.listAgentKeyNumeric,
    required this.listAgentMlsId,
  });

  final String name;
  final String phone;
  final String license;
  final String bio;
  final List<String> languages;
  final String brokerageName;
  final bool publicProfileVisible;
  final String listAgentKeyNumeric;
  final String listAgentMlsId;

  factory AccountDraft.fromProfile(AgentProfile profile) {
    return AccountDraft(
      name: profile.fullName,
      phone: profile.mobileNumber ?? '',
      license: profile.licenseNumber ?? '',
      bio: profile.description ?? '',
      languages: List<String>.from(profile.languages),
      brokerageName: profile.brokerageName ?? '',
      publicProfileVisible: profile.publicProfileVisible,
      listAgentKeyNumeric: profile.listAgentKeyNumeric?.toString() ?? '',
      listAgentMlsId: profile.listAgentMlsId?.toString() ?? '',
    );
  }

  int completedChecks(AgentProfile profile) {
    int count = 0;
    if (name.trim().isNotEmpty &&
        profile.email.trim().isNotEmpty &&
        phone.trim().isNotEmpty) {
      count += 1;
    }
    if (profile.hasPhoto) count += 1;
    if (bio.trim().isNotEmpty) count += 1;
    if (profile.hasVideo) count += 1;
    if (brokerageName.trim().isNotEmpty) count += 1;
    return count;
  }

  int completionPercent(AgentProfile profile) =>
      ((completedChecks(profile) / 5) * 100).round();

  Map<String, dynamic> toPatch() {
    final ({String firstName, String lastName}) names = splitName(name);
    if (listAgentKeyNumeric.trim().isNotEmpty &&
        parseMls(listAgentKeyNumeric) == null) {
      throw const FormatException('MLS fields must be numbers.');
    }
    if (listAgentMlsId.trim().isNotEmpty && parseMls(listAgentMlsId) == null) {
      throw const FormatException('MLS fields must be numbers.');
    }
    return <String, dynamic>{
      'firstName': names.firstName,
      'lastName': names.lastName,
      'mobileNumber': phone.trim(),
      'licenseNumber': license.trim(),
      'description': bio,
      'languages': languages,
      'brokerageName': brokerageName.trim(),
      'publicProfileVisible': publicProfileVisible,
      'listAgentKeyNumeric': parseMls(listAgentKeyNumeric),
      'listAgentMlsId': parseMls(listAgentMlsId),
    };
  }

  bool sameAs(AccountDraft other) {
    return name == other.name &&
        phone == other.phone &&
        license == other.license &&
        bio == other.bio &&
        brokerageName == other.brokerageName &&
        publicProfileVisible == other.publicProfileVisible &&
        listAgentKeyNumeric == other.listAgentKeyNumeric &&
        listAgentMlsId == other.listAgentMlsId &&
        _sameList(languages, other.languages);
  }

  static ({String firstName, String lastName}) splitName(String raw) {
    final List<String> parts =
        raw.trim().split(RegExp(r'\s+')).where((String p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return (firstName: '', lastName: '');
    if (parts.length == 1) return (firstName: parts.first, lastName: '');
    return (
      firstName: parts.first,
      lastName: parts.sublist(1).join(' '),
    );
  }

  static num? parseMls(String raw) {
    final String value = raw.trim();
    if (value.isEmpty) return null;
    return num.tryParse(value);
  }

  AccountDraft copyWith({
    String? name,
    String? phone,
    String? license,
    String? bio,
    List<String>? languages,
    String? brokerageName,
    bool? publicProfileVisible,
    String? listAgentKeyNumeric,
    String? listAgentMlsId,
  }) {
    return AccountDraft(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      license: license ?? this.license,
      bio: bio ?? this.bio,
      languages: languages ?? this.languages,
      brokerageName: brokerageName ?? this.brokerageName,
      publicProfileVisible: publicProfileVisible ?? this.publicProfileVisible,
      listAgentKeyNumeric: listAgentKeyNumeric ?? this.listAgentKeyNumeric,
      listAgentMlsId: listAgentMlsId ?? this.listAgentMlsId,
    );
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

abstract final class PasswordRules {
  static String? validateNew(String password) {
    if (password.length < 8) {
      return 'New password is too weak. Use at least 8 characters with mixed case, a number, and a symbol.';
    }
    final bool mixed = password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[A-Z]'));
    final bool number = password.contains(RegExp(r'\d'));
    final bool symbol = password.contains(RegExp(r'[^A-Za-z0-9]'));
    if (!mixed || !number || !symbol) {
      return 'New password is too weak. Use at least 8 characters with mixed case, a number, and a symbol.';
    }
    return null;
  }
}

abstract final class DeleteConfirm {
  static const String phrase = 'DELETE';

  static bool matches(String raw) => raw == phrase;
}

abstract final class MediaRules {
  static const int photoMaxBytes = 5 * 1024 * 1024;
  static const int videoMaxBytes = 50 * 1024 * 1024;
  static const int logoMaxBytes = 2 * 1024 * 1024;
  static const int videoMaxSeconds = 30;

  static const Set<String> photoExt = <String>{
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  };
  static const Set<String> videoExt = <String>{'mp4', 'mov', 'webm'};
  static const Set<String> logoExt = <String>{'jpg', 'jpeg', 'png', 'svg'};

  static String extensionOf(String path) {
    final int dot = path.lastIndexOf('.');
    if (dot < 0) return '';
    return path.substring(dot + 1).toLowerCase();
  }

  static String? photo(String path, int bytes) {
    if (!photoExt.contains(extensionOf(path))) {
      return 'Please upload a JPG, PNG, GIF, or WebP image';
    }
    if (bytes > photoMaxBytes) return 'Photo must be less than 5MB';
    return null;
  }

  static String? video(String path, int bytes) {
    if (!videoExt.contains(extensionOf(path))) {
      return 'Please upload a valid video file (MP4, MOV, or WebM)';
    }
    if (bytes > videoMaxBytes) {
      return 'Video file size must be less than 50MB';
    }
    return null;
  }

  static String? logo(String path, int bytes) {
    if (!logoExt.contains(extensionOf(path))) {
      return 'Please upload a JPG, PNG, or SVG image';
    }
    if (bytes > logoMaxBytes) return 'Logo must be less than 2MB';
    return null;
  }

  static String? videoDuration(Duration duration) {
    if (duration.inSeconds > videoMaxSeconds) {
      return 'Video must be 30 seconds or less';
    }
    return null;
  }
}
