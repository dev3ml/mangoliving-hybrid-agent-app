import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../auth/domain/models/agent_user.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../overview/presentation/controllers/overview_controller.dart';
import '../../data/repositories/account_repository_impl.dart';
import '../../domain/models/agent_profile.dart';
import '../../domain/repositories/account_repository.dart';

final accountControllerProvider =
    AsyncNotifierProvider<AccountController, AccountViewData>(
  AccountController.new,
);

enum AccountUploadKind { photo, video, logo }

final class AccountViewData {
  const AccountViewData({
    required this.profile,
    required this.draft,
    required this.baseline,
    this.saving = false,
    this.deleting = false,
    this.uploading,
  });

  final AgentProfile profile;
  final AccountDraft draft;
  final AccountDraft baseline;
  final bool saving;
  final bool deleting;
  final AccountUploadKind? uploading;

  bool get isDirty => !draft.sameAs(baseline);

  int get completedChecks => draft.completedChecks(profile);

  int get completionPercent => draft.completionPercent(profile);

  bool get busy => saving || deleting || uploading != null;

  AccountViewData copyWith({
    AgentProfile? profile,
    AccountDraft? draft,
    AccountDraft? baseline,
    bool? saving,
    bool? deleting,
    AccountUploadKind? uploading,
    bool clearUpload = false,
  }) {
    return AccountViewData(
      profile: profile ?? this.profile,
      draft: draft ?? this.draft,
      baseline: baseline ?? this.baseline,
      saving: saving ?? this.saving,
      deleting: deleting ?? this.deleting,
      uploading: clearUpload ? null : (uploading ?? this.uploading),
    );
  }
}

class AccountController extends AsyncNotifier<AccountViewData> {
  AccountRepository get _repo => ref.read(accountRepositoryProvider);

  @override
  Future<AccountViewData> build() async {
    final AgentProfile profile = await _repo.getProfile();
    final AccountDraft draft = AccountDraft.fromProfile(profile);
    return AccountViewData(profile: profile, draft: draft, baseline: draft);
  }

  Future<void> refresh() async {
    try {
      final AgentProfile profile = await _repo.getProfile();
      final AccountDraft draft = AccountDraft.fromProfile(profile);
      state = AsyncData<AccountViewData>(
        AccountViewData(profile: profile, draft: draft, baseline: draft),
      );
    } on Object catch (error, stackTrace) {
      if (!state.hasValue) {
        state = AsyncError<AccountViewData>(error, stackTrace);
      }
    }
  }

  void patchDraft(AccountDraft Function(AccountDraft current) update) {
    final AccountViewData? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData<AccountViewData>(
      current.copyWith(draft: update(current.draft)),
    );
  }

  void cancel() {
    final AccountViewData? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData<AccountViewData>(
      current.copyWith(draft: current.baseline),
    );
  }

  Future<void> save() async {
    final AccountViewData? current = state.valueOrNull;
    if (current == null || !current.isDirty) return;
    state = AsyncData<AccountViewData>(current.copyWith(saving: true));
    try {
      final AgentProfile profile = await _repo.updateProfile(current.draft.toPatch());
      await _syncSession(profile);
      state = AsyncData<AccountViewData>(
        AccountViewData(
          profile: profile,
          draft: AccountDraft.fromProfile(profile),
          baseline: AccountDraft.fromProfile(profile),
        ),
      );
    } on Object {
      final AccountViewData? latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncData<AccountViewData>(latest.copyWith(saving: false));
      }
      rethrow;
    }
  }

  Future<void> uploadPhoto(String path) {
    return _upload(
      kind: AccountUploadKind.photo,
      validate: () => _validateFile(path, MediaRules.photo),
      run: () => _repo.uploadPhoto(path),
      applyUrl: (AgentProfile profile, String url) =>
          profile.copyWith(photoUrl: url),
    );
  }

  Future<void> uploadLogo(String path) {
    return _upload(
      kind: AccountUploadKind.logo,
      validate: () => _validateFile(path, MediaRules.logo),
      run: () => _repo.uploadLogo(path),
      applyUrl: (AgentProfile profile, String url) =>
          profile.copyWith(brokerageLogoUrl: url),
    );
  }

  Future<void> uploadVideo(String path) {
    return _upload(
      kind: AccountUploadKind.video,
      validate: () async {
        final String? typeOrSize = await _validateFile(path, MediaRules.video);
        if (typeOrSize != null) return typeOrSize;
        final Duration? duration = await probeVideoDuration(path);
        if (duration == null) {
          return 'Please upload a valid video file (MP4, MOV, or WebM)';
        }
        return MediaRules.videoDuration(duration);
      },
      run: () => _repo.uploadVideo(path),
      applyUrl: (AgentProfile profile, String url) => profile.copyWith(
        videoIntroUrl: url,
        videoIntroStatus: VideoIntroStatus.pending,
      ),
    );
  }

  Future<void> removeVideo() async {
    final AccountViewData? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData<AccountViewData>(current.copyWith(saving: true));
    try {
      final AgentProfile profile = await _repo.updateProfile(
        <String, dynamic>{'videoIntroUrl': null},
      );
      await _syncSession(profile);
      final AgentProfile cleared = profile.copyWith(clearVideo: true);
      state = AsyncData<AccountViewData>(
        current.copyWith(
          profile: cleared,
          saving: false,
        ),
      );
    } on Object {
      final AccountViewData? latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncData<AccountViewData>(latest.copyWith(saving: false));
      }
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    final AccountViewData? current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData<AccountViewData>(current.copyWith(deleting: true));
    try {
      await _repo.deleteAccount();
      await ref.read(authControllerProvider.notifier).logout();
    } on Object {
      final AccountViewData? latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncData<AccountViewData>(latest.copyWith(deleting: false));
      }
      rethrow;
    }
  }

  Future<void> _upload({
    required AccountUploadKind kind,
    required Future<String?> Function() validate,
    required Future<ProfileUploadResult> Function() run,
    required AgentProfile Function(AgentProfile profile, String url) applyUrl,
  }) async {
    final AccountViewData? current = state.valueOrNull;
    if (current == null) return;
    final String? invalid = await validate();
    if (invalid != null) throw FormatException(invalid);
    state = AsyncData<AccountViewData>(current.copyWith(uploading: kind));
    try {
      final ProfileUploadResult result = await run();
      AgentProfile next = result.profile ?? current.profile;
      final String? url = result.url;
      if (result.profile == null && url != null && url.isNotEmpty) {
        next = applyUrl(next, url);
      }
      await _syncSession(next);
      state = AsyncData<AccountViewData>(
        current.copyWith(profile: next, clearUpload: true),
      );
    } on Object {
      final AccountViewData? latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncData<AccountViewData>(latest.copyWith(clearUpload: true));
      }
      rethrow;
    }
  }

  Future<String?> _validateFile(
    String path,
    String? Function(String path, int bytes) rule,
  ) async {
    final int bytes = await File(path).length();
    return rule(path, bytes);
  }

  Future<void> _syncSession(AgentProfile profile) async {
    final AgentSession? session = ref.read(authControllerProvider).valueOrNull;
    await ref.read(authControllerProvider.notifier).applyUser(
          profile.asUser.copyWith(roleName: session?.user.roleName),
        );
    await ref.read(overviewControllerProvider.notifier).refresh();
  }
}

Future<Duration?> probeVideoDuration(String path) async {
  final VideoPlayerController controller = VideoPlayerController.file(File(path));
  try {
    await controller.initialize();
    return controller.value.duration;
  } on Object {
    return null;
  } finally {
    await controller.dispose();
  }
}
