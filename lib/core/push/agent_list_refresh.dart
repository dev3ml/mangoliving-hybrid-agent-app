import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/domain/models/agent_user.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/clients/presentation/controllers/clients_controller.dart';
import '../../features/messages/presentation/controllers/chat_messages_controller.dart';
import '../../features/messages/presentation/controllers/chat_threads_controller.dart';
import '../../features/offers/presentation/controllers/offers_controller.dart';
import '../../features/showings/presentation/controllers/showings_controller.dart';

const Set<String> _clientListTypes = <String>{
  'add_request',
  'client_request',
  'buyer_interest',
  'invite_accepted',
  'invite_declined',
  'relation_revoked',
  'stage_change',
  'actions_panel_reminder',
};

const Set<String> _showingListTypes = <String>{
  'showing_request',
  'open_house_request',
};

const Set<String> _offerListTypes = <String>{
  'offer_request',
  'stage_change',
  'actions_panel_reminder',
};

const Set<String> _chatListTypes = <String>{
  'buyer_chat',
  'agent_chat',
};

/// Reloads the lists the web can change while this app is open.
///
/// An empty [type] reloads clients, showings, offers, and messages. A known type
/// reloads only the list that shows that event.
Future<void> refreshAgentLists(Ref ref, {String type = ''}) async {
  final bool signedIn = ref.read(authControllerProvider).maybeWhen(
        data: (AgentSession? session) => session != null,
        orElse: () => false,
      );
  if (!signedIn) return;
  final bool all = type.isEmpty;
  final List<Future<void>> jobs = <Future<void>>[];
  if (all || _clientListTypes.contains(type)) {
    jobs.add(ref.read(clientsControllerProvider.notifier).refresh());
  }
  if (all || _showingListTypes.contains(type)) {
    jobs.add(ref.read(showingsControllerProvider.notifier).refresh());
  }
  if (all || _offerListTypes.contains(type)) {
    jobs.add(ref.read(offersControllerProvider.notifier).refresh());
  }
  if (all || _chatListTypes.contains(type)) {
    jobs.add(ref.read(chatThreadsControllerProvider.notifier).refresh());
    final String? openId = ref.read(activeChatThreadIdProvider);
    if (openId != null && openId.isNotEmpty) {
      jobs.add(ref.read(chatMessagesControllerProvider(openId).notifier).refresh());
    }
  }
  if (jobs.isEmpty) return;
  await Future.wait(jobs);
}
