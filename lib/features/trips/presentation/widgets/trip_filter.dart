import 'package:flutter/material.dart';

class TripFilters {
  const TripFilters({
    this.destinationCountry,
    this.afterDate,
    this.includePast = false,
  });

  final String? destinationCountry;
  final DateTime? afterDate;
  final bool includePast;

  bool get isEmpty =>
      (destinationCountry == null || destinationCountry!.trim().isEmpty) &&
      afterDate == null &&
      includePast == false;
}

class TripFilterSheet extends StatefulWidget {
  const TripFilterSheet({
    super.key,
    required this.initial,
    required this.onApply,
  });

  final TripFilters initial;
  final ValueChanged<TripFilters> onApply;

  @override
  State<TripFilterSheet> createState() => _TripFilterSheetState();
}

class _TripFilterSheetState extends State<TripFilterSheet> {
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
    'Netherlands',
    'Sweden',
    'Norway',
    'Italy',
    'Spain',
    'Australia',
    'New Zealand',
    'South Africa',
    'Turkey',
    'India',
    'China',
    'Japan',
    'South Korea',
  ];

  String? _destinationCountry;
  DateTime? _afterDate;
  bool _includePast = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.initial.destinationCountry?.trim();
    _destinationCountry =
        (existing != null && _abroadCountries.contains(existing))
            ? existing
            : null;
    _afterDate = widget.initial.afterDate;
    _includePast = widget.initial.includePast;
  }

  @override
  void dispose() => super.dispose();

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _afterDate ?? now,
      firstDate: _includePast ? DateTime(2000) : DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );

    if (picked == null) return;
    setState(() => _afterDate = picked);
  }

  void _reset() {
    setState(() {
      _destinationCountry = null;
      _afterDate = null;
      _includePast = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter trips',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _destinationCountry,
              decoration: const InputDecoration(
                labelText: 'Destination country (optional)',
                border: OutlineInputBorder(),
              ),
              items: _abroadCountries
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(c),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (v) => setState(() => _destinationCountry = v),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(_afterDate == null
                  ? 'Departure date: Any'
                  : 'Departure after: ${_afterDate!.toLocal().toString().split(' ').first}'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include past trips'),
              value: _includePast,
              onChanged: (v) => setState(() => _includePast = v),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(
                        TripFilters(
                          destinationCountry: _destinationCountry,
                          afterDate: _afterDate,
                          includePast: _includePast,
                        ),
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
