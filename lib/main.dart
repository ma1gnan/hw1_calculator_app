import 'package:flutter/material.dart';

void main() => runApp(const CalculatorApp());


/// Applies [op] to [a] and [b]. Returns null when the result is undefined
double? calculate(double a, String op, double b) {
  switch (op) {
    case '+':
      return a + b;
    case '−':
      return a - b;
    case '×':
      return a * b;
    case '÷':
      if (b == 0) return null; // dividing by zero is undefined
      return a / b;
  }
  return null;
}

/// Formats result for displaying no trailing .0 or -0
String formatNumber(double v) {
  if (v == v.roundToDouble() && v.abs() < 1e15) return v.toInt().toString();
  var s = v.toStringAsPrecision(10);
  if (s.contains('e')) return s;
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
  }
  return s;
}


// Theme toggle feature

class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator',
      debugShowCheckedModeBanner: false,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      // MaterialApp animates between theme and darkTheme automatically.
      themeAnimationDuration: const Duration(milliseconds: 400),
      themeAnimationCurve: Curves.easeInOut,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: CalculatorPage(
        isDark: _dark,
        onThemeChanged: (v) => setState(() => _dark = v),
      ),
    );
  }
}


// Calculator screen

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  final bool isDark;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  static const int _maxDigits = 12;

  // State variables 
  String _entry = ''; // digits being typed; '' means "nothing typed yet"
  double? _stored; // first operand, or the last result
  String? _op; // selected operator
  bool _justEvaluated = false; // true right after "="
  String _lastExpression = ''; 
  String? _message; // status / error text
  bool _hasError = false;

  // Derived values 
  String get _displayText {
    if (_hasError) return 'Error';
    if (_entry.isNotEmpty) return _entry;
    return formatNumber(_stored ?? 0);
  }

  String get _expressionText {
    if (_op != null) return '${formatNumber(_stored!)} $_op';
    return _lastExpression;
  }

  // Actions
  void _resetAll() {
    _entry = '';
    _stored = null;
    _op = null;
    _justEvaluated = false;
    _lastExpression = '';
    _message = null;
    _hasError = false;
  }

  void _fail(String message) {
    _resetAll();
    _hasError = true;
    _message = message;
  }

  void _onDigit(String d) {
    setState(() {
      if (_hasError || _justEvaluated) _resetAll(); // new number after result
      _message = null;
      if (_entry == '0') {
        _entry = d; // avoid leading zeros
      } else if (_entry == '-0') {
        _entry = '-$d';
      } else if (_entry.replaceAll(RegExp(r'[^0-9]'), '').length < _maxDigits) {
        _entry += d;
      }
    });
  }

  void _onDecimal() {
    setState(() {
      if (_hasError || _justEvaluated) _resetAll();
      _message = null;
      if (_entry.contains('.')) return;
      _entry = _entry.isEmpty ? '0.' : '$_entry.';
    });
  }

  void _onOperator(String op) {
    setState(() {
      if (_hasError) return;
      _message = null;
      _lastExpression = '';
      // Repeated operator
      if (_op != null && _entry.isEmpty) {
        _op = op;
        return;
      }
      if (_op != null) {
        // evaluated left to right: 2 + 3 × ...
        final result = calculate(_stored!, _op!, double.parse(_entry));
        if (result == null) {
          _fail('Cannot divide by zero');
          return;
        }
        _stored = result;
      } else {
        _stored = _entry.isEmpty ? (_stored ?? 0) : double.parse(_entry);
      }
      _entry = '';
      _op = op;
      _justEvaluated = false;
    });
  }

  void _onEquals() {
    setState(() {
      if (_hasError || _op == null) return; // nothing to calculate
      if (_entry.isEmpty) {
        _message = 'Enter a second number first';
        return;
      }
      final a = _stored!;
      final b = double.parse(_entry);
      final result = calculate(a, _op!, b);
      if (result == null) {
        _fail('Cannot divide by zero');
        return;
      }
      _lastExpression = '${formatNumber(a)} $_op ${formatNumber(b)} =';
      _stored = result;
      _entry = '';
      _op = null;
      _justEvaluated = true;
      _message = null;
    });
  }

  // resets display and all state.
  void _onAllClear() => setState(_resetAll);

  /// Clear entry: clears only the number being typed.
  void _onClearEntry() {
    setState(() {
      if (_hasError || _justEvaluated) {
        _resetAll();
      } else {
        _entry = '';
        _message = null;
      }
    });
  }

  // Zero and empty input are left unchanged
  void _onToggleSign() {
    setState(() {
      if (_hasError) return;
      if (_entry.isNotEmpty) {
        if (double.parse(_entry) == 0) return;
        _entry = _entry.startsWith('-') ? _entry.substring(1) : '-$_entry';
      } else if (_op == null && _stored != null && _stored != 0) {
        _stored = -_stored!; // negate a displayed result
      }
    });
  }

  // UI 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'),
        actions: [
          Icon(widget.isDark ? Icons.dark_mode : Icons.light_mode),
          Semantics(
            label: 'Dark theme',
            child: Switch(
              key: const Key('theme-switch'),
              value: widget.isDark,
              onChanged: widget.onThemeChanged,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: OrientationBuilder(
              builder: (context, orientation) {
                final display = _buildDisplay(context);
                final keypad = _buildKeypad();
                if (orientation == Orientation.landscape) {
                  return Row(children: [
                    Expanded(child: display),
                    Expanded(child: keypad),
                  ]);
                }
                return Column(children: [
                  Expanded(flex: 2, child: display),
                  Expanded(flex: 5, child: keypad),
                ]);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisplay(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spoken =
        _displayText.replaceAll('-', 'minus ').replaceAll('.', ' point');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      alignment: Alignment.bottomRight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _expressionText,
            key: const Key('expression'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (_message != null)
            Semantics(
              liveRegion: true, //error changes
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _hasError ? Icons.error_outline : Icons.info_outline,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _message!,
                      key: const Key('status'),
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: scheme.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Semantics(
            liveRegion: true,
            label: 'Display $spoken',
            excludeSemantics: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                _displayText,
                key: const Key('display'),
                style: theme.textTheme.displayLarge
                    ?.copyWith(color: scheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    Widget row(List<Widget> children) => Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        );
    Widget digit(String d) =>
        CalcButton(label: d, onPressed: () => _onDigit(d));
    Widget op(String label, String spoken) => CalcButton(
          label: label,
          semanticsLabel: spoken,
          kind: ButtonKind.operator,
          selected: _op == label && _entry.isEmpty,
          onPressed: () => _onOperator(label),
        );

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        row([
          CalcButton(
              label: 'AC',
              semanticsLabel: 'All clear',
              kind: ButtonKind.action,
              onPressed: _onAllClear),
          CalcButton(
              label: 'CE',
              semanticsLabel: 'Clear entry',
              kind: ButtonKind.action,
              onPressed: _onClearEntry),
          CalcButton(
              label: '±',
              semanticsLabel: 'Toggle positive negative',
              kind: ButtonKind.action,
              onPressed: _onToggleSign),
          op('÷', 'divide'),
        ]),
        row([digit('7'), digit('8'), digit('9'), op('×', 'multiply')]),
        row([digit('4'), digit('5'), digit('6'), op('−', 'subtract')]),
        row([digit('1'), digit('2'), digit('3'), op('+', 'add')]),
        row([
          CalcButton(label: '0', flex: 2, onPressed: () => _onDigit('0')),
          CalcButton(
              label: '.', semanticsLabel: 'decimal point', onPressed: _onDecimal),
          CalcButton(
              label: '=',
              semanticsLabel: 'equals',
              kind: ButtonKind.equals,
              onPressed: _onEquals),
        ]),
      ]),
    );
  }
}

// Reusable button widget

enum ButtonKind { digit, operator, equals, action }

class CalcButton extends StatelessWidget {
  const CalcButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = ButtonKind.digit,
    this.semanticsLabel,
    this.flex = 1,
    this.selected = false,
  });

  final String label;
  final VoidCallback onPressed;
  final ButtonKind kind;
  final String? semanticsLabel;
  final int flex;

  /// Highlights the active operator with a border
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (kind) {
      ButtonKind.digit => (scheme.surfaceContainerHighest, scheme.onSurface),
      ButtonKind.operator => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer
        ),
      ButtonKind.equals => (scheme.primary, scheme.onPrimary),
      ButtonKind.action => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer
        ),
    };
    final spoken = semanticsLabel == null
        ? null
        : (selected ? '$semanticsLabel, selected' : semanticsLabel);

    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: selected ? BorderSide(color: fg, width: 3) : BorderSide.none,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                label,
                semanticsLabel: spoken,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
