// Replace `calculator_app` with the name in your pubspec.yaml.
import 'package:calculator_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> press(WidgetTester t, String label) async {
  await t.tap(find.widgetWithText(FilledButton, label));
  await t.pump();
}

Future<void> pressAll(WidgetTester t, List<String> labels) async {
  for (final l in labels) {
    await press(t, l);
  }
}

String display(WidgetTester t) =>
    t.widget<Text>(find.byKey(const Key('display'))).data!;

void main() {
  group('calculate()', () {
    test('basic operations', () {
      expect(calculate(8, '÷', 2), 4);
      expect(calculate(3, '×', 4), 12);
      expect(calculate(3, '−', 5), -2);
      expect(calculate(3, '+', 5), 8);
    });
    test('division by zero returns null, including 0 ÷ 0', () {
      expect(calculate(5, '÷', 0), isNull);
      expect(calculate(0, '÷', 0), isNull);
    });
  });

  group('formatNumber()', () {
    test('hides floating-point noise', () {
      expect(formatNumber(0.1 + 0.2), '0.3');
    });
    test('no trailing .0 and no negative zero', () {
      expect(formatNumber(4.0), '4');
      expect(formatNumber(-0.0), '0');
    });
  });

  group('widget behaviour', () {
    testWidgets('8 ÷ 2 = 4', (t) async {
      await t.pumpWidget(const CalculatorApp());
      await pressAll(t, ['8', '÷', '2', '=']);
      expect(display(t), '4');
    });

    testWidgets('0 ÷ 0 shows an error, not NaN', (t) async {
      await t.pumpWidget(const CalculatorApp());
      await pressAll(t, ['0', '÷', '0', '=']);
      expect(display(t), 'Error');
      expect(find.text('Cannot divide by zero'), findsOneWidget);
    });

    testWidgets('0.1 + 0.2 = 0.3', (t) async {
      await t.pumpWidget(const CalculatorApp());
      await pressAll(t, ['0', '.', '1', '+', '0', '.', '2', '=']);
      expect(display(t), '0.3');
    });

    testWidgets('repeated operator replaces the previous one', (t) async {
      await t.pumpWidget(const CalculatorApp());
      await pressAll(t, ['5', '+', '×', '3', '=']);
      expect(display(t), '15');
    });

    testWidgets('equals too early does nothing harmful', (t) async {
      await t.pumpWidget(const CalculatorApp());
      await pressAll(t, ['5', '×', '=']);
      expect(display(t), '5');
      expect(find.text('Enter a second number first'), findsOneWidget);
    });

    testWidgets('digit after a result starts a new number', (t) async {
      await t.pumpWidget(const CalculatorApp());
      await pressAll(t, ['2', '+', '3', '=', '7']);
      expect(display(t), '7');
    });

    testWidgets('operator after a result continues from it', (t) async {
      await t.pumpWidget(const CalculatorApp());
      await pressAll(t, ['2', '+', '3', '=', '×', '4', '=']);
      expect(display(t), '20');
    });

    testWidgets('chained operations evaluate left to right', (t) async {
      await t.pumpWidget(const CalculatorApp());
      await pressAll(t, ['2', '+', '3', '×', '4', '=']);
      expect(display(t), '20');
    });

    testWidgets('AC resets everything, CE only clears current entry',
        (t) async {
      await t.pumpWidget(const CalculatorApp());
      await pressAll(t, ['9', '+', '5', 'CE']);
      expect(display(t), '9'); // stored operand still shown
      await pressAll(t, ['1', '=']);
      expect(display(t), '10');
      await pressAll(t, ['AC']);
      expect(display(t), '0');
      expect(find.byKey(const Key('expression')), findsOneWidget);
    });

    testWidgets('sign toggle: negative, zero, empty', (t) async {
      await t.pumpWidget(const CalculatorApp());
      await press(t, '±'); // empty input
      expect(display(t), '0');
      await pressAll(t, ['0', '±']); // zero
      expect(display(t), '0');
      await pressAll(t, ['AC', '5', '±']);
      expect(display(t), '-5');
      await press(t, '±');
      expect(display(t), '5');
    });

    testWidgets('theme switch changes brightness', (t) async {
      await t.pumpWidget(const CalculatorApp());
      Brightness b() =>
          Theme.of(t.element(find.byType(Scaffold))).brightness;
      expect(b(), Brightness.light);
      await t.tap(find.byKey(const Key('theme-switch')));
      await t.pumpAndSettle();
      expect(b(), Brightness.dark);
    });
  });
}