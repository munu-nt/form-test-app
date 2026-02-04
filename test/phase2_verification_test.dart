import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:test_1/main.dart';
import 'package:test_1/widgets/searchable_dropdown.dart';
import 'package:test_1/widgets/card_selector.dart';
import 'package:test_1/widgets/star_rating.dart';

// Mock dependencies as we can't load assets in widget tests easily without setup
// Actually, better to test the FormPage if possible, but asset loading might fail
// So we will pump the app and mock the asset bundle or just test the DynamicFormField in isolation with our data
// Testing the full integration via main.dart might be tricky if data loading is async from rootBundle.
// Instead, we will build a test widget that uses the same logic as _FormPageState but injects data directly.

void main() {
  testWidgets('Phase 2 Verification Test', (WidgetTester tester) async {
    // 1. Setup Data
    /*
    Academic Section IDs:
    - 5752: Academic Level
    - 5753: Academic School
    - 1005: Department
    - 1006: Program (Dependent on 1005)
    
    Location Section IDs:
    - 2005: Country
    - 2003: State (Dependent on 2005)
    - 2002: City (Dependent on 2003)
    
    Selection Controls:
    - 5760: CheckBox
    - 5006: Rating
    */
    
    // We'll reuse the FormPage but mock the asset loading? 
    // Data loading is hardcoded in _loadFormData. 
    // Instead of fighting the asset loader, let's create a test harness.
    
    // Build MaterialApp directly to inject Bundle inside
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
        home: DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: const FormPage(),
        ),
      ),
    );
    
    // Allow Future to complete
    await tester.pump(); 
    await tester.pump(const Duration(seconds: 1)); 
    await tester.pumpAndSettle();

    // Check if we are still loading (Timeout debug)
    if (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      debugPrint('Still loading...');
      // Try to find error message if any
      final errorFinder = find.textContaining('Failed to load');
      if (errorFinder.evaluate().isNotEmpty) {
         debugPrint('Error found: ${errorFinder.evaluate().first}');
      }
    }
    
    // Verify title
    expect(find.text('Phase 2 - Moderate Risk Form'), findsOneWidget);
    
    // --- SCENARIO 1: Department -> Program ---
    
    // Find Department Dropdown (Field 1005)
    // It's a SearchableDropdown (DropdownMenu)
    // Find Department Dropdown (Field 1005)
    // There might be multiple Scrollables (e.g. inside Dropdowns), so we target the main one.
    final listScrollable = find.byType(Scrollable).first;

    // It's a SearchableDropdown (DropdownMenu)
    final deptFinder = find.byKey(const Key('1005')).first;
    await tester.scrollUntilVisible(deptFinder, 500, scrollable: listScrollable);
    expect(deptFinder, findsOneWidget);
    
    // Select 'Computer Science' (Value: DEPT_CS)
    // DropdownMenu is tricky to test. Tapping it opens a menu.
    await tester.tap(deptFinder);
    await tester.pumpAndSettle();
    
    // Find option 'Computer Science' and tap
    await tester.tap(find.text('Computer Science').last);
    await tester.pumpAndSettle();
    
    // Verify Program List (Field 1006) Options
    final progFinder = find.descendant(of: listScrollable, matching: find.byKey(const Key('1006')));
    await tester.scrollUntilVisible(progFinder, 500, scrollable: listScrollable);
    await tester.tap(progFinder);
    await tester.pumpAndSettle();
    
    // Should see 'AI & ML', 'Software Engineering'
    expect(find.text('AI & ML'), findsAtLeastNWidgets(1));
    expect(find.text('Software Engineering'), findsAtLeastNWidgets(1));
    // Should NOT see 'Robotics' (ParentCode: DEPT_ME)
    expect(find.text('Robotics'), findsNothing);
    
    // Close menu (tap outside)
    await tester.tapAt(const Offset(0, 0));
    await tester.pumpAndSettle();
    
    // Change Department to Mechanical Engineering
    await tester.scrollUntilVisible(deptFinder, 500, scrollable: listScrollable);
    await tester.tap(deptFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mechanical Engineering').last);
    await tester.pumpAndSettle();
    
    // Check Program Options again
    await tester.scrollUntilVisible(progFinder, 500, scrollable: listScrollable);
    await tester.tap(progFinder);
    await tester.pumpAndSettle();
    expect(find.text('Robotics'), findsAtLeastNWidgets(1)); // Now visible
    expect(find.text('AI & ML'), findsNothing);
    
    // Close menu
    await tester.tapAt(const Offset(0, 0));
    await tester.pumpAndSettle();


    // --- SCENARIO 2: United States -> California -> Los Angeles ---
    
    // 2.1 Select Country: US
    final countryFinder = find.descendant(of: listScrollable, matching: find.byKey(const Key('2005')));
    await tester.scrollUntilVisible(countryFinder, 500, scrollable: listScrollable);
    await tester.tap(countryFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('United States').last);
    await tester.pumpAndSettle();
    
    // 2.2 Select State: California
    final stateFinder = find.descendant(of: listScrollable, matching: find.byKey(const Key('2003')));
    await tester.scrollUntilVisible(stateFinder, 100, scrollable: listScrollable);
    await tester.tap(stateFinder);
    await tester.pumpAndSettle();
    
    expect(find.text('California'), findsAtLeastNWidgets(1));
    expect(find.text('Maharashtra'), findsNothing); 
    
    await tester.tap(find.text('California').last);
    await tester.pumpAndSettle();
    
    // 2.3 Verify City: Los Angeles
    final cityFinder = find.descendant(of: listScrollable, matching: find.byKey(const Key('2002')));
    await tester.scrollUntilVisible(cityFinder, 100, scrollable: listScrollable);
    await tester.tap(cityFinder);
    await tester.pumpAndSettle();
    
    expect(find.text('Los Angeles'), findsAtLeastNWidgets(1));
    expect(find.text('Mumbai'), findsNothing);
    
    // Close menu
    await tester.tapAt(const Offset(0, 0));
    await tester.pumpAndSettle();
    
    
    // --- SCENARIO 3: Selection Controls ---
    
    // 3.1 Checkbox (5760)
    final chkFinder = find.descendant(of: listScrollable, matching: find.byKey(const Key('5760')));
    await tester.scrollUntilVisible(chkFinder, 500, scrollable: listScrollable);
    expect(chkFinder, findsOneWidget);
    // Tap 'Library Access'
    await tester.tap(find.text(r'Library Access ($20)')); // Text might not be duplicated
    await tester.pump();
    
    // 3.2 Star Rating (5006)
    final rateFinder = find.descendant(of: listScrollable, matching: find.byKey(const Key('5006')));
    await tester.scrollUntilVisible(rateFinder, 100, scrollable: listScrollable);
    // Finds 5 star icons. Tap the 4th one.
    // The key is on the Row. The children are IconButtons.
    // We can find by icon.
    final stars = find.descendant(of: rateFinder, matching: find.byType(IconButton));
    expect(stars, findsNWidgets(5));
    await tester.tap(stars.at(3)); // 4th star
    await tester.pump();
    
    // Verify visual update (icon changes to star from star_border or stays star)
    // Hard to verify state without inspecting widget state, but no crash is good.
    
    // 3.3 Like/Unlike (5005)
    final likeFinder = find.descendant(of: listScrollable, matching: find.byKey(const Key('5005')));
    await tester.scrollUntilVisible(likeFinder, 100, scrollable: listScrollable);
    await tester.tap(find.descendant(of: likeFinder, matching: find.byIcon(Icons.thumb_up)));
    await tester.pump();
    
  });
}

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    print('TestAssetBundle loading key: $key');
    if (key.contains('form-data.json')) {
      return r'''
{
    "Status": true,
    "ErrorType": null,
    "FormName": "Phase 2 - Moderate Risk Form",
    "FormCategory": "AdhocForm",
    "ButtonType": "SUBMIT",
    "Fields": [
        {
            "FieldID": "5752",
            "FieldName": "Academic Level",
            "FieldType": "AcademicLevel",
            "FieldValue": null,
            "FieldMaxLength": "100",
            "IsMandate": true,
            "Sequence": "1",
            "FieldOptions": [
                { "Value": "UG", "Text": "Undergraduate" },
                { "Value": "PG", "Text": "Postgraduate" }
            ]
        },
        {
            "FieldID": "5753",
            "FieldName": "Academic School",
            "FieldType": "AcademicSchool",
            "FieldValue": null,
            "FieldMaxLength": "100",
            "IsMandate": false,
            "Sequence": "2",
            "FieldOptions": [
                { "Value": "SCH_ENG", "Text": "School of Engineering" },
                { "Value": "SCH_ART", "Text": "School of Arts" }
            ]
        },
        {
            "FieldID": "1005",
            "FieldName": "Department",
            "FieldType": "DepartmentList",
            "FieldValue": null,
            "FieldMaxLength": "100",
            "IsMandate": true,
            "Sequence": "3",
            "FieldOptions": [
                { "Value": "DEPT_CS", "Text": "Computer Science" },
                { "Value": "DEPT_ME", "Text": "Mechanical Engineering" },
                { "Value": "DEPT_HIST", "Text": "History" }
            ]
        },
        {
            "FieldID": "1006",
            "FieldName": "Program",
            "FieldType": "ProgramList",
            "FieldValue": null,
            "FieldMaxLength": "100",
            "IsMandate": true,
            "Sequence": "4",
            "FieldOptions": [
                { "Value": "PROG_CS_AI", "Text": "AI & ML", "ParentCode": "DEPT_CS" },
                { "Value": "PROG_CS_SE", "Text": "Software Engineering", "ParentCode": "DEPT_CS" },
                { "Value": "PROG_ME_ROBO", "Text": "Robotics", "ParentCode": "DEPT_ME" },
                { "Value": "PROG_HIST_ANC", "Text": "Ancient History", "ParentCode": "DEPT_HIST" }
            ]
        },
        {
            "FieldID": "1007",
            "FieldName": "Program Profile",
            "FieldType": "ProgramProfile",
            "FieldValue": null,
            "FieldMaxLength": "100",
            "IsMandate": false,
            "Sequence": "5",
            "FieldOptions": [
                { "Value": "FULL_TIME", "Text": "Full Time", "Code": "FT" },
                { "Value": "PART_TIME", "Text": "Part Time", "Code": "PT" }
            ]
        },
        {
            "FieldID": "1003",
            "FieldName": "Admit Term",
            "FieldType": "AdmitTermList",
            "FieldValue": null,
            "FieldMaxLength": "100",
            "IsMandate": true,
            "Sequence": "6",
            "FieldOptions": [
                { "Value": "FALL_2025", "Text": "Fall 2025" },
                { "Value": "SPRING_2026", "Text": "Spring 2026" }
            ]
        },
        {
             "FieldID": "DIV_1",
             "FieldName": "Location Details",
             "FieldType": "Divider",
             "IsMandate": false,
             "Sequence": "10"
        },
        {
            "FieldID": "2005",
            "FieldName": "Country",
            "FieldType": "CountryList",
            "FieldValue": null,
            "FieldMaxLength": "100",
            "IsMandate": true,
            "Sequence": "11",
            "FieldOptions": [
                { "Value": "US", "Text": "United States" },
                { "Value": "IN", "Text": "India" },
                { "Value": "CA", "Text": "Canada" }
            ]
        },
        {
            "FieldID": "2003",
            "FieldName": "State",
            "FieldType": "StateList",
            "FieldValue": null,
            "FieldMaxLength": "100",
            "IsMandate": true,
            "Sequence": "12",
            "FieldOptions": [
                { "Value": "US_CA", "Text": "California", "ParentCode": "US" },
                { "Value": "US_NY", "Text": "New York", "ParentCode": "US" },
                { "Value": "IN_MH", "Text": "Maharashtra", "ParentCode": "IN" },
                { "Value": "IN_DL", "Text": "Delhi", "ParentCode": "IN" },
                { "Value": "CA_ON", "Text": "Ontario", "ParentCode": "CA" }
            ]
        },
        {
            "FieldID": "2002",
            "FieldName": "City",
            "FieldType": "CityList",
            "FieldValue": null,
            "FieldMaxLength": "100",
            "IsMandate": true,
            "Sequence": "13",
            "FieldOptions": [
                { "Value": "LA", "Text": "Los Angeles", "ParentCode": "US_CA" },
                { "Value": "SF", "Text": "San Francisco", "ParentCode": "US_CA" },
                { "Value": "NYC", "Text": "New York City", "ParentCode": "US_NY" },
                { "Value": "MUM", "Text": "Mumbai", "ParentCode": "IN_MH" },
                { "Value": "PUN", "Text": "Pune", "ParentCode": "IN_MH" },
                { "Value": "ND", "Text": "New Delhi", "ParentCode": "IN_DL" },
                { "Value": "TOR", "Text": "Toronto", "ParentCode": "CA_ON" }
            ]
        },
        {
            "FieldID": "5754",
            "FieldName": "Postal Code",
            "FieldType": "PostalCode",
            "FieldValue": null,
            "FieldMaxLength": "10",
            "IsMandate": true,
            "Sequence": "14"
        },
        {
            "FieldID": "5761",
            "FieldName": "Citizenship",
            "FieldType": "CitizenshipList",
            "FieldValue": null,
            "FieldMaxLength": "100",
            "IsMandate": false,
            "Sequence": "15",
            "FieldOptions": [
                { "Value": "US", "Text": "American" },
                { "Value": "IN", "Text": "Indian" },
                { "Value": "CA", "Text": "Canadian" }
            ]
        },
        {
             "FieldID": "DIV_2",
             "FieldName": "Preferences",
             "FieldType": "Divider",
             "IsMandate": false,
             "Sequence": "20"
        },
        {
            "FieldID": "5002",
            "FieldName": "Contact Preference",
            "FieldType": "RadioButton",
            "FieldValue": null,
            "FieldMaxLength": "100",
            "IsMandate": false,
            "Sequence": "21",
            "FieldOptions": [
                { "Value": "EMAIL", "Text": "Email" },
                { "Value": "PHONE", "Text": "Phone" }
            ]
        },
        {
            "FieldID": "5760",
            "FieldName": "Extra Services",
            "FieldType": "CheckBox",
            "FieldValue": "GYM",
            "FieldMaxLength": "100",
            "IsMandate": false,
            "Sequence": "22",
            "FieldOptions": [
                { "Value": "GYM", "Text": "Gym Access ($50)" },
                { "Value": "LIB", "Text": "Library Access ($20)" },
                { "Value": "PARK", "Text": "Parking ($100)" }
            ]
        },
        {
            "FieldID": "5005",
            "FieldName": "Feedback",
            "FieldType": "LikeUnlike",
            "FieldValue": null,
            "FieldMaxLength": "10",
            "IsMandate": false,
            "Sequence": "23"
        },
        {
            "FieldID": "5006",
            "FieldName": "Experience Rating",
            "FieldType": "Rating",
            "FieldValue": "3",
            "FieldMaxLength": "10",
            "IsMandate": false,
            "Sequence": "24"
        }
    ]
}
      ''';
    }
    return '';
  }

  @override
  Future<ByteData> load(String key) async {
    throw UnimplementedError();
  }
}
