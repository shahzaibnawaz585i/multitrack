import 'package:flutter/material.dart';

import '../../l10n/app_l10n.dart';
import '../../theme/app_theme_tokens.dart';

/// Reminder type list (reference: Add Reminder + search + pink/grey squares).
class AddReminderPickerScreen extends StatefulWidget {
  const AddReminderPickerScreen({super.key});

  static const List<String> defaultTypes = <String>[
    'Service',
    'Changement de batterie',
    'Autres',
    'Battery Change',
    "Changement d'huile",
  ];

  static Future<List<String>?> open(BuildContext context) {
    return Navigator.push<List<String>>(
      context,
      MaterialPageRoute<List<String>>(
        builder: (_) => const AddReminderPickerScreen(),
      ),
    );
  }

  @override
  State<AddReminderPickerScreen> createState() =>
      _AddReminderPickerScreenState();
}

class _AddReminderPickerScreenState extends State<AddReminderPickerScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);
  static const Color _greySquare = Color(0xFFD3D3D3);

  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selected = <String>{'Service'};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    final String q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      return AddReminderPickerScreen.defaultTypes;
    }
    return AddReminderPickerScreen.defaultTypes
        .where((String t) => t.toLowerCase().contains(q))
        .toList();
  }

  void _toggle(String type) {
    setState(() {
      if (_selected.contains(type)) {
        _selected.remove(type);
      } else {
        _selected.add(type);
      }
    });
  }

  void _continue() {
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please select reminder type'))),
      );
      return;
    }
    Navigator.pop(context, _selected.toList());
  }

  @override
  Widget build(BuildContext context) {
    final List<String> types = _filtered;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: _pinkColor,
            size: 20,
          ),
        ),
        title: Text(
          context.tr('Add Reminder'),
          style: TextStyle(
            color: context.textColor,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: context.tr('Search Reminder'),
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                prefixIcon: const Icon(Icons.search, color: _pinkColor),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _pinkColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _pinkColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _pinkColor, width: 1.2),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              itemCount: types.length,
              itemBuilder: (BuildContext context, int index) {
                final String type = types[index];
                final bool selected = _selected.contains(type);
                return InkWell(
                  onTap: () => _toggle(type),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: selected ? _pinkColor : _greySquare,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            context.tr(type),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.textColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pinkColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    context.tr('Continue'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
