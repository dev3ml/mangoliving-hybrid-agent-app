import '../models/chat_message.dart';
import '../models/chat_thread.dart';

abstract interface class MessagesRepository {
  Future<List<ChatThread>> listThreads();

  Future<List<ChatMessage>> listMessages(String agentClientId);

  Future<ChatMessage> sendMessage(String agentClientId, String text);

  Future<void> markRead(String agentClientId);
}
