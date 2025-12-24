import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';

class TripFilter extends StatefulWidget {
  final String? selectedCity;
  final DateTime? selectedDate;
  final Function(String?, DateTime?) onApply;

  const TripFilter({
    super.key,
    this.selectedCity,
    this.selectedDate,
    required this.onApply,
  });

  @override
  State<TripFilter> createState() => _TripFilterState();
}

class _TripFilterState extends State<TripFilter> {
  late String? _selectedCity;
  late DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.selectedCity;
    _selectedDate = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Filter Trips', style: AppTextStyles.h5),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCity = null;
                    _selectedDate = null;
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Destination
          const Text('Destination', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AppConstants.ethiopianCities.map((city) {
              final isSelected = _selectedCity == city;
              return ChoiceChip(
                label: Text(city),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCity = selected ? city : null;
                  });
                },
                selectedColor: AppColors.primary.withAlpha(51),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Date
          const Text('Departure Date', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                setState(() => _selectedDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: AppColors.grey600),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDate != null
                        ? DateFormat('MMM dd, yyyy').format(_selectedDate!)
                        : 'Select date',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const Spacer(),
                  if (_selectedDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _selectedDate = null),
                      child: const Icon(Icons.close, color: AppColors.grey600),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Apply Button
          CustomButton(
            text: 'Apply Filters',
            onPressed: () => widget.onApply(_selectedCity, _selectedDate),
          ),
        ],
      ),
    );
  }
}
