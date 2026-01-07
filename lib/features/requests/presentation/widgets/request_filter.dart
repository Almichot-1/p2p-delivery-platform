import 'package:flutter/material.dart';

import '../../data/models/request_model.dart';

class RequestFilters {
  const RequestFilters({this.deliveryCity, this.category});

  final String? deliveryCity;
  final RequestCategory? category;

  bool get isEmpty =>
      (deliveryCity == null || deliveryCity!.trim().isEmpty) &&
      category == null;
}

class RequestFilterSheet extends StatefulWidget {
  const RequestFilterSheet({
    super.key,
    required this.initial,
    required this.onApply,
  });

  final RequestFilters initial;
  final ValueChanged<RequestFilters> onApply;

  @override
  State<RequestFilterSheet> createState() => _RequestFilterSheetState();
}

class _RequestFilterSheetState extends State<RequestFilterSheet> {
  final TextEditingController _deliveryCityCtrl = TextEditingController();
  RequestCategory? _category;

  @override
  void initState() {
    super.initState();
    _deliveryCityCtrl.text = widget.initial.deliveryCity?.trim() ?? '';
    _category = widget.initial.category;
  }

  @override
  void dispose() {
    _deliveryCityCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _deliveryCityCtrl.text = '';
      _category = null;
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
            Text('Filter requests',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _deliveryCityCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Delivery city (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RequestCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category (optional)',
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
              onChanged: (v) => setState(() => _category = v),
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
                      final city = _deliveryCityCtrl.text.trim();
                      widget.onApply(
                        RequestFilters(
                          deliveryCity: city.isEmpty ? null : city,
                          category: _category,
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
