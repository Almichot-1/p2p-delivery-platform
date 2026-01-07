import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../bloc/request_bloc.dart';
import '../../bloc/request_event.dart';
import '../../bloc/request_state.dart';
import '../../data/models/request_model.dart';
import '../widgets/image_picker_grid.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({
    super.key,
    this.existing,
  });

  final RequestModel? existing;

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _form1 = GlobalKey<FormState>();
  final _form2 = GlobalKey<FormState>();
  final _form3 = GlobalKey<FormState>();
  final _form4 = GlobalKey<FormState>();

  int _step = 0;

  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();
  RequestCategory? _category;

  final TextEditingController _pickupCityCtrl = TextEditingController();
  final TextEditingController _pickupCountryCtrl = TextEditingController();
  final TextEditingController _pickupAddressCtrl = TextEditingController();

  final TextEditingController _deliveryCityCtrl = TextEditingController();
  final TextEditingController _deliveryCountryCtrl = TextEditingController();
  final TextEditingController _deliveryAddressCtrl = TextEditingController();

  final TextEditingController _recipientNameCtrl = TextEditingController();
  final TextEditingController _recipientPhoneCtrl = TextEditingController();

  DateTime? _preferredDeliveryDate;
  final TextEditingController _offeredPriceCtrl = TextEditingController();
  bool _isUrgent = false;

  List<File> _localImages = <File>[];
  List<String> _uploadedUrls = <String>[];

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existing;
    if (existing != null) {
      _titleCtrl.text = existing.title;
      _descriptionCtrl.text = existing.description;
      _weightCtrl.text = existing.weightKg.toStringAsFixed(1);
      _category = existing.category;

      _pickupCityCtrl.text = existing.pickupCity;
      _pickupCountryCtrl.text = existing.pickupCountry;
      _pickupAddressCtrl.text = existing.pickupAddress;

      _deliveryCityCtrl.text = existing.deliveryCity;
      _deliveryCountryCtrl.text = existing.deliveryCountry;
      _deliveryAddressCtrl.text = existing.deliveryAddress;

      _recipientNameCtrl.text = existing.recipientName;
      _recipientPhoneCtrl.text = existing.recipientPhone;

      _preferredDeliveryDate = existing.preferredDeliveryDate;
      _offeredPriceCtrl.text = existing.offeredPrice?.toStringAsFixed(2) ?? '';
      _isUrgent = existing.isUrgent;

      _uploadedUrls = List<String>.of(existing.imageUrls);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _weightCtrl.dispose();
    _pickupCityCtrl.dispose();
    _pickupCountryCtrl.dispose();
    _pickupAddressCtrl.dispose();
    _deliveryCityCtrl.dispose();
    _deliveryCountryCtrl.dispose();
    _deliveryAddressCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _offeredPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPreferredDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferredDeliveryDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );

    if (picked == null) return;
    setState(() => _preferredDeliveryDate = picked);
  }

  Future<void> _pickImages() async {
    final remaining = 5 - (_uploadedUrls.length + _localImages.length);
    if (remaining <= 0) return;

    final picker = ImagePicker();
    final picks = await picker.pickMultiImage(imageQuality: 85);

    if (picks.isEmpty) return;

    final next = List<File>.of(_localImages);
    for (final x in picks) {
      if ((_uploadedUrls.length + next.length) >= 5) break;
      next.add(File(x.path));
    }

    setState(() => _localImages = next);
  }

  void _removeUploadedUrl(String url) {
    setState(() => _uploadedUrls = List<String>.of(_uploadedUrls)..remove(url));
  }

  bool _validateCurrentStep() {
    final key = switch (_step) {
      0 => _form1,
      1 => _form2,
      2 => _form3,
      _ => _form4,
    };
    final ok = key.currentState?.validate() ?? false;
    if (_step == 0 && _category == null) return false;
    return ok;
  }

  Future<void> _submit(BuildContext blocContext) async {
    final a1 = _form1.currentState?.validate() ?? false;
    final a2 = _form2.currentState?.validate() ?? false;
    final a3 = _form3.currentState?.validate() ?? false;
    final a4 = _form4.currentState?.validate() ?? false;

    if (!a1 || !a2 || !a3 || !a4 || _category == null) {
      setState(() => _step = 0);
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to create a request')),
      );
      return;
    }

    final weight = double.tryParse(_weightCtrl.text.trim());
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid weight')),
      );
      return;
    }

    final offeredPriceText = _offeredPriceCtrl.text.trim();
    final offeredPrice =
        offeredPriceText.isEmpty ? null : double.tryParse(offeredPriceText);

    final now = DateTime.now();

    if (_isEdit) {
      final existing = widget.existing!;
      final updated = existing.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        category: _category,
        weightKg: weight,
        pickupCity: _pickupCityCtrl.text.trim(),
        pickupCountry: _pickupCountryCtrl.text.trim(),
        pickupAddress: _pickupAddressCtrl.text.trim(),
        deliveryCity: _deliveryCityCtrl.text.trim(),
        deliveryCountry: _deliveryCountryCtrl.text.trim(),
        deliveryAddress: _deliveryAddressCtrl.text.trim(),
        recipientName: _recipientNameCtrl.text.trim(),
        recipientPhone: _recipientPhoneCtrl.text.trim(),
        preferredDeliveryDate: _preferredDeliveryDate,
        offeredPrice: offeredPrice,
        isUrgent: _isUrgent,
        imageUrls: _uploadedUrls,
        updatedAt: now,
      );

      blocContext.read<RequestBloc>().add(RequestUpdateRequested(updated));
      return;
    }

    final user = authState.user;

    final request = RequestModel(
      id: '',
      requesterId: user.uid,
      requesterName: user.fullName,
      requesterPhoto: user.photoUrl,
      requesterRating: user.rating,
      title: _titleCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      category: _category!,
      weightKg: weight,
      imageUrls: const <String>[],
      pickupCity: _pickupCityCtrl.text.trim(),
      pickupCountry: _pickupCountryCtrl.text.trim(),
      pickupAddress: _pickupAddressCtrl.text.trim(),
      deliveryCity: _deliveryCityCtrl.text.trim(),
      deliveryCountry: _deliveryCountryCtrl.text.trim(),
      deliveryAddress: _deliveryAddressCtrl.text.trim(),
      recipientName: _recipientNameCtrl.text.trim(),
      recipientPhone: _recipientPhoneCtrl.text.trim(),
      preferredDeliveryDate: _preferredDeliveryDate,
      offeredPrice: offeredPrice,
      isUrgent: _isUrgent,
      status: RequestStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    blocContext
        .read<RequestBloc>()
        .add(RequestCreateRequested(request, _localImages));
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? 'Edit Request' : 'Create Request';

    return BlocProvider<RequestBloc>(
      create: (_) => GetIt.instance<RequestBloc>(),
      child: BlocConsumer<RequestBloc, RequestState>(
        listenWhen: (_, s) =>
            s is RequestCreated || s is RequestUpdated || s is RequestError,
        listener: (context, state) {
          if (state is RequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
          if (state is RequestCreated || state is RequestUpdated) {
            context.pop();
          }
        },
        builder: (context, state) {
          final submitting = state is RequestCreating;
          final progress =
              state is RequestCreating ? state.uploadProgress : null;

          return Scaffold(
            appBar: AppBar(title: Text(title)),
            body: Column(
              children: [
                if (submitting && progress != null)
                  LinearProgressIndicator(
                      value: progress == 0 ? null : progress),
                Expanded(
                  child: Stepper(
                    currentStep: _step,
                    onStepCancel: submitting
                        ? null
                        : () {
                            if (_step == 0) return;
                            setState(() => _step -= 1);
                          },
                    onStepContinue: submitting
                        ? null
                        : () {
                            if (_step < 3) {
                              if (!_validateCurrentStep()) return;
                              setState(() => _step += 1);
                              return;
                            }
                            _submit(context);
                          },
                    controlsBuilder: (context, details) {
                      final isLast = _step == 3;
                      return Row(
                        children: [
                          FilledButton(
                            onPressed: details.onStepContinue,
                            child: Text(isLast
                                ? (_isEdit ? 'Save' : 'Submit')
                                : 'Next'),
                          ),
                          const SizedBox(width: 12),
                          if (_step > 0)
                            OutlinedButton(
                              onPressed: details.onStepCancel,
                              child: const Text('Back'),
                            ),
                        ],
                      );
                    },
                    steps: [
                      Step(
                        title: const Text('Item Details'),
                        isActive: _step >= 0,
                        content: Form(
                          key: _form1,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _titleCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Title',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _descriptionCtrl,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Description',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<RequestCategory>(
                                initialValue: _category,
                                decoration: const InputDecoration(
                                  labelText: 'Category',
                                  border: OutlineInputBorder(),
                                ),
                                items: RequestCategory.values
                                    .map(
                                      (c) => DropdownMenuItem<RequestCategory>(
                                        value: c,
                                        child: Text(_categoryLabel(c)),
                                      ),
                                    )
                                    .toList(growable: false),
                                onChanged: submitting
                                    ? null
                                    : (v) => setState(() => _category = v),
                                validator: (_) =>
                                    _category == null ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _weightCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Weight (kg)',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  final x = double.tryParse((v ?? '').trim());
                                  if (x == null || x <= 0)
                                    return 'Enter a valid weight';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      Step(
                        title: const Text('Locations'),
                        isActive: _step >= 1,
                        content: Form(
                          key: _form2,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _pickupCityCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Pickup city',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _pickupCountryCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Pickup country',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _pickupAddressCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Pickup address',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _deliveryCityCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Delivery city',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _deliveryCountryCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Delivery country',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _deliveryAddressCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Delivery address',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Step(
                        title: const Text('Recipient'),
                        isActive: _step >= 2,
                        content: Form(
                          key: _form3,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _recipientNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Recipient name',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _recipientPhoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Recipient phone',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Required'
                                        : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Step(
                        title: const Text('Photos & Price'),
                        isActive: _step >= 3,
                        content: Form(
                          key: _form4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ImagePickerGrid(
                                uploadedUrls: _uploadedUrls,
                                localFiles: _localImages,
                                onImagesChanged: (files) =>
                                    setState(() => _localImages = files),
                                onRemoveUrl: _removeUploadedUrl,
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: submitting ? null : _pickImages,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Add photos'),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed:
                                    submitting ? null : _pickPreferredDate,
                                icon: const Icon(Icons.calendar_today_outlined),
                                label: Text(
                                  _preferredDeliveryDate == null
                                      ? 'Preferred delivery date (optional)'
                                      : 'Preferred: ${_preferredDeliveryDate!.toLocal().toString().split(' ').first}',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _offeredPriceCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Offered price (optional)',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  final s = (v ?? '').trim();
                                  if (s.isEmpty) return null;
                                  final x = double.tryParse(s);
                                  if (x == null || x < 0)
                                    return 'Enter a valid price';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                value: _isUrgent,
                                onChanged: submitting
                                    ? null
                                    : (v) => setState(() => _isUrgent = v),
                                title: const Text('Urgent'),
                              ),
                              if (_isEdit && _localImages.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Note: Adding new photos during edit is not supported yet.',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _categoryLabel(RequestCategory c) {
    switch (c) {
      case RequestCategory.documents:
        return 'Documents';
      case RequestCategory.electronics:
        return 'Electronics';
      case RequestCategory.clothing:
        return 'Clothing';
      case RequestCategory.food:
        return 'Food';
      case RequestCategory.medicine:
        return 'Medicine';
      case RequestCategory.other:
        return 'Other';
    }
  }
}
