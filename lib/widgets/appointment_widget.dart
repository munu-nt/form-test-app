import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models.dart';
class SlotService {
  static Future<List<AppointmentSlot>> fetchSlots(DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
    if (isWeekend) {
      return [
        AppointmentSlot(id: '1', time: '10:00 AM', availableSeats: 3, maxSeats: 5),
        AppointmentSlot(id: '2', time: '11:00 AM', availableSeats: 5, maxSeats: 5),
        AppointmentSlot(id: '3', time: '02:00 PM', availableSeats: 0, maxSeats: 5, isAvailable: false),
      ];
    }
    return [
      AppointmentSlot(id: '1', time: '09:00 AM', availableSeats: 2, maxSeats: 5),
      AppointmentSlot(id: '2', time: '10:00 AM', availableSeats: 5, maxSeats: 5),
      AppointmentSlot(id: '3', time: '11:00 AM', availableSeats: 1, maxSeats: 5),
      AppointmentSlot(id: '4', time: '02:00 PM', availableSeats: 4, maxSeats: 5),
      AppointmentSlot(id: '5', time: '03:00 PM', availableSeats: 0, maxSeats: 5, isAvailable: false),
      AppointmentSlot(id: '6', time: '04:00 PM', availableSeats: 3, maxSeats: 5),
    ];
  }
}
class AppointmentWidget extends StatefulWidget {
  final FieldModel field;
  final Function(String, dynamic) onValueChanged;
  const AppointmentWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
  });
  @override
  State<AppointmentWidget> createState() => _AppointmentWidgetState();
}
class _AppointmentWidgetState extends State<AppointmentWidget> {
  DateTime? _selectedDate;
  AppointmentSlot? _selectedSlot;
  int _seatCount = 1;
  bool _isLoadingSlots = false;
  String? _errorMessage;
  List<AppointmentSlot> _availableSlots = [];
  int _fetchRequestId = 0;
  final _descCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _appointmentType = 'OneOnOne';
  String? _selectedCampus;
  @override
  void dispose() {
    _descCtrl.dispose();
    _reasonCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }
  Future<void> _fetchSlotsForDate(DateTime date) async {
    final currentRequestId = ++_fetchRequestId;
    setState(() {
      _isLoadingSlots = true;
      _errorMessage = null;
      _selectedSlot = null;
      _availableSlots = [];
    });
    try {
      final slots = await SlotService.fetchSlots(date);
      if (currentRequestId != _fetchRequestId) {
        return;  
      }
      setState(() {
        _availableSlots = slots;
        _isLoadingSlots = false;
      });
    } catch (e) {
      if (currentRequestId != _fetchRequestId) return;
      setState(() {
        _errorMessage = 'Failed to load slots. Please try again.';
        _isLoadingSlots = false;
      });
    }
  }
  void _selectSlot(AppointmentSlot slot) {
    if (!slot.isAvailable || slot.availableSeats == 0) return;
    setState(() {
      _selectedSlot = slot;
      _seatCount = 1;  
    });
    _updateValue();
  }
  void _incrementSeats() {
    if (_selectedSlot == null) return;
    if (_seatCount < _selectedSlot!.availableSeats) {
      setState(() {
        _seatCount++;
      });
      _updateValue();
    }
  }
  void _decrementSeats() {
    if (_seatCount > 1) {
      setState(() {
        _seatCount--;
      });
      _updateValue();
    }
  }
  void _updateValue() {
    if (_selectedDate == null || _selectedSlot == null) return;
    final apptData = {
      'Date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      'Slot': _selectedSlot!.time,
      'SlotId': _selectedSlot!.id,
      'SeatCount': _seatCount,
      'AppointmentType': _appointmentType,
      'Campus': _selectedCampus,
      'Description': _descCtrl.text,
      'Reason': _reasonCtrl.text,
      'Email': _emailCtrl.text,
    };
    widget.onValueChanged(widget.field.fieldId, apptData);
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Book Appointment', style: theme.textTheme.titleLarge),
              ],
            ),
            const Divider(height: 24),
            _buildDatePicker(theme),
            if (_selectedDate != null) ...[
              const SizedBox(height: 20),
              _buildSlotSection(theme),
            ],
            if (_selectedSlot != null) ...[
              const SizedBox(height: 24),
              _buildDetailsSection(theme),
              const SizedBox(height: 24),
              _buildBookingSummary(theme),
            ],
          ],
        ),
      ),
    );
  }
  Widget _buildDatePicker(ThemeData theme) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.calendar_today, color: theme.colorScheme.onPrimaryContainer),
      ),
      title: Text(
        _selectedDate == null 
            ? 'Select Date' 
            : DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate!),
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: _selectedDate != null ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      subtitle: _selectedDate == null 
          ? const Text('Tap to choose appointment date')
          : null,
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.outline),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedDate ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
          });
          _fetchSlotsForDate(date);
        }
      },
    );
  }
  Widget _buildSlotSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Available Slots', style: theme.textTheme.titleMedium),
            const Spacer(),
            if (_isLoadingSlots)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoadingSlots)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Loading available slots...'),
                ],
              ),
            ),
          )
        else if (_errorMessage != null)
          _buildErrorState(theme)
        else if (_availableSlots.isEmpty)
          _buildEmptyState(theme)
        else
          _buildSlotGrid(theme),
      ],
    );
  }
  Widget _buildErrorState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 32),
          const SizedBox(height: 8),
          Text(_errorMessage!, style: TextStyle(color: theme.colorScheme.error)),
          const SizedBox(height: 12),
          FilledButton.tonal(
            onPressed: () => _fetchSlotsForDate(_selectedDate!),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.event_busy, color: theme.colorScheme.outline, size: 48),
          const SizedBox(height: 12),
          Text(
            'No slots available for this date',
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 8),
          Text(
            'Please try another date',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
  Widget _buildSlotGrid(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableSlots.map((slot) {
        final isSelected = _selectedSlot?.id == slot.id;
        final isDisabled = !slot.isAvailable || slot.availableSeats == 0;
        return FilterChip(
          label: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(slot.time),
              Text(
                isDisabled ? 'Full' : '${slot.availableSeats} seats',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDisabled 
                      ? theme.colorScheme.error 
                      : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          selected: isSelected,
          showCheckmark: false,
          avatar: isSelected ? const Icon(Icons.check, size: 18) : null,
          backgroundColor: isDisabled 
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
              : null,
          onSelected: isDisabled ? null : (val) {
            if (val) _selectSlot(slot);
          },
        );
      }).toList(),
    );
  }
  Widget _buildDetailsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appointment Details', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        Text('Appointment Type', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'OneOnOne', label: Text('One-on-One'), icon: Icon(Icons.person)),
            ButtonSegment(value: 'Group', label: Text('Group'), icon: Icon(Icons.groups)),
          ],
          selected: {_appointmentType},
          onSelectionChanged: (Set<String> selection) {
            setState(() {
              _appointmentType = selection.first;
            });
            _updateValue();
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('Seats Required: ', style: theme.textTheme.labelLarge),
            const SizedBox(width: 16),
            IconButton.outlined(
              icon: const Icon(Icons.remove),
              onPressed: _seatCount > 1 ? _decrementSeats : null,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_seatCount',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            IconButton.outlined(
              icon: const Icon(Icons.add),
              onPressed: _seatCount < (_selectedSlot?.availableSeats ?? 1) 
                  ? _incrementSeats 
                  : null,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'of ${_selectedSlot?.availableSeats ?? 0} available',
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Campus',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.business),
          ),
          value: _selectedCampus,
          items: ['Main Campus', 'North Campus', 'South Campus', 'Online']
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: (val) {
            setState(() => _selectedCampus = val);
            _updateValue();
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descCtrl,
          decoration: const InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 2,
          onChanged: (_) => _updateValue(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _reasonCtrl,
          decoration: const InputDecoration(
            labelText: 'Reason for Appointment',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.help_outline),
          ),
          onChanged: (_) => _updateValue(),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _emailCtrl,
          decoration: const InputDecoration(
            labelText: 'Contact Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => _updateValue(),
        ),
      ],
    );
  }
  Widget _buildBookingSummary(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Text(
                'Booking Summary',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Date', DateFormat('EEEE, MMM dd, yyyy').format(_selectedDate!), theme),
          _buildSummaryRow('Time', _selectedSlot!.time, theme),
          _buildSummaryRow('Type', _appointmentType, theme),
          _buildSummaryRow('Seats', '$_seatCount', theme),
          if (_selectedCampus != null)
            _buildSummaryRow('Campus', _selectedCampus!, theme),
        ],
      ),
    );
  }
  Widget _buildSummaryRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}