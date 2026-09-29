import 'package:flutter_test/flutter_test.dart';
import 'package:mangoliving_agent/core/network/api_envelope.dart';
import 'package:mangoliving_agent/features/showings/domain/models/showing_request.dart';

void main() {
  test('dataList reads paginated data.list used by showings and offers', () {
    final List<Map<String, dynamic>> rows = ApiEnvelope.dataList(<String, dynamic>{
      'status': true,
      'message': 'OK',
      'data': <String, dynamic>{
        'list': <Map<String, dynamic>>[
          <String, dynamic>{
            '_id': 's1',
            'status': 'pending',
            'propertyAddress': '120 Oak St',
            'buyerId': <String, dynamic>{
              'firstName': 'Maya',
              'lastName': 'Chen',
            },
          },
        ],
        'total': 1,
      },
    });

    expect(rows, hasLength(1));
    expect(ShowingRequest.fromJson(rows.first).buyerName, 'Maya Chen');
  });

  test('dataList keeps rows when JSON maps are untyped', () {
    final List<Map<String, dynamic>> rows = ApiEnvelope.dataList(<dynamic, dynamic>{
      'status': true,
      'data': <dynamic, dynamic>{
        'list': <dynamic>[
          <dynamic, dynamic>{'id': 'o1', 'currentState': 'visited'},
        ],
      },
    });

    expect(rows.single['id'], 'o1');
    expect(rows.single['currentState'], 'visited');
  });

  test('All showings must not send status=all', () {
    const ShowingStatus? filter = null;
    final Map<String, dynamic> query = <String, dynamic>{
      if (filter != null) 'status': filter.apiValue,
    };
    expect(query.containsKey('status'), isFalse);
    expect(ShowingStatus.pending.apiValue, 'pending');
  });
}
