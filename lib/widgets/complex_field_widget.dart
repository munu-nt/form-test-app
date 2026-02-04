import 'package:flutter/material.dart';
import '../models.dart';
import '../form_widgets.dart';
class ComplexFieldWidget extends StatelessWidget {
  final FieldModel parentField;
  final List<FieldModel> allFields;
  final Map<String, dynamic> formData;
  final Function(String, dynamic) onValueChanged;
  const ComplexFieldWidget({
    super.key,
    required this.parentField,
    required this.allFields,
    required this.formData,
    required this.onValueChanged,
  });
  @override
  Widget build(BuildContext context) {
    final children = allFields.where((f) => 
       f.fieldId == parentField.fieldId && 
       f.fieldType != parentField.fieldType 
    ).toList();
    children.sort((a, b) {
       int seqA = int.tryParse(a.sequence ?? "0") ?? 0;
       int seqB = int.tryParse(b.sequence ?? "0") ?? 0;
       return seqA.compareTo(seqB);
    });
    if (children.isEmpty) {
       return Card(
         child: Padding(
           padding: const EdgeInsets.all(16.0),
           child: Text("No sub-fields found for ${parentField.fieldName} (ID: ${parentField.fieldId})"),
         ),
       );
    }
    List<FieldModel> virtualChildren = [];
    Map<String, dynamic> currentGroupData = {};
    if (formData[parentField.fieldId] is Map) {
        currentGroupData = Map<String, dynamic>.from(formData[parentField.fieldId]);
    }
    Map<String, dynamic> virtualData = {};
    for (var child in children) {
       String virtualId = "${parentField.fieldId}_${child.fieldName.replaceAll(RegExp(r'\s+'), '')}";
       if (virtualChildren.any((f) => f.fieldId == virtualId)) {
          virtualId = "${virtualId}_${child.index}";
       }
       FieldModel vf = FieldModel(
          fieldId: virtualId,
          fieldName: child.fieldName,
          fieldType: child.fieldType,
          fieldValue: currentGroupData[child.fieldName] ?? child.fieldValue,
          isMandate: child.isMandate,
          fieldOptions: child.fieldOptions,
          sequence: child.sequence,
          isReadOnly: child.isReadOnly,
          hideField: child.hideField,
          fieldMaxLength: child.fieldMaxLength,
          index: child.index,
          fieldDescription: child.fieldDescription,
          calendarConfig: child.calendarConfig,
          fieldRegex: child.fieldRegex,
          fieldValidationConfig: child.fieldValidationConfig,
          fieldValidationMessage: child.fieldValidationMessage,
          fieldHelpText: child.fieldHelpText,
          fieldInfo: child.fieldInfo,
          isDependent: child.isDependent,
          fieldDependencyConfig: child.fieldDependencyConfig,
          fileUploadOption: child.fileUploadOption,
          fieldPaymentEnabled: child.fieldPaymentEnabled,
          pointsAllocated: child.pointsAllocated,
          fieldOptionPointEnabled: child.fieldOptionPointEnabled,
          additionalFieldValues: child.additionalFieldValues,
          multiFileUploadOption: child.multiFileUploadOption,
          profileFieldCode: child.profileFieldCode,
          programLenthList: child.programLenthList,
          optionFieldAutoSelectConfig: child.optionFieldAutoSelectConfig,
          enableDefaultFieldConfig: child.enableDefaultFieldConfig,
          maxGroupLimit: child.maxGroupLimit,
          minGroupRequired: child.minGroupRequired,
          isGroupedField: child.isGroupedField,
          groupId: child.groupId,
          groupSequence: child.groupSequence,
          subFields: child.subFields,
          additionalFieldConfig: child.additionalFieldConfig,
          maxOptionSelection: child.maxOptionSelection,
          prepopulateValue: child.prepopulateValue,
          formula: child.formula,
          config: child.config,
          groupedFieldDisplayStyle: child.groupedFieldDisplayStyle,
          groupHeaders: child.groupHeaders,
          themeConfig: child.themeConfig,
          inheritedID: child.inheritedID,
          linkedFieldID: child.linkedFieldID,
       );
       virtualChildren.add(vf);
       virtualData[virtualId] = vf.fieldValue;
    }
    List<FieldModel> virtualAllFields = [...virtualChildren, ...allFields];
    Map<String, dynamic> proxyFormData = Map.from(formData);
    proxyFormData.addAll(virtualData);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              parentField.fieldName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8),
            ...virtualChildren.map((vField) {
               return DynamicFormField(
                   key: Key(vField.fieldId),
                   field: vField,
                   formData: proxyFormData,
                   displayIndex: 0, 
                   allFields: virtualAllFields,
                   onValueChanged: (id, val) {
                      Map<String, dynamic> newGroupData = {};
                      if (formData[parentField.fieldId] is Map) {
                          newGroupData = Map<String, dynamic>.from(formData[parentField.fieldId]);
                      }
                      newGroupData[vField.fieldName] = val;
                      onValueChanged(parentField.fieldId, newGroupData);
                   },
               );
            }),
          ],
        ),
      ),
    );
  }
}