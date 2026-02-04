import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';

class DatePickerWidget extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  final Map<String, dynamic>? formData;
  const DatePickerWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
    this.formData,
  });
  @override
  State<DatePickerWidget> createState() => _DatePickerWidgetState();
}

class _DatePickerWidgetState extends State<DatePickerWidget> {
  late TextEditingController _controller;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  static const String _dateFormat = 'MMM-dd-yyyy';
  static const String _dateTimeFormat = 'MMM-dd-yyyy hh:mm:ss a';
  @override
  void initState() {
    super.initState();
    final savedValue = widget.formData?[widget.field.fieldId]?.toString();
    _controller = TextEditingController(text: savedValue);
    _parseInitialValue(savedValue);
  }

  void _parseInitialValue(String? value) {
    if (value != null && value.isNotEmpty) {
      try {
        if (_isDateTimeField) {
          _selectedDate = DateFormat(_dateTimeFormat).parse(value);
          _selectedTime = TimeOfDay.fromDateTime(_selectedDate!);
        } else {
          _selectedDate = DateFormat(_dateFormat).parse(value);
        }
      } catch (e) {
        debugPrint('Failed to parse date value: $value');
      }
    }
  }

  bool get _isDateTimeField => widget.field.fieldType == 'DateTime';
  DateTime get _firstDate {
    final config = widget.field.calendarConfig;
    if (config?.minDate != null && config!.minDate!.isNotEmpty) {
      try {
        return DateFormat(_dateFormat).parse(config.minDate!);
      } catch (e) {
        debugPrint('Failed to parse minDate: ${config.minDate}');
      }
    }
    return DateTime(2000);
  }

  DateTime get _lastDate {
    final config = widget.field.calendarConfig;
    if (config?.maxDate != null && config!.maxDate!.isNotEmpty) {
      try {
        return DateFormat(_dateFormat).parse(config.maxDate!);
      } catch (e) {
        debugPrint('Failed to parse maxDate: ${config.maxDate}');
      }
    }
    return DateTime(2101);
  }

  bool _selectableDayPredicate(DateTime day) {
    final config = widget.field.calendarConfig;
    if (config == null) return true;
    final restricted = config.restrictedDates;
    if (restricted == null) return true;
    if (restricted.weekDays != null && restricted.weekDays!.isNotEmpty) {
      if (restricted.weekDays!.contains(day.weekday)) {
        return false;
      }
    }
    if (restricted.months != null && restricted.months!.isNotEmpty) {
      if (restricted.months!.contains(day.month)) {
        return false;
      }
    }
    if (restricted.daysOfMonths != null &&
        restricted.daysOfMonths!.isNotEmpty) {
      if (restricted.daysOfMonths!.contains(day.day)) {
        return false;
      }
    }
    if (restricted.customDates != null && restricted.customDates!.isNotEmpty) {
      final dayStr = DateFormat(_dateFormat).format(day);
      if (restricted.customDates!.contains(dayStr)) {
        return false;
      }
    }
    if (config.allowedDates != null && config.allowedDates!.isNotEmpty) {
      final dayStr = DateFormat(_dateFormat).format(day);
      if (!config.allowedDates!.contains(dayStr)) {
        return false;
      }
    }
    return true;
  }

  Future<void> _selectDate() async {
    if (widget.field.isReadOnly) return;
    final DateTime initialDate = _selectedDate ?? DateTime.now();
    DateTime adjustedInitialDate = initialDate;
    if (adjustedInitialDate.isBefore(_firstDate)) {
      adjustedInitialDate = _firstDate;
    }
    if (adjustedInitialDate.isAfter(_lastDate)) {
      adjustedInitialDate = _lastDate;
    }
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: adjustedInitialDate,
      firstDate: _firstDate,
      lastDate: _lastDate,
      selectableDayPredicate: _selectableDayPredicate,
      helpText: 'Select ${widget.field.fieldName}',
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
      if (_isDateTimeField) {
        await _selectTime();
      } else {
        _updateValue();
      }
    }
  }

  Future<void> _selectTime() async {
    if (widget.field.isReadOnly) return;
    final TimeOfDay initialTime = _selectedTime ?? TimeOfDay.now();
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Select time for ${widget.field.fieldName}',
    );
    if (pickedTime != null) {
      setState(() {
        _selectedTime = pickedTime;
      });
    } else if (_selectedTime == null) {
      setState(() {
        _selectedTime = TimeOfDay.now();
      });
    }
    _updateValue();
  }

  void _updateValue() {
    if (_selectedDate == null) return;
    String formattedValue;
    if (_isDateTimeField) {
      final time = _selectedTime ?? TimeOfDay.now();
      final dateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        time.hour,
        time.minute,
        0,
      );
      formattedValue = DateFormat(_dateTimeFormat).format(dateTime);
    } else {
      formattedValue = DateFormat(_dateFormat).format(_selectedDate!);
    }
    setState(() {
      _controller.text = formattedValue;
    });
    widget.onValueChanged(widget.field.fieldId, formattedValue);
  }

  String? _validate(String? value) {
    if (widget.field.isMandate) {
      if (value == null || value.trim().isEmpty) {
        return '${widget.field.fieldName} is required';
      }
    }
    return null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _selectDate,
      child: AbsorbPointer(
        child: TextFormField(
          controller: _controller,
          readOnly: true,
          validator: _validate,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: false,
            suffixIcon: Icon(
              _isDateTimeField ? Icons.access_time : Icons.calendar_today,
            ),
            hintText: _isDateTimeField ? 'Select date and time' : 'Select date',
          ),
        ),
      ),
    );
  }
}
