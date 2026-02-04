import 'package:flutter/material.dart';
import '../models.dart';
class FormulaWidget extends StatefulWidget {
  final FieldModel field;
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onValueChanged;
  const FormulaWidget({
    super.key,
    required this.field,
    required this.formData,
    required this.onValueChanged,
  });
  @override
  State<FormulaWidget> createState() => _FormulaWidgetState();
}
class _FormulaWidgetState extends State<FormulaWidget> {
  final TextEditingController _controller = TextEditingController();
  String _lastCalculated = "";
  @override
  void initState() {
    super.initState();
    _calculateValue();
  }
  @override
  void didUpdateWidget(covariant FormulaWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.formData != oldWidget.formData) {
      _calculateValue();
    }
  }
  void _calculateValue() {
    final formula = widget.field.formula;
    if (formula == null || formula.isEmpty) return;
    String processedFormula = formula;
    final regex = RegExp(r'F_(\d+)');
    final matches = regex.allMatches(formula);
    for (final match in matches) {
      final text = match.group(0)!;  
      final id = match.group(1)!;    
      final valStr = widget.formData[id]?.toString() ?? "0";
      final val = double.tryParse(valStr) ?? 0.0;
      processedFormula = processedFormula.replaceAll(text, val.toString());
    }
    try {
       double result = _evaluateMathExpression(processedFormula);
       String resultStr = result == result.roundToDouble() ? result.toInt().toString() : result.toString();
       if (_lastCalculated != resultStr) {
         _lastCalculated = resultStr;
         _controller.text = resultStr;
         WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onValueChanged(widget.field.fieldId, resultStr);
         });
       }
    } catch (e) {
    }
  }
  double _evaluateMathExpression(String expression) {
    expression = expression.replaceAll(' ', '');
    final terms = <String>[];
    final ops = <String>[];
    int lastIdx = 0;
    int level = 0;  
    for (int i = 0; i < expression.length; i++) {
        String char = expression[i];
        if (char == '+' || char == '-') {
            terms.add(expression.substring(lastIdx, i));
            ops.add(char);
            lastIdx = i + 1;
        }
    }
    terms.add(expression.substring(lastIdx));
    double total = 0;
    total = _evaluateTerm(terms[0]);
    for (int i = 0; i < ops.length; i++) {
        double nextVal = _evaluateTerm(terms[i+1]);
        if (ops[i] == '+') total += nextVal;
        else if (ops[i] == '-') total -= nextVal;
    }
    return total;
  }
  double _evaluateTerm(String term) {
      final factors = <String>[];
      final ops = <String>[];
      int lastIdx = 0;
      for (int i = 0; i < term.length; i++) {
          String char = term[i];
          if (char == '*' || char == '/') {
              factors.add(term.substring(lastIdx, i));
              ops.add(char);
              lastIdx = i + 1;
          }
      }
      factors.add(term.substring(lastIdx));
      double result = double.tryParse(factors[0]) ?? 0.0;
      for (int i = 0; i < ops.length; i++) {
          double nextVal = double.tryParse(factors[i+1]) ?? 0.0;
          if (ops[i] == '*') result *= nextVal;
          else if (ops[i] == '/') {
              if (nextVal != 0) result /= nextVal;
          }
      }
      return result;
  }
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: widget.field.fieldName,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        ),
      ),
    );
  }
}