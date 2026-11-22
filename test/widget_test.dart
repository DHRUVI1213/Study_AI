import 'package:flutter_test/flutter_test.dart';
import 'package:ai_study_assistant/app.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const StudyAiApp());
    await tester.pump();
  });
}
