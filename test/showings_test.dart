import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangoliving_agent/features/showings/domain/models/showing_request.dart';
import 'package:mangoliving_agent/features/showings/presentation/controllers/showings_controller.dart';
import 'package:mangoliving_agent/features/showings/presentation/pages/showings_page.dart';

class _FakeShowingsController extends ShowingsController {
  @override
  Future<ShowingsViewData> build() async {
    return ShowingsViewData(
      requests: <ShowingRequest>[
        const ShowingRequest(
          id: 's1',
          buyerName: 'Maya Chen',
          status: 'pending',
          propertyAddress: '120 Oak St',
          propertyCity: 'Frisco',
          message: 'Sunday afternoon?',
          createdAt: '2026-09-20T09:10:00.000Z',
        ),
        ShowingRequest(
          id: 's2',
          buyerName: 'Alex Rivera',
          status: 'scheduled',
          propertyAddress: '88 Main',
          scheduledAt: DateTime(2026, 9, 21, 14).toIso8601String(),
        ),
      ],
    );
  }
}

void main() {
  test('counts roll cancelled and declined together', () {
    final ShowingCounts counts = ShowingCounts.from(const <ShowingRequest>[
      ShowingRequest(id: '1', buyerName: 'A', status: 'pending'),
      ShowingRequest(id: '2', buyerName: 'B', status: 'scheduled'),
      ShowingRequest(id: '3', buyerName: 'C', status: 'completed'),
      ShowingRequest(id: '4', buyerName: 'D', status: 'cancelled'),
      ShowingRequest(id: '5', buyerName: 'E', status: 'declined'),
    ]);
    expect(counts.total, 5);
    expect(counts.pending, 1);
    expect(counts.scheduled, 1);
    expect(counts.completed, 1);
    expect(counts.cancelled, 2);
  });

  test('schedule validation requires a future datetime', () {
    final DateTime now = DateTime(2026, 9, 20, 12);
    expect(
      ShowingSchedule.validate(date: null, time: const TimeParts(10, 0), now: now),
      'Pick a visit date first.',
    );
    expect(
      ShowingSchedule.validate(
        date: DateTime(2026, 9, 20),
        time: const TimeParts(10, 0),
        now: now,
      ),
      'Please choose a future date and time for the visit.',
    );
    expect(
      ShowingSchedule.validate(
        date: DateTime(2026, 9, 21),
        time: const TimeParts(10, 0),
        now: now,
      ),
      isNull,
    );
  });

  test('reschedule is allowed for scheduled, cancelled, and declined', () {
    expect(
      const ShowingRequest(id: '1', buyerName: 'A', status: 'scheduled')
          .canReschedule,
      isTrue,
    );
    expect(
      const ShowingRequest(id: '2', buyerName: 'A', status: 'cancelled')
          .canReschedule,
      isTrue,
    );
    expect(
      const ShowingRequest(id: '3', buyerName: 'A', status: 'pending')
          .canReschedule,
      isFalse,
    );
    expect(
      const ShowingRequest(id: '4', buyerName: 'A', status: 'pending').canDecline,
      isTrue,
    );
  });

  testWidgets('Showings list renders pending actions and subtitle', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          showingsControllerProvider.overrideWith(_FakeShowingsController.new),
        ],
        child: const MaterialApp(home: ShowingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Manage tour requests from buyers connected to you.'),
      findsOneWidget,
    );
    expect(find.text('Maya Chen'), findsOneWidget);
    expect(find.text('120 Oak St'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Decline'), findsOneWidget);
    expect(find.text('Alex Rivera'), findsOneWidget);
    expect(find.text('Reschedule'), findsOneWidget);
  });
}
