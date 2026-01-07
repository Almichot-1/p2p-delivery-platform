import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/bloc/auth_state.dart';
import '../../bloc/trip_bloc.dart';
import '../../bloc/trip_event.dart';
import '../../bloc/trip_state.dart';
import '../../data/models/trip_model.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key, this.existing});

  final TripModel? existing;

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  static const List<String> _ethiopianCities = <String>[
    'Addis Ababa',
    'Adama',
    'Bahir Dar',
    'Gondar',
    'Hawassa',
    'Dire Dawa',
    'Mekelle',
    'Jimma',
    'Dessie',
    'Harar',
  ];

  static const List<String> _itemTypes = <String>[
    'Documents',
    'Electronics',
    'Clothing',
    'Food (sealed)',
    'Medicine',
    'Other',
  ];

  static const List<String> _abroadCountries = <String>[
    'United States (USA)',
    'United Arab Emirates (UAE)',
    'Saudi Arabia',
    'Qatar',
    'Kuwait',
    'Bahrain',
    'Oman',
    'Canada',
    'United Kingdom (UK)',
    'Germany',
    'France',
    'Italy',
    'Netherlands',
    'Sweden',
    'Norway',
    'Australia',
    'Turkey',
    'South Africa',
  ];

  final _formKey = GlobalKey<FormState>();

  String? _originCity;
  String? _destinationCountry;

  DateTime? _departureDate;
  DateTime? _returnDate;

  final TextEditingController _capacityCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  final Set<String> _selectedTypes = <String>{};

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _originCity = t.originCity;
      final existingDest =
          (t.destinationCountry.trim().isNotEmpty && t.destinationCountry != 'Ethiopia')
              ? t.destinationCountry
              : t.destinationCity;
      _destinationCountry = _abroadCountries.contains(existingDest) ? existingDest : null;
      _departureDate = t.departureDate;
      _returnDate = t.returnDate;
      _capacityCtrl.text = t.availableCapacityKg.toStringAsFixed(1);
      _priceCtrl.text = t.pricePerKg?.toStringAsFixed(2) ?? '';
      _notesCtrl.text = t.notes ?? '';
      _selectedTypes.addAll(t.acceptedItemTypes);
    }
  }

  @override
  void dispose() {
    _capacityCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDepartureDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? DateTime(now.year, now.month, now.day),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );

    if (picked == null) return;
    setState(() {
      _departureDate = picked;
      if (_returnDate != null && _returnDate!.isBefore(picked)) {
        _returnDate = null;
      }
    });
  }

  Future<void> _pickReturnDate() async {
    final dep = _departureDate;
    if (dep == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a departure date first.')),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? dep,
      firstDate: dep,
      lastDate: DateTime(dep.year + 2),
    );

    if (picked == null) return;
    setState(() => _returnDate = picked);
  }

  double? _parseDouble(String s) {
    final v = double.tryParse(s.trim());
    if (v == null) return null;
    return v;
  }

  void _toggleType(String t, bool selected) {
    setState(() {
      if (selected) {
        _selectedTypes.add(t);
      } else {
        _selectedTypes.remove(t);
      }
    });
  }

  void _submit(BuildContext blocContext) {
    if (!_formKey.currentState!.validate()) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in first.')),
      );
      return;
    }

    final dep = _departureDate;
    if (dep == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Departure date is required.')),
      );
      return;
    }

    final capacity = _parseDouble(_capacityCtrl.text);
    if (capacity == null) return;

    final price = _priceCtrl.text.trim().isEmpty ? null : _parseDouble(_priceCtrl.text);

    final destinationCountry = (_destinationCountry ?? '').trim();
    if (destinationCountry.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destination country is required.')),
      );
      return;
    }

    final base = TripModel(
      id: widget.existing?.id ?? '',
      travelerId: authState.user.uid,
      travelerName: authState.user.fullName,
      travelerPhoto: authState.user.photoUrl,
      travelerRating: authState.user.rating,
      originCity: _originCity!.trim(),
      originCountry: 'Ethiopia',
      destinationCity: destinationCountry,
      destinationCountry: destinationCountry,
      departureDate: dep,
      returnDate: _returnDate,
      availableCapacityKg: capacity,
      pricePerKg: price,
      acceptedItemTypes: _selectedTypes.toList(growable: false),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      status: widget.existing?.status ?? TripStatus.active,
      matchCount: widget.existing?.matchCount ?? 0,
      createdAt: widget.existing?.createdAt,
      updatedAt: widget.existing?.updatedAt,
    );

    if (_isEdit) {
      blocContext.read<TripBloc>().add(TripUpdateRequested(base));
    } else {
      blocContext.read<TripBloc>().add(TripCreateRequested(base));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: Text('Please log in to post a trip.')),
          );
        }

        return BlocProvider<TripBloc>(
          create: (_) => GetIt.instance<TripBloc>(),
          child: BlocConsumer<TripBloc, TripState>(
            listenWhen: (_, s) => s is TripError || s is TripCreated || s is TripUpdated,
            listener: (context, state) {
              if (state is TripError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
              if (state is TripCreated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trip posted')),
                );
                context.pop();
              }
              if (state is TripUpdated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Trip updated')),
                );
                context.pop();
              }
            },
            builder: (context, state) {
              final submitting = state is TripCreating;

              return Scaffold(
                appBar: AppBar(
                  title: Text(_isEdit ? 'Edit Trip' : 'Post a Trip'),
                ),
                body: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _originCity,
                        decoration: const InputDecoration(
                          labelText: 'Origin city',
                          border: OutlineInputBorder(),
                        ),
                        items: _ethiopianCities
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(growable: false),
                        onChanged: submitting ? null : (v) => setState(() => _originCity = v),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Origin city is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _destinationCountry,
                        decoration: const InputDecoration(
                          labelText: 'Destination country (abroad)'
                          ,
                          border: OutlineInputBorder(),
                        ),
                        items: _abroadCountries
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(growable: false),
                        onChanged: submitting ? null : (v) => setState(() => _destinationCountry = v),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Destination country is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: submitting ? null : _pickDepartureDate,
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(
                          _departureDate == null
                              ? 'Departure date (required)'
                              : 'Departure: ${_departureDate!.toLocal().toString().split(' ').first}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: submitting ? null : _pickReturnDate,
                        icon: const Icon(Icons.event_repeat_outlined),
                        label: Text(
                          _returnDate == null
                              ? 'Return date (optional)'
                              : 'Return: ${_returnDate!.toLocal().toString().split(' ').first}',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _capacityCtrl,
                        enabled: !submitting,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Available capacity (kg)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          final value = _parseDouble(v ?? '');
                          if (value == null) return 'Enter a valid number';
                          if (value < 0.1 || value > 50) return 'Capacity must be 0.1–50 kg';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _priceCtrl,
                        enabled: !submitting,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Price per kg (optional)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final value = _parseDouble(v);
                          if (value == null) return 'Enter a valid number';
                          if (value < 0) return 'Price must be positive';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Accepted item types',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in _itemTypes)
                            FilterChip(
                              label: Text(t),
                              selected: _selectedTypes.contains(t),
                              onSelected: submitting ? null : (v) => _toggleType(t, v),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _notesCtrl,
                        enabled: !submitting,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: submitting ? null : () => _submit(context),
                        icon: const Icon(Icons.check),
                        label: Text(_isEdit ? 'Save Changes' : 'Post Trip'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
