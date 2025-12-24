import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
import '../../bloc/request_bloc.dart';
import '../../bloc/request_event.dart';
import '../../bloc/request_state.dart';
import '../../data/models/request_model.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _weightController = TextEditingController();
  final _pickupAddressController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _recipientNameController = TextEditingController();
  final _recipientPhoneController = TextEditingController();
  final _priceController = TextEditingController();

  String? _pickupCity;
  String? _deliveryCity;
  ItemCategory _category = ItemCategory.other;
  DateTime? _preferredDate;
  bool _isUrgent = false;
  final List<File> _selectedImages = [];
  final _imagePicker = ImagePicker();

  int _currentStep = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _weightController.dispose();
    _pickupAddressController.dispose();
    _deliveryAddressController.dispose();
    _recipientNameController.dispose();
    _recipientPhoneController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage(
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );

    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(
          images.take(5 - _selectedImages.length).map((e) => File(e.path)),
        );
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _onCreatePressed() {
    if (!_formKey.currentState!.validate()) return;

    if (_pickupCity == null || _deliveryCity == null) {
      Helpers.showErrorSnackBar(
          context, 'Please select pickup and delivery cities');
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;

    final request = RequestModel(
      id: '',
      requesterId: user.uid,
      requesterName: user.fullName,
      requesterPhoto: user.photoUrl,
      requesterRating: user.rating,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      weightKg: double.parse(_weightController.text),
      pickupCity: _pickupCity!.split(',').first.trim(),
      pickupCountry: _pickupCity!.split(',').last.trim(),
      pickupAddress: _pickupAddressController.text.trim(),
      deliveryCity: _deliveryCity!.split(',').first.trim(),
      deliveryCountry: _deliveryCity!.split(',').last.trim(),
      deliveryAddress: _deliveryAddressController.text.trim(),
      recipientName: _recipientNameController.text.trim(),
      recipientPhone: _recipientPhoneController.text.trim(),
      preferredDeliveryDate: _preferredDate,
      offeredPrice: _priceController.text.isNotEmpty
          ? double.parse(_priceController.text)
          : null,
      isUrgent: _isUrgent,
      createdAt: DateTime.now(),
    );

    context.read<RequestBloc>().add(
          RequestCreateRequested(
            request,
            images: _selectedImages.isNotEmpty ? _selectedImages : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RequestBloc>(),
      child: BlocListener<RequestBloc, RequestState>(
        listener: (context, state) {
          if (state is RequestCreated) {
            Helpers.showSuccessSnackBar(
                context, 'Request created successfully!');
            context.pop();
          } else if (state is RequestError) {
            Helpers.showErrorSnackBar(context, state.message);
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Create Request'),
          ),
          body: Form(
            key: _formKey,
            child: Stepper(
              currentStep: _currentStep,
              onStepContinue: () {
                if (_currentStep < 3) {
                  setState(() => _currentStep++);
                } else {
                  _onCreatePressed();
                }
              },
              onStepCancel: () {
                if (_currentStep > 0) {
                  setState(() => _currentStep--);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: BlocBuilder<RequestBloc, RequestState>(
                          builder: (context, state) {
                            return CustomButton(
                              text: _currentStep == 3 ? 'Submit' : 'Continue',
                              onPressed: details.onStepContinue,
                              isLoading: state is RequestLoading,
                            );
                          },
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomButton(
                            text: 'Back',
                            type: ButtonType.outline,
                            onPressed: details.onStepCancel,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                // Step 1: Item Details
                Step(
                  title: const Text('Item Details'),
                  isActive: _currentStep >= 0,
                  state:
                      _currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: _buildItemDetailsStep(),
                ),

                // Step 2: Pickup & Delivery
                Step(
                  title: const Text('Locations'),
                  isActive: _currentStep >= 1,
                  state:
                      _currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: _buildLocationsStep(),
                ),

                // Step 3: Recipient
                Step(
                  title: const Text('Recipient'),
                  isActive: _currentStep >= 2,
                  state:
                      _currentStep > 2 ? StepState.complete : StepState.indexed,
                  content: _buildRecipientStep(),
                ),

                // Step 4: Images & Price
                Step(
                  title: const Text('Photos & Price'),
                  isActive: _currentStep >= 3,
                  state:
                      _currentStep > 3 ? StepState.complete : StepState.indexed,
                  content: _buildPhotosStep(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemDetailsStep() {
    return Column(
      children: [
        CustomTextField(
          label: 'Item Title',
          hint: 'e.g., Traditional Ethiopian Coffee',
          controller: _titleController,
          prefixIcon: Icons.inventory_2,
          validator: (v) => Validators.required(v, 'Title'),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Description',
          hint: 'Describe the item you want to send',
          controller: _descriptionController,
          maxLines: 3,
          validator: (v) => Validators.required(v, 'Description'),
        ),
        const SizedBox(height: 16),
        const Text('Category', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ItemCategory.values.map((cat) {
            final isSelected = _category == cat;
            return ChoiceChip(
              label: Text(cat.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _category = cat);
              },
              selectedColor: AppColors.primary.withAlpha(51),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Weight (kg)',
          hint: 'Estimated weight',
          controller: _weightController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.fitness_center,
          validator: Validators.weight,
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Urgent Delivery'),
          subtitle: const Text('Mark as urgent for faster matching'),
          value: _isUrgent,
          onChanged: (value) => setState(() => _isUrgent = value),
          activeThumbColor: AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildLocationsStep() {
    return Column(
      children: [
        const Text('Pickup Location', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        _buildCityDropdown(
          value: _pickupCity,
          hint: 'Select pickup city',
          cities: AppConstants.internationalCities,
          onChanged: (v) => setState(() => _pickupCity = v),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'Pickup Address',
          hint: 'Detailed pickup address',
          controller: _pickupAddressController,
          prefixIcon: Icons.location_on,
          validator: (v) => Validators.required(v, 'Pickup address'),
        ),
        const SizedBox(height: 24),
        const Text('Delivery Location', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        _buildCityDropdown(
          value: _deliveryCity,
          hint: 'Select delivery city',
          cities:
              AppConstants.ethiopianCities.map((c) => '$c, Ethiopia').toList(),
          onChanged: (v) => setState(() => _deliveryCity = v),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          label: 'Delivery Address',
          hint: 'Detailed delivery address',
          controller: _deliveryAddressController,
          prefixIcon: Icons.location_on,
          validator: (v) => Validators.required(v, 'Delivery address'),
        ),
        const SizedBox(height: 16),
        const Text('Preferred Delivery Date (Optional)',
            style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        _buildDatePicker(),
      ],
    );
  }

  Widget _buildRecipientStep() {
    return Column(
      children: [
        CustomTextField(
          label: 'Recipient Name',
          hint: 'Full name of the recipient',
          controller: _recipientNameController,
          prefixIcon: Icons.person,
          validator: (v) => Validators.required(v, 'Recipient name'),
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Recipient Phone',
          hint: '+251 91 234 5678',
          controller: _recipientPhoneController,
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone,
          validator: Validators.phone,
        ),
      ],
    );
  }

  Widget _buildPhotosStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Item Photos', style: AppTextStyles.labelLarge),
        const SizedBox(height: 8),
        const Text(
          'Add up to 5 photos of your item',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 12),
        _buildImageGrid(),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'Offered Price (Optional)',
          hint: 'Price you\'re willing to pay in USD',
          controller: _priceController,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.attach_money,
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        ..._selectedImages.asMap().entries.map((entry) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(entry.value, fit: BoxFit.cover),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeImage(entry.key),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
        if (_selectedImages.length < 5)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.grey300,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate, color: AppColors.grey500),
                  SizedBox(height: 4),
                  Text(
                    'Add Photo',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
            ),
          ),
      ],
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
            return DropdownMenuItem(value: city, child: Text(city));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 7)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          setState(() => _preferredDate = date);
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
              _preferredDate != null
                  ? DateFormat('MMM dd, yyyy').format(_preferredDate!)
                  : 'Select preferred date',
              style: AppTextStyles.bodyMedium.copyWith(
                color: _preferredDate != null
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
