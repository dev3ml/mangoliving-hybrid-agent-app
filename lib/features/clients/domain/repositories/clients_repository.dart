import '../models/client_conversation.dart';
import '../models/criteria_history.dart';
import '../models/managed_client.dart';
import '../roster_merge.dart';

abstract interface class ClientsRepository {
  Future<ClientRoster> load();

  Future<ManagedClient> create({
    required String email,
    String? name,
    String? phone,
    bool sendInvitation = true,
  });

  Future<void> delete(String managedId);

  Future<void> resendInvite(String managedId);

  Future<void> accept(String managedId);

  Future<void> decline(String managedId);

  Future<ClientConversation?> conversation(String id);

  Future<List<CriteriaHistoryEntry>> criteriaHistory(String buyerId);
}
