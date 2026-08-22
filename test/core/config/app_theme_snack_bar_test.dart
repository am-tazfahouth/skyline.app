import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sky_line/core/config/app_theme.dart';

void main() {
  // Regression guard for the M3 SnackBar "action overflow" layout: when the
  // combined width of the action label and close icon exceeds
  // `actionOverflowThreshold` of the snackbar width, Flutter renders the
  // action on an extra row below the message, squeezing the text into ~55%
  // of the width and producing a gigantic snackbar (visible with French
  // labels such as "Rechercher").
  testWidgets(
    'snackbar keeps the action on the message row instead of an extra overflow row',
    (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(360, 800);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme(ThemeData.light().textTheme).light(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                SchedulerBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Connexion impossible.'),
                      action: SnackBarAction(
                        label: 'Rechercher',
                        onPressed: () {},
                      ),
                    ),
                  );
                });
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final messageRect = tester.getRect(find.text('Connexion impossible.'));
      final actionRect = tester.getRect(find.byType(SnackBarAction));

      expect(
        actionRect.bottom,
        lessThanOrEqualTo(messageRect.bottom),
        reason:
            'The action button must stay vertically aligned with the message '
            '(inline layout), not rendered on an extra row below it.',
      );
    },
  );
}
