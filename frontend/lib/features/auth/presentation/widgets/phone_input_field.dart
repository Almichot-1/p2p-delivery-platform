import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class PhoneInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool enabled;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.validator,
    this.onChanged,
    this.enabled = true,
  });

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  String _selectedCountryCode = '+1';

  final List<Map<String, String>> _countryCodes = [
    {'code': '+1', 'country': 'US', 'flag': '🇺🇸'},
    {'code': '+251', 'country': 'ET', 'flag': '🇪🇹'},
    {'code': '+44', 'country': 'UK', 'flag': '🇬🇧'},
    {'code': '+971', 'country': 'AE', 'flag': '🇦🇪'},
    {'code': '+1', 'country': 'CA', 'flag': '🇨🇦'},
    {'code': '+49', 'country': 'DE', 'flag': '🇩🇪'},
    {'code': '+966', 'country': 'SA', 'flag': '🇸🇦'},
    {'code': '+27', 'country': 'ZA', 'flag': '🇿🇦'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Country code dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: const BoxDecoration(
                  border: Border(
                    right: BorderSide(color: AppColors.grey300),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCountryCode,
                    items: _countryCodes.map((country) {
                      return DropdownMenuItem(
                        value: country['code'],
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              country['flag']!,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              country['code']!,
                              style: AppTextStyles.bodyMedium,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: widget.enabled
                        ? (value) {
                            setState(() {
                              _selectedCountryCode = value!;
                            });
                          }
                        : null,
                  ),
                ),
              ),

              // Phone number input
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(15),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.grey500,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: widget.validator,
                  onChanged: (value) {
                    widget.onChanged?.call('$_selectedCountryCode$value');
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
