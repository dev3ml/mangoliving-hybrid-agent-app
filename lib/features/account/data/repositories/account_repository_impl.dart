import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../domain/models/agent_profile.dart';
import '../../domain/repositories/account_repository.dart';
import '../datasources/account_remote_datasource.dart';

final accountRepositoryProvider = Provider<AccountRepository>((Ref ref) {
  return AccountRepositoryImpl(AccountRemoteDataSource(ref.watch(dioProvider)));
});

final class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._remote);

  final AccountRemoteDataSource _remote;

  @override
  Future<AgentProfile> getProfile() => _remote.getProfile();

  @override
  Future<AgentProfile> updateProfile(Map<String, dynamic> body) {
    return _remote.updateProfile(body);
  }

  @override
  Future<ProfileUploadResult> uploadPhoto(String path) =>
      _remote.uploadPhoto(path);

  @override
  Future<ProfileUploadResult> uploadVideo(String path) =>
      _remote.uploadVideo(path);

  @override
  Future<ProfileUploadResult> uploadLogo(String path) =>
      _remote.uploadLogo(path);

  @override
  Future<void> deleteAccount() => _remote.deleteAccount();
}
