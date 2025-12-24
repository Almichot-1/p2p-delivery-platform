import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/dependency_injection.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../bloc/trip_bloc.dart';
import '../../bloc/trip_event.dart';
import '../../bloc/trip_state.dart';
import '../../data/models/trip_model.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _capacityController = TextEditingController();
  final _priceController = TextEditingController();
  final _notesController = TextEditingController();

  String? _originCity;
  String? _destinationCity;
  DateTime? _departureDate;
  DateTime? _returnDate;
  final List<String> _acceptedItemTypes = [];

  final List<String> _itemTypes = [
    'Documents',
    'Electronics',
    'Clothing',
    'Food Items',
    'Medicine',
    'Gifts',
    'Other',
  ];

  @override
  void dispose() {
    _capacityController.dispose();
    _priceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onCreatePressed() {
    if (_formKey.currentState!.validate()) {
      if (_originCity == null || _destinationCity == null) {
        Helpers.showErrorSnackBar(
            context, 'Please select origin and destination');
        return;
      }
      if (_departureDate == null) {
        Helpers.showErrorSnackBar(context, 'Please select departure date');
        return;
      }

      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticated) return;

      final user = authState.user;

      final trip = TripModel(
        id: '',
        travelerId: user.uid,
        travelerName: user.fullName,
        travelerPhoto: user.photoUrl,
        travelerRating: user.rating,
        originCity: _originCity!.split(',').first.trim(),
        originCountry: _originCity!.split(',').last.trim(),
        destinationCity: _destinationCity!.split(',').first.trim(),
        destinationCountry: _destinationCity!.split(',').last.trim(),
        departureDate: _departureDate!,
        returnDate: _returnDate,
        availableCapacityKg: double.parse(_capacityController.text),
        pricePerKg: _priceController.text.isEmpty
            ? 0.0
            : double.parse(_priceController.text),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        acceptedItemTypes: _acceptedItemTypes,
        createdAt: DateTime.now(),
      );

      context.read<TripBloc>().add(TripCreateRequested(trip));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TripBloc>(),
      child: BlocListener<TripBloc, TripState>(
        listener: (context, state) {
          if (state is TripCreated) {
            Helpers.showSuccessSnackBar(context, 'Trip created successfully!');
            context.pop();
          } else if (state is TripError) {
            Helpers.showErrorSnackBar(context, state.message);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Post a Trip'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Origin
                  const Text('Origin', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  _buildCityDropdown(
                    value: _originCity,
                    hint: 'Select departure city',
                    cities: AppConstants.internationalCities,
                    onChanged: (value) => setState(() => _originCity = value),
                  ),
                  const SizedBox(height: 20),

                  // Destination
                  const Text('Destination', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  _buildCityDropdown(
                    value: _destinationCity,
                    hint: 'Select destination city',
                    cities: AppConstants.ethiopianCities
                        .map((c) => '$c, Ethiopia')
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _destinationCity = value),
                  ),
                  const SizedBox(height: 20),

                  // Departure Date
                  const Text('Departure Date', style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  _buildDatePicker(
                    value: _departureDate,
                    hint: 'Select departure date',
                    onChanged: (date) => setState(() => _departureDate = date),
                  ),
                  const SizedBox(height: 20),

                  // Return Date (Optional)
                  const Text('Return Date (Optional)',
                      style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  _buildDatePicker(
                    value: _returnDate,
                    hint: 'Select return date',
                    onChanged: (date) => setState(() => _returnDate = date),
                    firstDate: _departureDate,
                  ),
                  const SizedBox(height: 20),

                  // Available Capacity
                  CustomTextField(
                    label: 'Available Capacity (kg)',
                    hint: 'Enter available weight in kg',
                    controller: _capacityController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.fitness_center,
                    validator: Validators.weight,
                  ),
                  const SizedBox(height: 20),

                  // Price per kg (Optional)
                  CustomTextField(
                    label: 'Price per kg (Optional)',
                    hint: 'Enter price in USD',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.attach_money,
                  ),
                  const SizedBox(height: 20),

                  // Accepted Item Types
                  const Text('Accepted Item Types',
                      style: AppTextStyles.labelLarge),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _itemTypes.map((type) {
                      final isSelected = _acceptedItemTypes.contains(type);
                      return FilterChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _acceptedItemTypes.add(type);
                            } else {
                              _acceptedItemTypes.remove(type);
                            }
                          });
                        },
                        selectedColor: AppColors.primary.withAlpha(51),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Notes
                  CustomTextField(
                    label: 'Additional Notes (Optional)',
                    hint: 'Any special instructions or requirements',
                    controller: _notesController,
                    maxLines: 3,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 32),

                  // Create Button
                  BlocBuilder<TripBloc, TripState>(
                    builder: (context, state) {
                      return CustomButton(
                        text: 'Post Trip',
                        onPressed: _onCreatePressed,
                        isLoading: state is TripLoading,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCityDropdown({
    required String? value,
    required String hint,
    required List<String> cities,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint),
          isExpanded: true,
          items: cities.map((city) {
            return DropdownMenuItem(
              value: city,
              child: Text(city),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker({
    required DateTime? value,
    required String hint,
    required ValueChanged<DateTime?> onChanged,
    DateTime? firstDate,
  }) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: firstDate ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onChanged(date);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppColors.grey600),
            const SizedBox(width: 12),
            Text(
              value != null ? DateFormat('MMM dd, yyyy').format(value) : hint,
              style: AppTextStyles.bodyMedium.copyWith(
                color: value != null
                    ? AppColors.textPrimaryLight
                    : AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
