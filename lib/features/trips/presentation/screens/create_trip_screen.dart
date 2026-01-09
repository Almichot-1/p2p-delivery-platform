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
  static const List<String> _itemTypes = <String>[
    'Documents',
    'Electronics',
    'Clothing',
    'Food (sealed)',
    'Medicine',
    'Other',
  ];

  // Countries with their cities
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

  final _formKey = GlobalKey<FormState>();

  // Trip direction: true = Ethiopia to Abroad, false = Abroad to Ethiopia
  bool _isOutbound = true;

  // Origin
  String? _originCountry;
  String? _originCity;
  final _originCityCtrl = TextEditingController();
  bool _showOriginManualCity = false;

  // Destination
  String? _destinationCountry;
  String? _destinationCity;
  final _destinationCityCtrl = TextEditingController();
  bool _showDestinationManualCity = false;

  DateTime? _departureDate;
  DateTime? _returnDate;

  final _capacityCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final Set<String> _selectedTypes = <String>{};

  bool get _isEdit => widget.existing != null;

  List<String> get _countries => _countryCities.keys.toList();

  List<String> _getCities(String? country) {
    if (country == null || country == 'Other') return [];
    return _countryCities[country] ?? [];
  }

  @override
  void initState() {
    super.initState();
    final t = widget.existing;
    if (t != null) {
      _isOutbound = t.originCountry == 'Ethiopia';
      _originCountry = t.originCountry;
      _originCity = t.originCity;
      _originCityCtrl.text = t.originCity;
      _destinationCountry = t.destinationCountry;
      _destinationCity = t.destinationCity;
      _destinationCityCtrl.text = t.destinationCity;
      _departureDate = t.departureDate;
      _returnDate = t.returnDate;
      _capacityCtrl.text = t.availableCapacityKg.toStringAsFixed(1);
      _priceCtrl.text = t.pricePerKg?.toStringAsFixed(2) ?? '';
      _notesCtrl.text = t.notes ?? '';
      _selectedTypes.addAll(t.acceptedItemTypes);
    } else {
      _originCountry = 'Ethiopia';
    }
  }

  @override
  void dispose() {
    _originCityCtrl.dispose();
    _destinationCityCtrl.dispose();
    _capacityCtrl.dispose();
    _priceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _toggleDirection() {
    setState(() {
      _isOutbound = !_isOutbound;
      // Swap
      final tempCountry = _originCountry;
      final tempCity = _originCity;
      final tempCityText = _originCityCtrl.text;
      final tempShowManual = _showOriginManualCity;

      _originCountry = _destinationCountry;
      _originCity = _destinationCity;
      _originCityCtrl.text = _destinationCityCtrl.text;
      _showOriginManualCity = _showDestinationManualCity;

      _destinationCountry = tempCountry;
      _destinationCity = tempCity;
      _destinationCityCtrl.text = tempCityText;
      _showDestinationManualCity = tempShowManual;

      // Set Ethiopia as default for appropriate side
      if (_isOutbound) {
        _originCountry = 'Ethiopia';
        _originCity = null;
        _originCityCtrl.clear();
        _showOriginManualCity = false;
      } else {
        _destinationCountry = 'Ethiopia';
        _destinationCity = null;
        _destinationCityCtrl.clear();
        _showDestinationManualCity = false;
      }
    });
  }

  Future<void> _pickDepartureDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _departureDate ?? now,
      firstDate: now,
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
        const SnackBar(content: Text('Pick departure date first')),
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _returnDate ?? dep,
      firstDate: dep,
      lastDate: DateTime(dep.year + 2),
    );
    if (picked != null) setState(() => _returnDate = picked);
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
        const SnackBar(content: Text('Please log in first')),
      );
      return;
    }

    if (_departureDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Departure date is required')),
      );
      return;
    }

    final capacity = double.tryParse(_capacityCtrl.text.trim());
    if (capacity == null) return;

    final price = _priceCtrl.text.trim().isEmpty ? null : double.tryParse(_priceCtrl.text.trim());

    final originCountry = (_originCountry ?? '').trim();
    final originCity = _originCity?.trim() ?? _originCityCtrl.text.trim();
    final destCountry = (_destinationCountry ?? '').trim();
    final destCity = _destinationCity?.trim() ?? _destinationCityCtrl.text.trim();

    if (originCountry.isEmpty || originCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Origin location required')),
      );
      return;
    }

    if (destCountry.isEmpty || destCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Destination location required')),
      );
      return;
    }

    final trip = TripModel(
      id: widget.existing?.id ?? '',
      travelerId: authState.user.uid,
      travelerName: authState.user.fullName,
      travelerPhoto: authState.user.photoUrl,
      travelerRating: authState.user.rating,
      originCity: originCity,
      originCountry: originCountry,
      destinationCity: destCity,
      destinationCountry: destCountry,
      departureDate: _departureDate!,
      returnDate: _returnDate,
      availableCapacityKg: capacity,
      pricePerKg: price,
      acceptedItemTypes: _selectedTypes.toList(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      status: widget.existing?.status ?? TripStatus.active,
      matchCount: widget.existing?.matchCount ?? 0,
      createdAt: widget.existing?.createdAt,
      updatedAt: widget.existing?.updatedAt,
    );

    if (_isEdit) {
      blocContext.read<TripBloc>().add(TripUpdateRequested(trip));
    } else {
      blocContext.read<TripBloc>().add(TripCreateRequested(trip));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const Scaffold(body: Center(child: Text('Please log in')));
        }

        return BlocProvider<TripBloc>(
          create: (_) => GetIt.instance<TripBloc>(),
          child: BlocConsumer<TripBloc, TripState>(
            listenWhen: (_, s) => s is TripError || s is TripCreated || s is TripUpdated,
            listener: (context, state) {
              if (state is TripError) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
              }
              if (state is TripCreated || state is TripUpdated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(_isEdit ? 'Trip updated' : 'Trip posted')),
                );
                context.pop();
              }
            },
            builder: (context, state) {
              final submitting = state is TripCreating;

              return Scaffold(
                appBar: AppBar(title: Text(_isEdit ? 'Edit Trip' : 'Post a Trip')),
                body: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Direction toggle
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Trip Direction', style: Theme.of(context).textTheme.titleSmall),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isOutbound ? 'Ethiopia → Abroad' : 'Abroad → Ethiopia',
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton.filled(
                                onPressed: submitting ? null : _toggleDirection,
                                icon: const Icon(Icons.swap_horiz),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Origin
                      Text('From', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _buildLocationSection(
                        isOrigin: true,
                        isFixed: _isOutbound,
                        enabled: !submitting,
                      ),
                      const SizedBox(height: 16),

                      // Destination
                      Text('To', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _buildLocationSection(
                        isOrigin: false,
                        isFixed: !_isOutbound,
                        enabled: !submitting,
                      ),
                      const SizedBox(height: 16),

                      // Dates
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: submitting ? null : _pickDepartureDate,
                              icon: const Icon(Icons.flight_takeoff, size: 18),
                              label: Text(_departureDate == null
                                  ? 'Departure *'
                                  : '${_departureDate!.day}/${_departureDate!.month}/${_departureDate!.year}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: submitting ? null : _pickReturnDate,
                              icon: const Icon(Icons.flight_land, size: 18),
                              label: Text(_returnDate == null
                                  ? 'Return'
                                  : '${_returnDate!.day}/${_returnDate!.month}/${_returnDate!.year}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Capacity & Price
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _capacityCtrl,
                              enabled: !submitting,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Capacity (kg) *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                final x = double.tryParse(v?.trim() ?? '');
                                if (x == null) return 'Required';
                                if (x < 0.1 || x > 50) return '0.1-50 kg';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _priceCtrl,
                              enabled: !submitting,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Price/kg',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Item types
                      Text('Accepted items', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _itemTypes.map((t) => FilterChip(
                          label: Text(t),
                          selected: _selectedTypes.contains(t),
                          onSelected: submitting ? null : (v) => _toggleType(t, v),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: _notesCtrl,
                        enabled: !submitting,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 24),

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

  Widget _buildLocationSection({
    required bool isOrigin,
    required bool isFixed,
    required bool enabled,
  }) {
    final country = isOrigin ? _originCountry : _destinationCountry;
    final city = isOrigin ? _originCity : _destinationCity;
    final cityCtrl = isOrigin ? _originCityCtrl : _destinationCityCtrl;
    final showManualInput = isOrigin ? _showOriginManualCity : _showDestinationManualCity;
    final cities = _getCities(country);

    return Column(
      children: [
        // Country dropdown
        DropdownButtonFormField<String>(
          value: isFixed ? 'Ethiopia' : (country != null && _countries.contains(country) ? country : null),
          decoration: InputDecoration(
            labelText: isFixed ? 'Ethiopia' : 'Country *',
            border: const OutlineInputBorder(),
          ),
          items: (isFixed ? ['Ethiopia'] : _countries).map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
          onChanged: (isFixed || !enabled) ? null : (v) {
            setState(() {
              if (isOrigin) {
                _originCountry = v;
                _originCity = null;
                _originCityCtrl.clear();
                _showOriginManualCity = false;
              } else {
                _destinationCountry = v;
                _destinationCity = null;
                _destinationCityCtrl.clear();
                _showDestinationManualCity = false;
              }
            });
          },
        ),
        const SizedBox(height: 12),

        // City - dropdown if cities available and not showing manual input
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
                  if (isOrigin) {
                    _originCity = null;
                    _originCityCtrl.clear();
                    _showOriginManualCity = true;
                  } else {
                    _destinationCity = null;
                    _destinationCityCtrl.clear();
                    _showDestinationManualCity = true;
                  }
                } else {
                  if (isOrigin) {
                    _originCity = v;
                    _originCityCtrl.text = v ?? '';
                  } else {
                    _destinationCity = v;
                    _destinationCityCtrl.text = v ?? '';
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
                        if (isOrigin) {
                          _showOriginManualCity = false;
                          _originCityCtrl.clear();
                        } else {
                          _showDestinationManualCity = false;
                          _destinationCityCtrl.clear();
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
}
