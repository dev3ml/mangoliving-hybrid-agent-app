/// Secure-storage keys for the agent session.
abstract final class StorageKeys {
  static const String accessToken = 'agent.accessToken';
  static const String cachedUser = 'agent.cachedUser';
  static const String notificationsLastReadAt = 'agent.notifications.lastReadAt';
  static const String themeMode = 'agent.themeMode';

  /// Separate from the agent session so role switches do not collide.
  static const String inspectorAccessToken = 'inspector.accessToken';
  static const String inspectorCachedSession = 'inspector.cachedSession';
}
