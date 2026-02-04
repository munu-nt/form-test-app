import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models.dart';
import '../form_widgets.dart';
class GroupedFieldsWidget extends StatefulWidget {
  final FieldModel field;
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onValueChanged;
  const GroupedFieldsWidget({
    super.key,
    required this.field,
    required this.formData,
    required this.onValueChanged,
  });
  @override
  State<GroupedFieldsWidget> createState() => _GroupedFieldsWidgetState();
}
class _GroupedFieldsWidgetState extends State<GroupedFieldsWidget> {
  final List<GroupInstance> _groups = [];
  final Uuid _uuid = const Uuid();
  int get _maxLimit => widget.field.maxGroupLimit ?? 10;
  int get _minRequired => widget.field.minGroupRequired ?? 0;
  @override
  void initState() {
    super.initState();
    _initializeGroups();
  }
  void _initializeGroups() {
    final initialCount = _minRequired > 0 ? _minRequired : 1;
    for (int i = 0; i < initialCount; i++) {
      _groups.add(GroupInstance(id: _uuid.v4()));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _notifyValueChanged();
      }
    });
  }
  void _addGroup() {
    if (_groups.length < _maxLimit) {
      setState(() {
        _groups.add(GroupInstance(id: _uuid.v4()));
      });
      _notifyValueChanged();
    }
  }
  Future<void> _confirmAndRemoveGroup(int index) async {
    if (_groups.length <= _minRequired) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.error,
          size: 48,
        ),
        title: const Text('Remove Section?'),
        content: Text(
          'Are you sure you want to remove "${widget.field.fieldName} #${index + 1}"?\n\n'
          'All data entered in this section will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() {
        _groups.removeAt(index);
      });
      _notifyValueChanged();
    }
  }
  void _toggleExpansion(int index) {
    setState(() {
      _groups[index].isExpanded = !_groups[index].isExpanded;
    });
  }
  void _handleSubFieldChanged(int groupIndex, String fieldId, dynamic value) {
    setState(() {
      _groups[groupIndex].data[fieldId] = value;
    });
    _notifyValueChanged();
  }
  void _notifyValueChanged() {
    final groupData = _groups.map((g) => Map<String, dynamic>.from(g.data)).toList();
    widget.onValueChanged(widget.field.fieldId, groupData);
  }
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._groups.asMap().entries.map((entry) {
          final index = entry.key;
          final group = entry.value;
          return _buildGroupCard(context, index, group);
        }),
        const SizedBox(height: 12),
        Center(
          child: FilledButton.tonalIcon(
            onPressed: _groups.length >= _maxLimit ? null : _addGroup,
            icon: const Icon(Icons.add),
            label: const Text('Add Section'),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              disabledBackgroundColor: colorScheme.surfaceContainerHighest,
              disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
        if (_groups.length >= _maxLimit)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                'Maximum sections reached ($_maxLimit)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.outline,
                ),
              ),
            ),
          ),
      ],
    );
  }
  Widget _buildGroupCard(BuildContext context, int index, GroupInstance group) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canRemove = _groups.length > _minRequired;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleExpansion(index),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: group.isExpanded ? Radius.zero : const Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    group.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.field.fieldName} #${index + 1}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: canRemove ? () => _confirmAndRemoveGroup(index) : null,
                    icon: Icon(
                      Icons.delete_outline,
                      color: canRemove ? colorScheme.error : colorScheme.outline,
                    ),
                    tooltip: canRemove ? 'Remove section' : 'Minimum sections required',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildSubFields(index, group),
            crossFadeState: group.isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
  Widget _buildSubFields(int groupIndex, GroupInstance group) {
    if (widget.field.subFields == null || widget.field.subFields!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No subfields configured',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: widget.field.subFields!.asMap().entries.map<Widget>((entry) {
          final subFieldIndex = entry.key;
          final subField = entry.value;
          final fieldWithValue = FieldModel(
            fieldId: subField.fieldId,
            fieldName: subField.fieldName,
            fieldType: subField.fieldType,
            fieldValue: group.data[subField.fieldId]?.toString(),
            fieldMaxLength: subField.fieldMaxLength,
            isMandate: subField.isMandate,
            sequence: subField.sequence,
            index: subField.index,
            fieldOptions: subField.fieldOptions,
            isReadOnly: subField.isReadOnly,
            hideField: subField.hideField,
          );
          return DynamicFormField(
            key: Key('${widget.field.fieldId}_${group.id}_${subField.fieldId}'),
            field: fieldWithValue,
            formData: group.data,
            displayIndex: subFieldIndex,
            onValueChanged: (fieldId, value) {
              _handleSubFieldChanged(groupIndex, fieldId, value);
            },
          );
        }).toList(),
      ),
    );
  }
}