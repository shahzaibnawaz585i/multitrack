import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';
import '../services/vehicle_icon_service.dart';

/// Reference-style dialog: category dropdown + pink Update button.
class UpdateVehicleIconDialog extends StatefulWidget {
  const UpdateVehicleIconDialog({
    super.key,
    required this.initialCategory,
  });

  final VehicleIconCategory initialCategory;

  static Future<VehicleIconCategory?> show(
    BuildContext context, {
    required VehicleIconCategory initialCategory,
  }) {
    return showDialog<VehicleIconCategory>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return UpdateVehicleIconDialog(initialCategory: initialCategory);
      },
    );
  }

  @override
  State<UpdateVehicleIconDialog> createState() =>
      _UpdateVehicleIconDialogState();
}

class _UpdateVehicleIconDialogState extends State<UpdateVehicleIconDialog> {
  static const Color _accent = Color(0xFFF53D6B);

  late VehicleIconCategory _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              context.tr('Update Icons'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              context.tr('Category'),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF333333), width: 1),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<VehicleIconCategory>(
                  isExpanded: true,
                  value: _selected,
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: _accent,
                    size: 28,
                  ),
                  menuMaxHeight: 320,
                  borderRadius: BorderRadius.circular(10),
                  dropdownColor: Colors.white,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                  items: VehicleIconCategory.all
                      .map(
                        (VehicleIconCategory c) =>
                            DropdownMenuItem<VehicleIconCategory>(
                          value: c,
                          child: Text(context.tr(c.label)),
                        ),
                      )
                      .toList(),
                  onChanged: (VehicleIconCategory? value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _selected = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _selected),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  context.tr('Update'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
