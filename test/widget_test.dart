import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:exam_brow/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Menampilkan halaman pengaturan', (tester) async {
    await tester.pumpWidget(const ExamBrowApp());
    await tester.pumpAndSettle();
    expect(find.text('Exam Browser'), findsOneWidget);
  });
}
