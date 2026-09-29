import '../models/overview_snapshot.dart';

abstract interface class OverviewRepository {
  Future<OverviewSnapshot> load();

  Future<void> markNotificationsRead(String iso);

  Future<DateTime?> lastReadAt();
}
