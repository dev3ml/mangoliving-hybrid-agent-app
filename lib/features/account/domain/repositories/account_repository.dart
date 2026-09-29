import '../models/agent_profile.dart';

typedef ProfileUploadResult = ({String? url, AgentProfile? profile});

abstract interface class AccountRepository {
  Future<AgentProfile> getProfile();

  Future<AgentProfile> updateProfile(Map<String, dynamic> body);

  Future<ProfileUploadResult> uploadPhoto(String path);

  Future<ProfileUploadResult> uploadVideo(String path);

  Future<ProfileUploadResult> uploadLogo(String path);

  Future<void> deleteAccount();
}
