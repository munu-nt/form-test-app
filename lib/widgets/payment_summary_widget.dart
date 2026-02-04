import 'dart:convert';
import 'package:flutter/material.dart';
import '../models.dart';

class PaymentSummaryWidget extends StatelessWidget {
  final FieldModel field;
  final Map<String, dynamic> formData;
  final List<FieldModel> allFields;
  const PaymentSummaryWidget({
    super.key,
    required this.field,
    required this.formData,
    required this.allFields,
  });
  PaymentConfig _parseConfig() {
    if (field.config != null && field.config!.isNotEmpty) {
      try {
        final decoded = jsonDecode(field.config!);
        return PaymentConfig.fromJson(decoded);
      } catch (e) {
        debugPrint('Error parsing PaymentConfig for ${field.fieldId}: $e');
      }
    }
    return PaymentConfig();
  }

  double _calculateSubtotal() {
    double subtotal = 0.0;
    for (final field in allFields) {
      if (field.fieldOptions != null) {
        for (final option in field.fieldOptions!) {
          final selectedValue = formData[field.fieldId];
          if (selectedValue != null) {
            bool isSelected = false;
            if (selectedValue is List) {
              isSelected = selectedValue.contains(option.value);
            } else if (selectedValue is String) {
              if (selectedValue.contains(',')) {
                isSelected = selectedValue.split(',').contains(option.value);
              } else {
                isSelected = selectedValue == option.value;
              }
            }
            if (isSelected) {
              double amount = 0.0;
              if (option.paymentAmount != null) {
                amount = double.tryParse(option.paymentAmount!) ?? 0.0;
              } else {
                final priceMatch = RegExp(
                  r'[\$£€](\d+(?:\.\d{2})?)',
                ).firstMatch(option.text);
                if (priceMatch != null) {
                  amount = double.tryParse(priceMatch.group(1)!) ?? 0.0;
                }
              }
              subtotal += amount;
            }
          }
        }
      }
    }
    return subtotal;
  }

  double _getDiscount() {
    for (final field in allFields) {
      if (field.fieldType == 'Discount') {
        final discountValue = formData[field.fieldId];
        if (discountValue != null) {
          if (discountValue is double) return discountValue;
          if (discountValue is int) return discountValue.toDouble();
          if (discountValue is String) {
            return double.tryParse(discountValue) ?? 0.0;
          }
        }
      }
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final config = _parseConfig();
    final subtotal = _calculateSubtotal();
    final discount = _getDiscount();
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primaryContainer,
              theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Payment Summary',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _buildSummaryRow(
              context,
              label: config.formAmountLabel,
              value: subtotal,
              currencyType: config.currencyType,
            ),
            const SizedBox(height: 12),
            if (discount > 0) ...[
              _buildSummaryRow(
                context,
                label: config.discountLabel,
                value: -discount,
                currencyType: config.currencyType,
                isDiscount: true,
              ),
              const SizedBox(height: 12),
            ],
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildSummaryRow(
              context,
              label: config.subTotalLabel,
              value: total,
              currencyType: config.currencyType,
              isTotal: true,
            ),
            if (subtotal > 0 && total == 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Discount applied. No payment required.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required String label,
    required double value,
    required String currencyType,
    bool isTotal = false,
    bool isDiscount = false,
  }) {
    final theme = Theme.of(context);
    final valueText =
        '${isDiscount ? '-' : ''}$currencyType${value.abs().toStringAsFixed(2)}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                )
              : theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withValues(
                    alpha: 0.8,
                  ),
                ),
        ),
        Text(
          valueText,
          style: isTotal
              ? theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                )
              : theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDiscount
                      ? theme.colorScheme.error
                      : theme.colorScheme.onPrimaryContainer,
                ),
        ),
      ],
    );
  }
}
