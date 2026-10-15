import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/app_feedback.dart';

void main() {
  testWidgets('AppFeedback.showSuccess displays floating toast with message and icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppFeedback.showSuccess(
                  context,
                  title: 'Connexion réussie',
                  message: 'Bienvenue sur FEMAX !',
                );
              },
              child: const Text('Show Success'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Success'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Connexion réussie'), findsOneWidget);
    expect(find.text('Bienvenue sur FEMAX !'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('AppFeedback.showError displays floating toast with action', (WidgetTester tester) async {
    bool actionClicked = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppFeedback.showError(
                  context,
                  error: 'Identifiants invalides',
                  customTitle: 'Erreur de connexion',
                  actionLabel: 'Réessayer',
                  onAction: () => actionClicked = true,
                );
              },
              child: const Text('Show Error'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Error'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Erreur de connexion'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);

    await tester.tap(find.text('Réessayer'));
    await tester.pump();

    expect(actionClicked, isTrue);
  });

  testWidgets('InlineFeedbackBanner renders title, message and icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: InlineFeedbackBanner(
            type: FeedbackType.warning,
            title: 'Attention',
            message: 'Veuillez vérifier votre email',
            suggestion: 'Vérifiez le dossier spams',
          ),
        ),
      ),
    );

    expect(find.text('Attention'), findsOneWidget);
    expect(find.text('Veuillez vérifier votre email'), findsOneWidget);
    expect(find.text('💡 Vérifiez le dossier spams'), findsOneWidget);
  });
}
