import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangoliving_agent/features/offers/domain/models/property_action.dart';
import 'package:mangoliving_agent/features/offers/presentation/controllers/offers_controller.dart';
import 'package:mangoliving_agent/features/offers/presentation/pages/offers_page.dart';

PropertyAction _row({
  String id = 'o1',
  String state = 'visited',
  String? status,
  String first = 'Maya',
  String last = 'Chen',
  String street = '120 Oak St; extra',
  num? amount,
}) {
  return PropertyAction(
    id: id,
    buyerId: 'b1',
    propertyId: 'p1',
    currentState: state,
    agentName: 'Jordan Lee',
    property: OfferProperty(streetAddress: street, city: 'Frisco', listPrice: 625000),
    buyer: OfferBuyer(firstName: first, lastName: last, email: 'maya@example.com'),
    offer: status == null && amount == null
        ? null
        : OfferDetails(
            offerStatus: OfferStatusX.tryParse(status),
            offerAmount: amount,
            offerSentAt: '2026-09-18T16:02:00.000Z',
            inspectionPeriodDays: 7,
          ),
  );
}

class _FakeOffersController extends OffersController {
  _FakeOffersController(this.initial);

  final OffersViewData initial;

  @override
  Future<OffersViewData> build() async => initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(
      fileInput: '''
API_BASE_URL=https://example.test/api
''',
    );
  });

  test('buyer name, street, money, and rejected badge', () {
    final PropertyAction visited = _row();
    expect(visited.buyerName, 'Maya Chen');
    expect(visited.streetLine, '120 Oak St');
    expect(visited.stageLabel, 'Visited');
    expect(visited.canPrepare, isTrue);
    expect(OfferMoney.format(585000), r'$585,000');
    expect(OfferMoney.format(null), '—');

    final PropertyAction rejected = _row(
      state: 'offer_placed',
      status: 'rejected',
      amount: 610000,
    );
    expect(rejected.stageLabel, 'Offer rejected');
    expect(rejected.canSendAgain, isTrue);
    expect(rejected.canView, isFalse);
    expect(rejected.amountLabel, r'$610,000');

    final PropertyAction placed = _row(
      state: 'offer_placed',
      status: 'sent',
      amount: 610000,
    );
    expect(placed.canView, isTrue);
    expect(placed.canUpdate, isTrue);
    expect(placed.canMarkDecision, isTrue);
  });

  test('inspection text rewrites only the default sentence', () {
    final OfferPdfForm form = OfferPdfForm.empty();
    expect(form.inspectionText, OfferPdfForm.defaultInspectionText(7));
    final OfferPdfForm next = form.withInspectionDays('10');
    expect(next.inspectionText, OfferPdfForm.defaultInspectionText(10));

    final OfferPdfForm custom = form.copyWith(inspectionText: 'Buyer waiver.');
    expect(custom.withInspectionDays('14').inspectionText, 'Buyer waiver.');
  });

  test('prepare validation and write body', () {
    final OfferPdfForm invalid = OfferPdfForm.empty();
    expect(invalid.amountError, 'Enter a valid offer amount.');
    expect(
      invalid.copyWith(inspectionPeriodDays: '0').daysError,
      'Inspection period must be at least 1 day.',
    );

    final OfferPdfForm valid = OfferPdfForm.empty().copyWith(
      offerAmount: '610000',
      listPrice: '625000',
      buyerName: 'Maya Chen',
      notes: '  cash  ',
    );
    expect(valid.amountError, isNull);
    expect(valid.daysError, isNull);
    expect(valid.toWriteBody()['offerAmount'], 610000);
    expect(valid.toWriteBody()['listPrice'], 625000);
    expect(valid.toWriteBody()['notes'], 'cash');
  });

  test('PDF url prefixes api host for stored filenames', () {
    expect(
      OfferPdfUrl.resolve('/somewhere/offer-file.pdf', cacheBust: 'abc'),
      'https://example.test/api/uploads/offers/offer-file.pdf?t=abc',
    );
    expect(OfferPdfUrl.resolve('https://cdn.test/not-a-pdf'), 'https://cdn.test/not-a-pdf');
  });

  test('counts from loaded list', () {
    final OfferCounts counts = OfferCounts.from(<PropertyAction>[
      _row(id: '1', state: 'visited'),
      _row(id: '2', state: 'offer_placed', status: 'sent', amount: 1),
      _row(id: '3', state: 'offer_accepted', status: 'accepted', amount: 2),
    ]);
    expect(counts.total, 3);
    expect(counts.visited, 1);
    expect(counts.offerPlaced, 1);
    expect(counts.offerAccepted, 1);
  });

  testWidgets('Offers list shows cards and prepare action', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          offersControllerProvider.overrideWith(
            () => _FakeOffersController(
              OffersViewData(
                rows: <PropertyAction>[
                  _row(),
                  _row(
                    id: 'o2',
                    first: 'Alex',
                    last: 'Rivera',
                    street: '88 Main',
                    state: 'offer_placed',
                    status: 'sent',
                    amount: 610000,
                  ),
                ],
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: OffersPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Prepare, send, and update offers for buyers connected to you.'),
      findsOneWidget,
    );
    expect(find.text('Maya Chen · 120 Oak St'), findsOneWidget);
    expect(find.text('Prepare offer'), findsOneWidget);
    expect(find.text('View offer'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
  });

  testWidgets('empty offers copy', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          offersControllerProvider.overrideWith(
            () => _FakeOffersController(const OffersViewData(rows: <PropertyAction>[])),
          ),
        ],
        child: const MaterialApp(home: OffersPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No offer-stage properties yet.'), findsOneWidget);
  });
}
