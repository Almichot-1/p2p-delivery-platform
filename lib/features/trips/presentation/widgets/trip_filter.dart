import 'package:flutter/material.dart';

class TripFilters {
  const TripFilters({this.destinationCity, this.afterDate});

  final String? destinationCity;
  final DateTime? afterDate;

  bool get isEmpty =>
      (destinationCity == null || destinationCity!.trim().isEmpty) && afterDate == null;
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
  final TextEditingController _destinationCountryCtrl = TextEditingController();
  DateTime? _afterDate;

  @override
  void initState() {
    super.initState();
    _destinationCountryCtrl.text = widget.initial.destinationCity?.trim() ?? '';
    _afterDate = widget.initial.afterDate;
  }

  @override
  void dispose() {
    _destinationCountryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _afterDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
    );

    if (picked == null) return;
    setState(() => _afterDate = picked);
  }

  void _reset() {
    setState(() {
      _destinationCountryCtrl.text = '';
      _afterDate = null;
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
            Text('Filter trips', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _destinationCountryCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Destination country (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today_outlined),
              label: Text(_afterDate == null ? 'Departure date: Any' : 'Departure after: ${_afterDate!.toLocal().toString().split(' ').first}'),
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
                      final destinationCountry = _destinationCountryCtrl.text.trim();
                      widget.onApply(
                        TripFilters(
                          destinationCity: destinationCountry.isEmpty ? null : destinationCountry,
                          afterDate: _afterDate,
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
