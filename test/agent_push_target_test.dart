import 'package:flutter_test/flutter_test.dart';
import 'package:mangoliving_agent/core/push/agent_push_target.dart';
import 'package:mangoliving_agent/core/router/app_routes.dart';

void main() {
  test('buyer chat opens the matching thread', () {
    final AgentPushTarget target = AgentPushTarget.fromData(<String, dynamic>{
      'type': 'buyer_chat',
      'agentClientId': 'thread-1',
    });

    expect(target.location, AppRoutes.messageThread('thread-1'));
    expect(target.replace, isFalse);
  });

  test('chat without a thread id opens the messages tab', () {
    final AgentPushTarget target = AgentPushTarget.fromData(<String, dynamic>{
      'type': 'agent_chat',
    });

    expect(target.location, AppRoutes.messages);
    expect(target.replace, isTrue);
  });

  test('showing and open house requests open the showings tab', () {
    for (final String type in <String>['showing_request', 'open_house_request']) {
      final AgentPushTarget target = AgentPushTarget.fromData(<String, dynamic>{
        'type': type,
      });
      expect(target.location, AppRoutes.showings);
      expect(target.replace, isTrue);
    }
  });

  test('client activity opens the clients tab', () {
    for (final String type in <String>[
      'add_request',
      'buyer_interest',
      'invite_accepted',
    ]) {
      expect(
        AgentPushTarget.fromData(<String, dynamic>{'type': type}).location,
        AppRoutes.clients,
      );
    }
  });

  test('offer and stage pushes open offers or clients', () {
    expect(
      AgentPushTarget.fromData(<String, dynamic>{'type': 'offer_request'}).location,
      AppRoutes.offers,
    );
    expect(
      AgentPushTarget.fromData(<String, dynamic>{
        'type': 'stage_change',
        'link': '/offers',
      }).location,
      AppRoutes.offers,
    );
    expect(
      AgentPushTarget.fromData(<String, dynamic>{
        'type': 'stage_change',
        'link': '/clients',
      }).location,
      AppRoutes.clients,
    );
    expect(
      AgentPushTarget.fromData(<String, dynamic>{
        'type': 'actions_panel_reminder',
      }).location,
      AppRoutes.clients,
    );
  });

  test('campaign screens map onto agent routes', () {
    expect(
      AgentPushTarget.fromData(<String, dynamic>{
        'type': 'campaign',
        'screen': 'clients',
      }).location,
      AppRoutes.clients,
    );
    expect(
      AgentPushTarget.fromData(<String, dynamic>{
        'type': 'campaign',
        'screen': 'analytics',
      }).location,
      AppRoutes.analytics,
    );
    expect(
      AgentPushTarget.fromData(<String, dynamic>{
        'type': 'campaign',
        'screen': 'messages',
        'agentClientId': 'abc',
      }).location,
      AppRoutes.messageThread('abc'),
    );
  });

  test('json payload and a raw thread id both resolve', () {
    final AgentPushTarget fromJson = AgentPushTarget.fromPayload(
      '{"type":"buyer_chat","agentClientId":"abc/1"}',
    );
    expect(fromJson.location, AppRoutes.messageThread('abc/1'));

    final AgentPushTarget raw = AgentPushTarget.fromPayload('legacy-id');
    expect(raw.location, AppRoutes.messageThread('legacy-id'));
  });

  test('empty payload does not navigate', () {
    expect(AgentPushTarget.fromPayload('   ').location, isNull);
    expect(AgentPushTarget.fromData(<String, dynamic>{}).location, isNull);
  });
}
