import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mangoliving_agent/core/widgets/app_search_field.dart';

void main() {
  testWidgets('Done appears above the keyboard and only dismisses it', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController();
    final FocusNode focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSearchField(
            controller: controller,
            focusNode: focusNode,
            hintText: 'Search clients',
          ),
        ),
      ),
    );

    expect(find.text('Done'), findsNothing);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'maya');
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Done'), findsOneWidget);
    expect(focusNode.hasFocus, isTrue);
    expect(controller.text, 'maya');

    await tester.tap(find.text('Done'));
    await tester.pump();

    expect(focusNode.hasFocus, isFalse);
    expect(controller.text, 'maya');
    expect(find.text('Done'), findsNothing);
  });
}
