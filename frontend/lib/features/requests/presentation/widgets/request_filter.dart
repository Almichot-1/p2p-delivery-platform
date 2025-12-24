import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../data/models/request_model.dart';

class RequestFilter extends StatefulWidget {
  final String? selectedCity;
  final ItemCategory? selectedCategory;
  final double? maxWeight;
  final Function(String?, ItemCategory?, double?) onApply;

  const RequestFilter({
    super.key,
    this.selectedCity,
    this.selectedCategory,
    this.maxWeight,
    required this.onApply,
  });

  @override
  State<RequestFilter> createState() => _RequestFilterState();
}

class _RequestFilterState extends State<RequestFilter> {
  late String? _selectedCity;
  late ItemCategory? _selectedCategory;
  late double _maxWeight;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.selectedCity;
    _selectedCategory = widget.selectedCategory;
    _maxWeight = widget.maxWeight ?? 50;
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
              const Text('Filter Requests', style: AppTextStyles.h5),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedCity = null;
                    _selectedCategory = null;
                    _maxWeight = 50;
                  });
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Delivery City
          const Text('Delivery City', style: AppTextStyles.labelLarge),
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

          // Category
          const Text('Category', style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ItemCategory.values.map((category) {
              final isSelected = _selectedCategory == category;
              return ChoiceChip(
                label: Text(category.name.toUpperCase()),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : null;
                  });
                },
                selectedColor: AppColors.primary.withAlpha(51),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Max Weight
          Text('Maximum Weight: ${_maxWeight.toStringAsFixed(0)} kg',
              style: AppTextStyles.labelLarge),
          const SizedBox(height: 8),
          Slider(
            value: _maxWeight,
            min: 1,
            max: 50,
            divisions: 49,
            label: '${_maxWeight.toStringAsFixed(0)} kg',
            onChanged: (value) {
              setState(() {
                _maxWeight = value;
              });
            },
          ),
          const SizedBox(height: 32),

          // Apply Button
          CustomButton(
            text: 'Apply Filters',
            onPressed: () => widget.onApply(
              _selectedCity,
              _selectedCategory,
              _maxWeight < 50 ? _maxWeight : null,
            ),
          ),
        ],
      ),
    );
  }
}
