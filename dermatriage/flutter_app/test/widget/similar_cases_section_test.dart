// Phase 3 verification: SimilarCasesSection renders the right content for
// each state — agreement, disagreement (amber caution), the healthy_skin /
// no-bank-coverage neutral message, and the loading placeholder.
import 'package:dermatriage/data/models/reference_case.dart';
import 'package:dermatriage/l10n/app_localizations.dart';
import 'package:dermatriage/presentation/widgets/result/similar_cases_section.dart';
import 'package:dermatriage/services/retrieval/retrieval_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

ReferenceMatch _match(String label, double sim, String subject) =>
    ReferenceMatch(
      reference: ReferenceCase(
          file: '$subject.jpg',
          label: label,
          subjectId: subject,
          fitzpatrick: 4),
      similarity: sim,
    );

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  ));
  await tester.pump(); // let the localization delegate's Future resolve
}

void main() {
  testWidgets('agreement: shows quiet confirmation, no warning icon',
      (tester) async {
    final RetrievalResult agree = RetrievalResult(
      <ReferenceMatch>[
        _match('eczema', 0.91, 's1'),
        _match('eczema', 0.87, 's2'),
        _match('eczema', 0.83, 's3'),
      ],
      'eczema',
    );
    await _pump(
      tester,
      SimilarCasesSection(
          retrieval: agree, loading: false, predictedClassId: 'eczema'),
    );

    expect(find.textContaining('Eczema'), findsWidgets);
    expect(find.textContaining('3/3'), findsOneWidget);
    expect(find.text('Similar confirmed cases support this result.'),
        findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  testWidgets('disagreement: shows amber caution naming the retrieval label',
      (tester) async {
    final RetrievalResult disagree = RetrievalResult(
      <ReferenceMatch>[
        _match('eczema', 0.79, 's1'),
        _match('eczema', 0.74, 's2'),
        _match('fungal', 0.70, 's3'),
      ],
      'eczema',
    );
    await _pump(
      tester,
      SimilarCasesSection(
          retrieval: disagree, loading: false, predictedClassId: 'fungal'),
    );

    expect(find.textContaining('2/3'), findsOneWidget);
    expect(
        find.textContaining('Similar cases suggest Eczema'), findsOneWidget);
    expect(find.textContaining('consider referral'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('healthy_skin / no bank coverage: neutral message only',
      (tester) async {
    await _pump(
      tester,
      const SimilarCasesSection(
          retrieval: RetrievalResult.empty,
          loading: false,
          predictedClassId: 'healthy_skin'),
    );

    expect(find.text('No reference cases available for this result.'),
        findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    expect(find.byIcon(Icons.check_circle_outline), findsNothing);
  });

  testWidgets('loading: shows a spinner and loading copy, no result content',
      (tester) async {
    await _pump(
      tester,
      const SimilarCasesSection(
          retrieval: null, loading: true, predictedClassId: 'eczema'),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Finding similar cases…'), findsOneWidget);
    expect(find.text('No reference cases available for this result.'),
        findsNothing);
  });
}
