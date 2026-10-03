import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';
import '../models/device_group_model.dart';

class AddGroupDeviceDialog extends StatefulWidget {
  const AddGroupDeviceDialog({
    super.key,
    required this.groups,
    this.initialGroupId,
  });

  final List<DeviceGroupModel> groups;
  final int? initialGroupId;

  static Future<DeviceGroupModel?> show(
    BuildContext context, {
    required List<DeviceGroupModel> groups,
    int? initialGroupId,
  }) {
    return showDialog<DeviceGroupModel>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AddGroupDeviceDialog(
          groups: groups,
          initialGroupId: initialGroupId,
        );
      },
    );
  }

  @override
  State<AddGroupDeviceDialog> createState() => _AddGroupDeviceDialogState();
}

class _AddGroupDeviceDialogState extends State<AddGroupDeviceDialog> {
  static const Color _accent = Color(0xFFF53D6B);
  int? _selectedGroupId;

  @override
  void initState() {
    super.initState();
    _selectedGroupId = widget.initialGroupId;
    if (_selectedGroupId != null &&
        !widget.groups.any((DeviceGroupModel g) => g.id == _selectedGroupId)) {
      _selectedGroupId = null;
    }
  }

  void _submit() {
    if (_selectedGroupId == null) {
      return;
    }
    for (final DeviceGroupModel group in widget.groups) {
      if (group.id == _selectedGroupId) {
        Navigator.pop(context, group);
        return;
      }
    }
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
              context.tr('Add Group'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.tr('Groups'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ),
            const SizedBox(height: 8),
            InputDecorator(
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1A1A1A)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF1A1A1A)),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  isExpanded: true,
                  value: _selectedGroupId,
                  hint: Text(
                    context.tr('Select'),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  icon: const Icon(
                    Icons.arrow_drop_down,
                    color: Color(0xFFE53935),
                  ),
                  items: widget.groups
                      .map(
                        (DeviceGroupModel g) => DropdownMenuItem<int>(
                          value: g.id,
                          child: Text(
                            g.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: widget.groups.isEmpty
                      ? null
                      : (int? value) {
                          setState(() {
                            _selectedGroupId = value;
                          });
                        },
                ),
              ),
            ),
            if (widget.groups.isEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                context.tr('No groups found on server'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
            const SizedBox(height: 22),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed:
                    _selectedGroupId == null ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _accent.withValues(alpha: 0.45),
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  context.tr('Update Device'),
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
