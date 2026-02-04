import 'package:flutter/foundation.dart';
class FormModel {
  final bool status;
  final String? errorType;
  final String formName;
  final String formCategory;
  final String buttonType;
  final List<FieldModel> fields;
  FormModel({
    required this.status,
    this.errorType,
    required this.formName,
    required this.formCategory,
    required this.buttonType,
    required this.fields,
  });
  factory FormModel.fromJson(Map<String, dynamic> json) {
    return FormModel(
      status: json['Status'],
      errorType: json['ErrorType'],
      formName: json['FormName'],
      formCategory: json['FormCategory'],
      buttonType: json['ButtonType'],
      fields: (json['Fields'] as List).map((i) {
            try {
              return FieldModel.fromJson(i);
            } catch (e) {
              print('Error parsing field: ${i['FieldID']} - ${i['FieldName']}');
              print('Error details: $e');
              return FieldModel(
                 fieldId: i['FieldID']?.toString() ?? 'error',
                 fieldName: 'Error Parsing Field',
                 fieldType: 'Error',
                 isMandate: false,
                 isReadOnly: true, 
                 hideField: true,  
              );
            }
          }).toList(),
    );
  }
}
class FieldModel {
  final String fieldId;
  final String fieldName;
  final String fieldType;
  final String? fieldValue;
  final String? fieldMaxLength;
  final bool isMandate;
  final String? sequence;
  final int? index;
  final List<FieldOptionModel>? fieldOptions;
  final bool isReadOnly;
  final bool hideField;
  final String? fieldDescription;
  final bool isGroupedField;
  final int? maxGroupLimit;
  final int? minGroupRequired;
  final String? groupId;
  final int? groupSequence;
  final List<FieldModel>? subFields;
  final CalendarConfig? calendarConfig;
  final String? formula;
  final String? fieldRegex;
  final String? fieldValidationConfig;
  final String? fieldValidationMessage;
  final String? fieldHelpText;
  final String? fieldInfo;
  final String? config;
  final String? groupedFieldDisplayStyle;
  final List<dynamic>? groupHeaders;
  final Map<String, dynamic>? themeConfig;
  final String? inheritedID;
  final String? linkedFieldID;
  final Map<String, dynamic>? fileUploadOption;
  final bool? fieldPaymentEnabled;
  final String? pointsAllocated;
  final bool? fieldOptionPointEnabled;
  final List<dynamic>? additionalFieldValues;
  final List<dynamic>? multiFileUploadOption;
  final String? profileFieldCode;
  final String? programLenthList;
  final String? optionFieldAutoSelectConfig;
  final bool? enableDefaultFieldConfig;
  final List<dynamic>? additionalFieldConfig;
  final int? maxOptionSelection;
  final bool? prepopulateValue;
  final List<FieldDependencyConfig>? fieldDependencyConfig;
  final bool isDependent;
  FieldModel({
    required this.fieldId,
    required this.fieldName,
    required this.fieldType,
    this.fieldValue,
    this.fieldMaxLength,
    required this.isMandate,
    this.sequence,
    this.index,
    this.fieldOptions,
    required this.isReadOnly,
    required this.hideField,
    this.fieldDescription,
    this.isGroupedField = false,
    this.maxGroupLimit,
    this.minGroupRequired,
    this.groupId,
    this.groupSequence,
    this.subFields,
    this.calendarConfig,
    this.fieldDependencyConfig,
    this.isDependent = false,
    this.formula,
    this.fieldRegex,
    this.fieldValidationConfig,
    this.fieldValidationMessage,
    this.fieldHelpText,
    this.fieldInfo,
    this.config,
    this.groupedFieldDisplayStyle,
    this.groupHeaders,
    this.themeConfig,
    this.inheritedID,
    this.linkedFieldID,
    this.fileUploadOption,
    this.fieldPaymentEnabled,
    this.pointsAllocated,
    this.fieldOptionPointEnabled,
    this.additionalFieldValues,
    this.multiFileUploadOption,
    this.profileFieldCode,
    this.programLenthList,
    this.optionFieldAutoSelectConfig,
    this.enableDefaultFieldConfig,
    this.additionalFieldConfig,
    this.maxOptionSelection,
    this.prepopulateValue,
  });
  factory FieldModel.fromJson(Map<String, dynamic> json) {
    List<FieldModel>? subFields;
    if (json['SubFieldList'] != null) {
      final list = json['SubFieldList'] as List;
      if (list.isNotEmpty) {
        try {
          if (list[0] is List) {
             subFields = (list[0] as List)
                 .map((i) => FieldModel.fromJson(i))
                 .toList();
          } else {
             subFields = list
                 .map((i) => FieldModel.fromJson(i))
                 .toList();
          }
        } catch (e) {
          debugPrint('Error parsing SubFieldList for ${json['FieldID']}: $e');
        }
      }
    }
    return FieldModel(
      fieldId: json['FieldID'],
      fieldName: json['FieldName'],
      fieldType: json['FieldType'],
      fieldValue: json['FieldValue'],
      fieldMaxLength: json['FieldMaxLength'],
      isMandate: json['IsMandate'],
      sequence: json['Sequence'],
      index: json['Index'] != null
          ? int.tryParse(json['Index'].toString())
          : null,
      fieldOptions: json['FieldOptions'] != null
          ? (json['FieldOptions'] as List)
              .map((i) => FieldOptionModel.fromJson(i))
              .toList()
          : null,
      isReadOnly: json['IsReadOnly'] ?? false,
      hideField: json['HideField'] ?? false,
      fieldDescription: json['FieldDescription'],
      isGroupedField: json['IsGroupedField'] ?? false,
      maxGroupLimit: json['MaxGroupLimit'] != null 
          ? int.tryParse(json['MaxGroupLimit'].toString()) 
          : null,
      minGroupRequired: json['MinGroupRequired'] != null 
          ? int.tryParse(json['MinGroupRequired'].toString()) 
          : null,
      groupId: json['GroupId'],
      groupSequence: json['GroupSequence'] != null
          ? int.tryParse(json['GroupSequence'].toString())
          : null,
      subFields: subFields,
      calendarConfig: json['CalendarConfig'] != null
          ? CalendarConfig.fromJson(json['CalendarConfig'])
          : null,
      fieldDependencyConfig: json['FieldDependencyConfig'] != null
          ? (json['FieldDependencyConfig'] as List)
              .map((i) => FieldDependencyConfig.fromJson(i))
              .toList()
          : null,
      isDependent: json['IsDependent'] ?? false,
      formula: json['Formula'],
      fieldRegex: json['FieldRegex'],
      fieldValidationConfig: json['FieldValidationConfig'],
      fieldValidationMessage: json['FieldValidationMessage'],
      fieldHelpText: json['FieldHelpText'],
      fieldInfo: json['FieldInfo'],
      config: json['Config'],
      groupedFieldDisplayStyle: json['GroupedFieldDisplayStyle'],
      groupHeaders: json['GroupHeaders'],
      themeConfig: json['ThemeConfig'],
      inheritedID: json['InheritedID'],
      linkedFieldID: json['LinkedFieldID'],
      fileUploadOption: json['FileUploadOption'],
      fieldPaymentEnabled: json['FieldPaymentEnabled'],
      pointsAllocated: json['PointsAllocated'],
      fieldOptionPointEnabled: json['FieldOptionPointEnabled'],
      additionalFieldValues: json['AdditionalFieldValues'],
      multiFileUploadOption: json['MultiFileUploadOption'],
      profileFieldCode: json['ProfileFieldCode'],
      programLenthList: json['ProgramLenthList'],
      optionFieldAutoSelectConfig: json['OptionFieldAutoSelectConfig'],
      enableDefaultFieldConfig: json['EnableDefaultFieldConfig'],
      additionalFieldConfig: json['AdditionalFieldConfig'] is List
          ? json['AdditionalFieldConfig']
          : (json['AdditionalFieldConfig'] != null
              ? [json['AdditionalFieldConfig']]
              : null),
      maxOptionSelection: json['MaxOptionSelection'],
      prepopulateValue: json['PrepopulateValue'],
    );
  }
}
class FieldOptionModel {
  final String value;
  final String text;
  final String? code;
  final String? parentCode;
  final int? index;
  final String? paymentAmount;
  FieldOptionModel({
    required this.value,
    required this.text,
    this.code,
    this.parentCode,
    this.index,
    this.paymentAmount,
  });
  factory FieldOptionModel.fromJson(Map<String, dynamic> json) {
    return FieldOptionModel(
      value: json['Value'].toString(),
      text: json['Text'],
      code: json['Code'],
      parentCode: json['ParentCode'],
      index: json['Index'] != null
          ? int.tryParse(json['Index'].toString())
          : null,
      paymentAmount: json['PaymentAmount']?.toString(),
    );
  }
}
class FieldDependencyConfig {
  final String dependencyType;
  final String dependencyTypeId;
  final int selectionCount;
  final String? selectOptionId;
  final bool disablePossibleMatch;
  FieldDependencyConfig({
    required this.dependencyType,
    required this.dependencyTypeId,
    this.selectionCount = 0,
    this.selectOptionId,
    this.disablePossibleMatch = false,
  });
  factory FieldDependencyConfig.fromJson(Map<String, dynamic> json) {
    return FieldDependencyConfig(
      dependencyType: json['DependencyType'] ?? '',
      dependencyTypeId: json['DependencyTypeID']?.toString() ?? '',
      selectionCount: json['SelectionCount'] ?? 0,
      selectOptionId: json['SelectOptionId']?.toString(),
      disablePossibleMatch: json['DisablePossibleMatch'] ?? false,
    );
  }
  List<String> get dependencyTypeIds {
    if (dependencyTypeId.isEmpty) return [];
    return dependencyTypeId.split(',').map((e) => e.trim()).toList();
  }
}
class GroupInstance {
  final String id;
  final Map<String, dynamic> data;
  bool isExpanded;
  GroupInstance({
    required this.id,
    Map<String, dynamic>? data,
    this.isExpanded = true,
  }) : data = data ?? {};
  GroupInstance copyWith({
    String? id,
    Map<String, dynamic>? data,
    bool? isExpanded,
  }) {
    return GroupInstance(
      id: id ?? this.id,
      data: data ?? Map.from(this.data),
      isExpanded: isExpanded ?? this.isExpanded,
    );
  }
}
class CalendarConfig {
  final String? limitType;
  final String? minDate;
  final String? maxDate;
  final String? dependentField;
  final int? dependentInterval;
  final List<String>? allowedDates;
  final RestrictedDates? restrictedDates;
  CalendarConfig({
    this.limitType,
    this.minDate,
    this.maxDate,
    this.dependentField,
    this.dependentInterval,
    this.allowedDates,
    this.restrictedDates,
  });
  factory CalendarConfig.fromJson(Map<String, dynamic> json) {
    return CalendarConfig(
      limitType: json['LimitType'],
      minDate: json['MinDate'],
      maxDate: json['MaxDate'],
      dependentField: json['DependentField'],
      dependentInterval: json['DependentInterval'] != null
          ? int.tryParse(json['DependentInterval'].toString())
          : null,
      allowedDates: json['AllowedDates'] != null
          ? List<String>.from(json['AllowedDates'])
          : null,
      restrictedDates: json['RestrictedDates'] != null
          ? RestrictedDates.fromJson(json['RestrictedDates'])
          : null,
    );
  }
}
class RestrictedDates {
  final List<String>? customDates;
  final List<int>? daysOfMonths;
  final List<int>? months;
  final List<int>? weekDays;
  RestrictedDates({
    this.customDates,
    this.daysOfMonths,
    this.months,
    this.weekDays,
  });
  factory RestrictedDates.fromJson(Map<String, dynamic> json) {
    return RestrictedDates(
      customDates: json['CustomDates'] != null
          ? List<String>.from(json['CustomDates'])
          : null,
      daysOfMonths: json['DaysOfMonths'] != null
          ? List<int>.from(json['DaysOfMonths'].map((e) => int.tryParse(e.toString()) ?? e))
          : null,
      months: json['Months'] != null
          ? List<int>.from(json['Months'].map((e) => int.tryParse(e.toString()) ?? e))
          : null,
      weekDays: json['WeekDays'] != null
          ? List<int>.from(json['WeekDays'].map((e) => int.tryParse(e.toString()) ?? e))
          : null,
    );
  }
}
class AppointmentSlot {
  final String id;
  final String time;
  final int availableSeats;
  final int maxSeats;
  final bool isAvailable;
  AppointmentSlot({
    required this.id,
    required this.time,
    required this.availableSeats,
    required this.maxSeats,
    this.isAvailable = true,
  });
  factory AppointmentSlot.fromJson(Map<String, dynamic> json) {
    return AppointmentSlot(
      id: json['Id'] ?? json['id'] ?? '',
      time: json['Time'] ?? json['time'] ?? '',
      availableSeats: int.tryParse(json['AvailableSeats']?.toString() ?? '0') ?? 0,
      maxSeats: int.tryParse(json['MaxSeats']?.toString() ?? '1') ?? 1,
      isAvailable: json['IsAvailable'] ?? json['isAvailable'] ?? true,
    );
  }
}
class LocationData {
  final double latitude;
  final double longitude;
  final String? address;
  final String? city;
  final String? country;
  final String? postalCode;
  LocationData({
    required this.latitude,
    required this.longitude,
    this.address,
    this.city,
    this.country,
    this.postalCode,
  });
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'country': country,
      'postalCode': postalCode,
    };
  }
  @override
  String toString() {
    if (address != null && address!.isNotEmpty) {
      return address!;
    }
    return '$latitude, $longitude';
  }
}
class MediaFile {
  final String id;
  final String name;
  final String path;
  final String? mimeType;
  final int? sizeBytes;
  final double uploadProgress;
  final bool isUploading;
  final bool isUploaded;
  final String? errorMessage;
  final String? thumbnailPath;
  MediaFile({
    required this.id,
    required this.name,
    required this.path,
    this.mimeType,
    this.sizeBytes,
    this.uploadProgress = 0.0,
    this.isUploading = false,
    this.isUploaded = false,
    this.errorMessage,
    this.thumbnailPath,
  });
  MediaFile copyWith({
    String? id,
    String? name,
    String? path,
    String? mimeType,
    int? sizeBytes,
    double? uploadProgress,
    bool? isUploading,
    bool? isUploaded,
    String? errorMessage,
    String? thumbnailPath,
  }) {
    return MediaFile(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      mimeType: mimeType ?? this.mimeType,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      isUploading: isUploading ?? this.isUploading,
      isUploaded: isUploaded ?? this.isUploaded,
      errorMessage: errorMessage,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
  String get formattedSize {
    if (sizeBytes == null) return '';
    if (sizeBytes! < 1024) return '$sizeBytes B';
    if (sizeBytes! < 1024 * 1024) return '${(sizeBytes! / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
class PaymentConfig {
  final String amountPayableLabel;
  final String discountLabel;
  final String subTotalLabel;
  final String currencyType;
  final String formAmountLabel;
  final List<PriceCalculationItem> priceCalculationList;
  PaymentConfig({
    this.amountPayableLabel = 'Amount Payable',
    this.discountLabel = 'Discount',
    this.subTotalLabel = 'Total Due',
    this.currencyType = '\$',
    this.formAmountLabel = 'Subtotal',
    this.priceCalculationList = const [],
  });
  factory PaymentConfig.fromJson(Map<String, dynamic> json) {
    List<PriceCalculationItem> items = [];
    if (json['PaymentCalulationConfigList'] != null) {
      items = (json['PaymentCalulationConfigList'] as List)
          .map((e) => PriceCalculationItem.fromJson(e))
          .toList();
    }
    return PaymentConfig(
      amountPayableLabel: json['AmountPayableLabel'] ?? 'Total Amount',
      discountLabel: json['DiscountLabel'] ?? 'Discount',
      subTotalLabel: json['SubTotalLabel'] ?? 'Grand Total',
      currencyType: json['CurrencyType'] ?? '\$',
      formAmountLabel: json['FormAmountLabel'] ?? 'Form Amount',
      priceCalculationList: items,
    );
  }
}
class PriceCalculationItem {
  final String priceCalculationId;
  final String name;
  final String fieldId;
  final String fieldName;
  final List<String> fieldValues;
  final List<String> fieldOptionTexts;
  final int sequence;
  PriceCalculationItem({
    required this.priceCalculationId,
    required this.name,
    required this.fieldId,
    required this.fieldName,
    required this.fieldValues,
    required this.fieldOptionTexts,
    required this.sequence,
  });
  factory PriceCalculationItem.fromJson(Map<String, dynamic> json) {
    return PriceCalculationItem(
      priceCalculationId: json['PriceCalculationId'] ?? '',
      name: json['Name'] ?? '',
      fieldId: json['FieldId'] ?? '',
      fieldName: json['FieldName'] ?? '',
      fieldValues: json['FieldValues'] != null 
          ? List<String>.from(json['FieldValues']) 
          : [],
      fieldOptionTexts: json['FieldOptionTexts'] != null 
          ? List<String>.from(json['FieldOptionTexts']) 
          : [],
      sequence: json['Sequence'] ?? 0,
    );
  }
}
class SequenceNumberConfig {
  final int startingNumber;
  final int startingNumberLength;
  final String prefix;
  final String suffix;
  final bool hideFieldName;
  SequenceNumberConfig({
    this.startingNumber = 1,
    this.startingNumberLength = 4,
    this.prefix = '',
    this.suffix = '',
    this.hideFieldName = false,
  });
  factory SequenceNumberConfig.fromJson(Map<String, dynamic> json) {
    return SequenceNumberConfig(
      startingNumber: json['StartingNumber'] ?? 1,
      startingNumberLength: json['StartingNumberLength'] ?? 4,
      prefix: json['Prefix'] ?? '',
      suffix: json['Suffix'] ?? '',
      hideFieldName: json['HideFieldName'] ?? false,
    );
  }
  String generateSequence([int? number]) {
    final num = number ?? startingNumber;
    final paddedNum = num.toString().padLeft(startingNumberLength, '0');
    return '$prefix$paddedNum$suffix';
  }
}