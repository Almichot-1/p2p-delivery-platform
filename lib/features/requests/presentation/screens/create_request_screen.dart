import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../../trips/data/models/trip_model.dart';
import '../../bloc/request_bloc.dart';
import '../../bloc/request_event.dart';
import '../../bloc/request_state.dart';
import '../../data/models/request_model.dart';
import '../widgets/image_picker_grid.dart';

/// Data class to pass trip info when creating request from a trip
class CreateRequestFromTrip {
  const CreateRequestFromTrip({
    required this.trip,
  });

  final TripModel trip;
}

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key, this.existing, this.fromTrip});

  final RequestModel? existing;
  final CreateRequestFromTrip? fromTrip;

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  // Countries with cities
  static const Map<String, List<String>> _countryCities = {
    'Ethiopia': ['Addis Ababa', 'Adama', 'Bahir Dar', 'Gondar', 'Hawassa', 'Dire Dawa', 'Mekelle', 'Jimma', 'Dessie', 'Harar'],
    'United States': ['New York', 'Los Angeles', 'Washington DC', 'Chicago', 'Houston', 'Miami', 'San Francisco', 'Seattle', 'Boston', 'Atlanta'],
    'United Arab Emirates': ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman'],
    'Saudi Arabia': ['Riyadh', 'Jeddah', 'Mecca', 'Medina', 'Dammam'],
    'Qatar': ['Doha', 'Al Wakrah', 'Al Khor'],
    'Kuwait': ['Kuwait City', 'Hawalli', 'Salmiya'],
    'Bahrain': ['Manama', 'Riffa', 'Muharraq'],
    'Oman': ['Muscat', 'Salalah', 'Sohar'],
    'Canada': ['Toronto', 'Vancouver', 'Montreal', 'Calgary', 'Ottawa'],
    'United Kingdom': ['London', 'Manchester', 'Birmingham', 'Liverpool', 'Edinburgh'],
    'Germany': ['Berlin', 'Munich', 'Frankfurt', 'Hamburg', 'Cologne'],
    'France': ['Paris', 'Lyon', 'Marseille', 'Nice', 'Toulouse'],
    'Italy': ['Rome', 'Milan', 'Naples', 'Turin', 'Florence'],
    'Netherlands': ['Amsterdam', 'Rotterdam', 'The Hague', 'Utrecht'],
    'Sweden': ['Stockholm', 'Gothenburg', 'Malmö'],
    'Norway': ['Oslo', 'Bergen', 'Trondheim'],
    'Australia': ['Sydney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaide'],
    'Turkey': ['Istanbul', 'Ankara', 'Izmir', 'Antalya'],
    'South Africa': ['Johannesburg', 'Cape Town', 'Durban', 'Pretoria'],
    'Kenya': ['Nairobi', 'Mombasa', 'Kisumu'],
    'Egypt': ['Cairo', 'Alexandria', 'Giza'],
    'Israel': ['Tel Aviv', 'Jerusalem', 'Haifa'],
    'India': ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Kolkata'],
    'China': ['Beijing', 'Shanghai', 'Guangzhou', 'Shenzhen'],
    'Japan': ['Tokyo', 'Osaka', 'Kyoto', 'Yokohama'],
    'South Korea': ['Seoul', 'Busan', 'Incheon'],
    'Singapore': ['Singapore'],
    'Malaysia': ['Kuala Lumpur', 'Penang', 'Johor Bahru'],
    'Thailand': ['Bangkok', 'Chiang Mai', 'Phuket'],
    'Other': [],
  };

  // Item details
  final _titleCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  RequestCategory? _category;

  // Pickup location
  String? _pickupCountry;
  String? _pickupCity;
  final _pickupCityCtrl = TextEditingController();
  bool _showPickupManualCity = false;

  // Delivery location
  String? _deliveryCountry;
  String? _deliveryCity;
  final _deliveryCityCtrl = TextEditingController();
  bool _showDeliveryManualCity = false;

  // Recipient
  final _recipientNameCtrl = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();

  // Optional
  DateTime? _preferredDeliveryDate;
  final _offeredPriceCtrl = TextEditingController();
  bool _isUrgent = false;

  List<File> _localImages = <File>[];
  List<String> _uploadedUrls = <String>[];

  bool get _isEdit => widget.existing != null;
  bool get _isFromTrip => widget.fromTrip != null;
  TripModel? get _linkedTrip => widget.fromTrip?.trip;
  List<String> get _countries => _countryCities.keys.toList();

  List<String> _getCities(String? country) {
    if (country == null || country == 'Other') return [];
    return _countryCities[country] ?? [];
  }

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _titleCtrl.text = e.title;
      _descriptionCtrl.text = e.description;
      _weightCtrl.text = e.weightKg.toStringAsFixed(1);
      _category = e.category;
      _pickupCountry = e.pickupCountry;
      _pickupCity = e.pickupCity;
      _pickupCityCtrl.text = e.pickupCity;
      _deliveryCountry = e.deliveryCountry;
      _deliveryCity = e.deliveryCity;
      _deliveryCityCtrl.text = e.deliveryCity;
      _recipientNameCtrl.text = e.recipientName;
      _recipientPhoneCtrl.text = e.recipientPhone;
      _preferredDeliveryDate = e.preferredDeliveryDate;
      _offeredPriceCtrl.text = e.offeredPrice?.toStringAsFixed(2) ?? '';
      _isUrgent = e.isUrgent;
      _uploadedUrls = List.of(e.imageUrls);
    } else if (_isFromTrip) {
      // Pre-fill from trip data - pickup is trip origin, delivery is trip destination
      final trip = _linkedTrip!;
      _pickupCountry = trip.originCountry;
      _pickupCity = trip.originCity;
      _pickupCityCtrl.text = trip.originCity;
      _deliveryCountry = trip.destinationCountry;
      _deliveryCity = trip.destinationCity;
      _deliveryCityCtrl.text = trip.destinationCity;
      _preferredDeliveryDate = trip.departureDate;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    _weightCtrl.dispose();
    _pickupCityCtrl.dispose();
    _deliveryCityCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _offeredPriceCtrl.dispose();
    super.dispose();
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferredDeliveryDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _preferredDeliveryDate = picked);
  }

  void _submit(BuildContext blocContext) {
    if (!_formKey.currentState!.validate()) return;
    if (_category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    final pickupCountry = (_pickupCountry ?? '').trim();
    final pickupCity = _pickupCity?.trim() ?? _pickupCityCtrl.text.trim();
    final deliveryCountry = (_deliveryCountry ?? '').trim();
    final deliveryCity = _deliveryCity?.trim() ?? _deliveryCityCtrl.text.trim();

    if (pickupCountry.isEmpty || pickupCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pickup location required')),
      );
      return;
    }

    if (deliveryCountry.isEmpty || deliveryCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery location required')),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final weight = double.tryParse(_weightCtrl.text.trim()) ?? 0;
    final price = _offeredPriceCtrl.text.trim().isEmpty
        ? null
        : double.tryParse(_offeredPriceCtrl.text.trim());
    final now = DateTime.now();
    final user = authState.user;

    if (_isEdit) {
      final updated = widget.existing!.copyWith(
        title: _titleCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
        category: _category,
        weightKg: weight,
        pickupCity: pickupCity,
        pickupCountry: pickupCountry,
        pickupAddress: pickupCity,
        deliveryCity: deliveryCity,
        deliveryCountry: deliveryCountry,
        deliveryAddress: deliveryCity,
        recipientName: _recipientNameCtrl.text.trim(),
        recipientPhone: _recipientPhoneCtrl.text.trim(),
        preferredDeliveryDate: _preferredDeliveryDate,
        offeredPrice: price,
        isUrgent: _isUrgent,
        imageUrls: _uploadedUrls,
        updatedAt: now,
      );
      blocContext.read<RequestBloc>().add(RequestUpdateRequested(updated));
    } else {
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
        imageUrls: const [],
        pickupCity: pickupCity,
        pickupCountry: pickupCountry,
        pickupAddress: pickupCity,
        deliveryCity: deliveryCity,
        deliveryCountry: deliveryCountry,
        deliveryAddress: deliveryCity,
        recipientName: _recipientNameCtrl.text.trim(),
        recipientPhone: _recipientPhoneCtrl.text.trim(),
        preferredDeliveryDate: _preferredDeliveryDate,
        offeredPrice: price,
        isUrgent: _isUrgent,
        status: RequestStatus.active,
        createdAt: now,
        updatedAt: now,
      );
      blocContext.read<RequestBloc>().add(RequestCreateRequested(request, _localImages));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RequestBloc>(
      create: (_) => GetIt.instance<RequestBloc>(),
      child: BlocConsumer<RequestBloc, RequestState>(
        listenWhen: (_, s) => s is RequestCreated || s is RequestUpdated || s is RequestError,
        listener: (context, state) {
          if (state is RequestError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is RequestCreated || state is RequestUpdated) {
            context.pop();
          }
        },
        builder: (context, state) {
          final submitting = state is RequestCreating;
          final progress = state is RequestCreating ? state.uploadProgress : null;

          return Scaffold(
            appBar: AppBar(title: Text(_isEdit ? 'Edit Request' : 'Send Item')),
            body: Column(
              children: [
                if (submitting && progress != null)
                  LinearProgressIndicator(value: progress == 0 ? null : progress),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Item details
                        Text('What are you sending?', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Item name *',
                            hintText: 'e.g., iPhone charger, Documents',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<RequestCategory>(
                                value: _category,
                                decoration: const InputDecoration(
                                  labelText: 'Category *',
                                  border: OutlineInputBorder(),
                                ),
                                items: RequestCategory.values.map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(_categoryLabel(c)),
                                )).toList(),
                                onChanged: submitting ? null : (v) => setState(() => _category = v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                controller: _weightCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Weight *',
                                  suffixText: 'kg',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  final x = double.tryParse(v?.trim() ?? '');
                                  return (x == null || x <= 0) ? 'Invalid' : null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Pickup location
                        Text('Pickup Location', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _buildLocationSection(
                          isPickup: true,
                          enabled: !submitting,
                        ),
                        const SizedBox(height: 20),

                        // Delivery location
                        Text('Delivery Location', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        _buildLocationSection(
                          isPickup: false,
                          enabled: !submitting,
                        ),
                        const SizedBox(height: 20),

                        // Recipient
                        Text('Recipient', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _recipientNameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Name *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _recipientPhoneCtrl,
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Phone *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Optional
                        Text('Optional', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _descriptionCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Description / Notes',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: submitting ? null : _pickDate,
                                icon: const Icon(Icons.calendar_today, size: 18),
                                label: Text(_preferredDeliveryDate == null
                                    ? 'Delivery date'
                                    : '${_preferredDeliveryDate!.day}/${_preferredDeliveryDate!.month}'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 120,
                              child: TextFormField(
                                controller: _offeredPriceCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Price \$',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: _isUrgent,
                          onChanged: submitting ? null : (v) => setState(() => _isUrgent = v),
                          title: const Text('Urgent delivery'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 12),

                        // Photos
                        ImagePickerGrid(
                          uploadedUrls: _uploadedUrls,
                          localFiles: _localImages,
                          onImagesChanged: (files) => setState(() => _localImages = files),
                          onRemoveUrl: (url) => setState(() => _uploadedUrls.remove(url)),
                        ),
                        if (_localImages.length + _uploadedUrls.length < 5)
                          TextButton.icon(
                            onPressed: submitting ? null : _pickImages,
                            icon: const Icon(Icons.add_photo_alternate),
                            label: const Text('Add photos'),
                          ),
                        const SizedBox(height: 24),

                        FilledButton.icon(
                          onPressed: submitting ? null : () => _submit(context),
                          icon: const Icon(Icons.send),
                          label: Text(_isEdit ? 'Save Changes' : 'Create Request'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLocationSection({required bool isPickup, required bool enabled}) {
    final country = isPickup ? _pickupCountry : _deliveryCountry;
    final city = isPickup ? _pickupCity : _deliveryCity;
    final cityCtrl = isPickup ? _pickupCityCtrl : _deliveryCityCtrl;
    final showManualInput = isPickup ? _showPickupManualCity : _showDeliveryManualCity;
    final cities = _getCities(country);

    return Column(
      children: [
        DropdownButtonFormField<String>(
          value: country != null && _countries.contains(country) ? country : null,
          decoration: const InputDecoration(
            labelText: 'Country *',
            border: OutlineInputBorder(),
          ),
          items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: enabled ? (v) {
            setState(() {
              if (isPickup) {
                _pickupCountry = v;
                _pickupCity = null;
                _pickupCityCtrl.clear();
                _showPickupManualCity = false;
              } else {
                _deliveryCountry = v;
                _deliveryCity = null;
                _deliveryCityCtrl.clear();
                _showDeliveryManualCity = false;
              }
            });
          } : null,
        ),
        const SizedBox(height: 12),

        if (cities.isNotEmpty && !showManualInput)
          DropdownButtonFormField<String>(
            value: city != null && cities.contains(city) ? city : null,
            decoration: const InputDecoration(
              labelText: 'City *',
              border: OutlineInputBorder(),
            ),
            items: [
              ...cities.map((c) => DropdownMenuItem(value: c, child: Text(c))),
              const DropdownMenuItem(value: '__other__', child: Text('Other (enter manually)')),
            ],
            onChanged: enabled ? (v) {
              setState(() {
                if (v == '__other__') {
                  if (isPickup) {
                    _pickupCity = null;
                    _pickupCityCtrl.clear();
                    _showPickupManualCity = true;
                  } else {
                    _deliveryCity = null;
                    _deliveryCityCtrl.clear();
                    _showDeliveryManualCity = true;
                  }
                } else {
                  if (isPickup) {
                    _pickupCity = v;
                    _pickupCityCtrl.text = v ?? '';
                  } else {
                    _deliveryCity = v;
                    _deliveryCityCtrl.text = v ?? '';
                  }
                }
              });
            } : null,
          ),

        // Show manual input when "Other" selected or country has no cities
        if (showManualInput || country == 'Other' || (country != null && cities.isEmpty))
          Column(
            children: [
              TextFormField(
                controller: cityCtrl,
                enabled: enabled,
                decoration: const InputDecoration(
                  labelText: 'City *',
                  hintText: 'Enter city name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
              ),
              if (showManualInput && cities.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: enabled ? () {
                      setState(() {
                        if (isPickup) {
                          _showPickupManualCity = false;
                          _pickupCityCtrl.clear();
                        } else {
                          _showDeliveryManualCity = false;
                          _deliveryCityCtrl.clear();
                        }
                      });
                    } : null,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back to city list'),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  String _categoryLabel(RequestCategory c) => switch (c) {
    RequestCategory.documents => 'Documents',
    RequestCategory.electronics => 'Electronics',
    RequestCategory.clothing => 'Clothing',
    RequestCategory.food => 'Food',
    RequestCategory.medicine => 'Medicine',
    RequestCategory.other => 'Other',
  };
}
