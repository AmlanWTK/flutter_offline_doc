import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_offline_ai_doc_chat/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('OnboardingScreen shows privacy-first message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingScreen(),
      ),
    );

    expect(find.text('Privacy First'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('OnboardingPage renders title and description', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OnboardingPage(
            title: 'Chat with your Docs',
            description: 'Ask questions about your documents.',
            icon: Icons.chat_bubble_outline,
          ),
        ),
      ),
    );

    expect(find.text('Chat with your Docs'), findsOneWidget);
    expect(find.text('Ask questions about your documents.'), findsOneWidget);
    expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
  });
}
