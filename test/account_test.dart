import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangoliving_agent/features/account/domain/models/agent_profile.dart';
import 'package:mangoliving_agent/features/account/presentation/controllers/account_controller.dart';
import 'package:mangoliving_agent/features/account/presentation/pages/account_page.dart';

AgentProfile _profile({
  String name = 'Alex Rivera',
  String email = 'alex@broker.com',
  String phone = '5550100',
  String? photo,
  String? bio,
  String? video,
  String? brokerage,
}) {
  final List<String> parts = name.split(' ');
  return AgentProfile(
    id: 'a1',
    email: email,
    firstName: parts.first,
    lastName: parts.length > 1 ? parts.sublist(1).join(' ') : null,
    mobileNumber: phone,
    description: bio,
    photoUrl: photo,
    videoIntroUrl: video,
    brokerageName: brokerage,
    publicSlug: 'alex-rivera',
  );
}

class _FakeAccountController extends AccountController {
  _FakeAccountController(this.initial);

  final AccountViewData initial;

  @override
  Future<AccountViewData> build() async => initial;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    dotenv.testLoad(
      fileInput: '''
BUYER_APP_URL=https://app.mangoliving.ai
API_BASE_URL=https://example.test/api
''',
    );
  });

  test('name split maps to first + remaining last', () {
    expect(AccountDraft.splitName('Alex Rivera Chen'), (
      firstName: 'Alex',
      lastName: 'Rivera Chen',
    ));
    expect(AccountDraft.splitName('Alex'), (firstName: 'Alex', lastName: ''));
    expect(AccountDraft.splitName('  '), (firstName: '', lastName: ''));
  });

  test('draft dirty + patch payload', () {
    final AgentProfile profile = _profile();
    final AccountDraft baseline = AccountDraft.fromProfile(profile);
    final AccountDraft dirty = baseline.copyWith(bio: 'Hello buyers');
    expect(dirty.sameAs(baseline), isFalse);
    expect(dirty.toPatch()['firstName'], 'Alex');
    expect(dirty.toPatch()['lastName'], 'Rivera');
    expect(dirty.toPatch()['description'], 'Hello buyers');
    expect(dirty.toPatch()['listAgentKeyNumeric'], isNull);
  });

  test('completion is done/5', () {
    final AgentProfile profile = _profile(
      photo: 'https://cdn.test/p.jpg',
      bio: null,
      video: null,
      brokerage: null,
    );
    final AccountDraft draft = AccountDraft.fromProfile(profile);
    expect(draft.completedChecks(profile), 2);
    expect(draft.completionPercent(profile), 40);
  });

  test('public URL uses buyer origin and slug', () {
    expect(
      _profile().publicUrl,
      'https://app.mangoliving.ai/agent/alex-rivera',
    );
    expect(
      const AgentProfile(id: 'xyz', email: 'a@b.com').publicUrl,
      'https://app.mangoliving.ai/agent/xyz',
    );
  });

  test('password and delete confirm rules', () {
    expect(PasswordRules.validateNew('short'), isNotNull);
    expect(PasswordRules.validateNew('nouppercase1!'), isNotNull);
    expect(PasswordRules.validateNew('ValidPass1!'), isNull);
    expect(DeleteConfirm.matches('DELETE'), isTrue);
    expect(DeleteConfirm.matches('delete'), isFalse);
  });

  test('media rules reject size and type', () {
    expect(MediaRules.photo('shot.jpg', 100), isNull);
    expect(MediaRules.photo('shot.pdf', 100), isNotNull);
    expect(MediaRules.photo('shot.jpg', MediaRules.photoMaxBytes + 1), isNotNull);
    expect(MediaRules.video('clip.mp4', 100), isNull);
    expect(
      MediaRules.videoDuration(const Duration(seconds: 31)),
      'Video must be 30 seconds or less',
    );
    expect(MediaRules.logo('logo.svg', 100), isNull);
    expect(MediaRules.logo('logo.gif', 100), isNotNull);
  });

  testWidgets('Account shows tabs and Save when dirty', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final AgentProfile profile = _profile();
    final AccountDraft draft = AccountDraft.fromProfile(profile);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          accountControllerProvider.overrideWith(
            () => _FakeAccountController(
              AccountViewData(profile: profile, draft: draft, baseline: draft),
            ),
          ),
        ],
        child: const MaterialApp(home: AccountPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsWidgets);
    expect(find.text('20% complete'), findsOneWidget);
    expect(find.text('Save'), findsNothing);

    await tester.enterText(find.widgetWithText(TextField, 'Full Name'), 'Alex Rivera Jr');
    await tester.pump();
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('Delete stays disabled until DELETE is typed', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final AgentProfile profile = _profile();
    final AccountDraft draft = AccountDraft.fromProfile(profile);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          accountControllerProvider.overrideWith(
            () => _FakeAccountController(
              AccountViewData(profile: profile, draft: draft, baseline: draft),
            ),
          ),
        ],
        child: const MaterialApp(home: AccountPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(Tab, 'Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(Tab, 'Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete account'));
    await tester.pumpAndSettle();

    final Finder confirm = find.widgetWithText(FilledButton, 'Delete account').last;
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
  });
}
