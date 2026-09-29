import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mangoliving_agent/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    dotenv.testLoad(
      fileInput: '''
APP_NAME=MangoLiving Agent
API_BASE_URL=https://example.test/api
API_TIMEOUT_SECONDS=5
''',
    );
  });

  testWidgets('app boots to splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MangoLivingAgentApp()));
    expect(find.text('MangoLiving Agent'), findsOneWidget);
  });
}
