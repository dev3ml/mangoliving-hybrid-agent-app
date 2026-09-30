import 'dart:convert';

import '../router/app_routes.dart';

/// Where a push payload should open in the agent app.
final class AgentPushTarget {
  const AgentPushTarget({required this.location, this.replace = false});

  /// `null` means the tap should not navigate.
  final String? location;

  /// Shell tabs use [GoRouter.go]. A chat thread uses [GoRouter.push].
  final bool replace;

  static const AgentPushTarget none = AgentPushTarget(location: null);

  factory AgentPushTarget.fromPayload(String payload) {
    final String trimmed = payload.trim();
    if (trimmed.isEmpty) return none;
    // Older local notifications stored a raw conversation id.
    if (!trimmed.startsWith('{')) {
      return AgentPushTarget(location: AppRoutes.messageThread(trimmed));
    }
    try {
      final Object? decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        return AgentPushTarget.fromData(decoded);
      }
      if (decoded is Map) {
        return AgentPushTarget.fromData(Map<String, dynamic>.from(decoded));
      }
    } on Object {
      return AgentPushTarget(location: AppRoutes.messageThread(trimmed));
    }
    return none;
  }

  factory AgentPushTarget.fromData(Map<String, dynamic> data) {
    final String type = data['type']?.toString() ?? '';
    if (type == 'buyer_chat' || type == 'agent_chat') {
      return _chat(data);
    }
    if (type == 'showing_request') {
      return const AgentPushTarget(location: AppRoutes.showings, replace: true);
    }
    if (type == 'campaign') {
      return _campaign(data);
    }
    final String link = (data['link'] ?? data['screen'] ?? '').toString();
    if (link.isEmpty) return none;
    return _fromLink(link, data);
  }

  static AgentPushTarget _chat(Map<String, dynamic> data) {
    final String agentClientId = data['agentClientId']?.toString() ?? '';
    if (agentClientId.isEmpty) {
      return const AgentPushTarget(location: AppRoutes.messages, replace: true);
    }
    return AgentPushTarget(location: AppRoutes.messageThread(agentClientId));
  }

  static AgentPushTarget _campaign(Map<String, dynamic> data) {
    final String screen = (data['screen']?.toString() ?? '').toLowerCase();
    switch (screen) {
      case 'messages':
        return _chat(data);
      case 'clients':
        return const AgentPushTarget(location: AppRoutes.clients, replace: true);
      case 'showings':
      case 'showing-requests':
        return const AgentPushTarget(
          location: AppRoutes.showings,
          replace: true,
        );
      case 'analytics':
        return const AgentPushTarget(location: AppRoutes.analytics);
      case 'offers':
        return const AgentPushTarget(location: AppRoutes.offers);
      case 'overview':
      case 'home':
        return const AgentPushTarget(
          location: AppRoutes.overview,
          replace: true,
        );
      default:
        if (screen.isEmpty) {
          return const AgentPushTarget(
            location: AppRoutes.overview,
            replace: true,
          );
        }
        return _fromLink(screen, data);
    }
  }

  static AgentPushTarget _fromLink(String link, Map<String, dynamic> data) {
    final String path = link.toLowerCase();
    if (path.contains('showing')) {
      return const AgentPushTarget(location: AppRoutes.showings, replace: true);
    }
    if (path.contains('message')) return _chat(data);
    if (path.contains('analytic')) {
      return const AgentPushTarget(location: AppRoutes.analytics);
    }
    if (path.contains('offer')) {
      return const AgentPushTarget(location: AppRoutes.offers);
    }
    if (path.contains('client')) {
      return const AgentPushTarget(location: AppRoutes.clients, replace: true);
    }
    return const AgentPushTarget(location: AppRoutes.overview, replace: true);
  }
}
