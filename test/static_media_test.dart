import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test_1/models.dart';
import 'package:test_1/widgets/image_view_widget.dart';
import 'package:test_1/widgets/static_web_widget.dart';

void main() {
  group('Static Media Display Tests', () {
    testWidgets('StaticImageView displays placeholder for empty URL', (WidgetTester tester) async {
      final field = FieldModel(
        fieldId: '5777',
        fieldName: 'Test Image',
        fieldType: 'Image',
        fieldValue: '', // Empty string instead of null
        isMandate: false,
        isReadOnly: false,
        hideField: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaticImageView(field: field),
          ),
        ),
      );

      expect(find.text('No image URL provided'), findsOneWidget);
      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('StaticImageView displays tap to zoom hint', (WidgetTester tester) async {
      final field = FieldModel(
        fieldId: '5777',
        fieldName: 'Test Image',
        fieldType: 'Image',
        fieldValue: 'https://example.com/image.jpg',
        isMandate: false,
        isReadOnly: false,
        hideField: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaticImageView(field: field),
          ),
        ),
      );

      expect(find.text('Tap to zoom'), findsOneWidget);
    });

    testWidgets('StaticWebWidget displays HTML content', (WidgetTester tester) async {
      final field = FieldModel(
        fieldId: '5778',
        fieldName: 'Test HTML',
        fieldType: 'WebView',
        fieldValue: '<h1>Hello World</h1><p>This is HTML content</p>',
        isMandate: false,
        isReadOnly: false,
        hideField: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaticWebWidget(field: field),
          ),
        ),
      );

      expect(find.text('HTML Content'), findsOneWidget);
      expect(find.byIcon(Icons.code), findsOneWidget);
    });

    testWidgets('StaticWebWidget displays URL placeholder in test environment', (WidgetTester tester) async {
      final field = FieldModel(
        fieldId: '5778',
        fieldName: 'Test URL',
        fieldType: 'WebView',
        fieldValue: 'https://example.com',
        isMandate: false,
        isReadOnly: false,
        hideField: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaticWebWidget(field: field),
          ),
        ),
      );

      // In test environment, WebView shows placeholder
      expect(find.text('Web Content'), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);
      expect(find.text('https://example.com'), findsOneWidget);
      expect(find.text('Open in Browser'), findsOneWidget);
    });

    testWidgets('StaticWebWidget displays placeholder for empty content', (WidgetTester tester) async {
      final field = FieldModel(
        fieldId: '5778',
        fieldName: 'Test Empty',
        fieldType: 'WebView',
        fieldValue: '', // Empty string instead of null
        isMandate: false,
        isReadOnly: false,
        hideField: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StaticWebWidget(field: field),
          ),
        ),
      );

      expect(find.text('No content provided'), findsOneWidget);
      expect(find.byIcon(Icons.web), findsOneWidget);
    });
  });
}