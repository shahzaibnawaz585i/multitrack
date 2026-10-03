import 'package:flutter/material.dart';

import '../../l10n/app_l10n.dart';
import '../../services/vehicle_maintenance_service.dart';
import '../../theme/app_theme_tokens.dart';

class AddNewReminderScreen extends StatefulWidget {
  const AddNewReminderScreen({
    super.key,
    this.initialType,
    this.deviceId,
  });

  final String? initialType;
  final int? deviceId;

  static Future<bool?> open(
    BuildContext context, {
    String? initialType,
    int? deviceId,
  }) {
    return Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => AddNewReminderScreen(
          initialType: initialType,
          deviceId: deviceId,
        ),
      ),
    );
  }

  @override
  State<AddNewReminderScreen> createState() => _AddNewReminderScreenState();
}

class _AddNewReminderScreenState extends State<AddNewReminderScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);

  late final TextEditingController _typeController;
  final TextEditingController _odometerStartController =
      TextEditingController();
  final TextEditingController _periodController = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.initialType ?? '');
  }

  @override
  void dispose() {
    _typeController.dispose();
    _odometerStartController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: context.tr(hint),
      hintStyle: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: context.fieldFillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF555555), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF555555), width: 1.2),
      ),
    );
  }

  Future<void> _submit() async {
    final String type = _typeController.text.trim();
    final double? start = double.tryParse(_odometerStartController.text.trim());
    final double? period = double.tryParse(_periodController.text.trim());

    if (type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please select reminder type'))),
      );
      return;
    }

    if (start == null || period == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter odometer values'))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (widget.deviceId != null) {
        await VehicleMaintenanceService.addOdometerReminder(
          deviceId: widget.deviceId!,
          name: type,
          intervalKm: period,
          lastServiceKm: start,
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: _pinkColor,
            size: 20,
          ),
        ),
        titleSpacing: 0,
        title: Text(
          context.tr('Add New Reminder'),
          style: TextStyle(
            color: context.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: <Widget>[
                TextField(
                  controller: _typeController,
                  readOnly: widget.initialType != null,
                  style: TextStyle(color: context.textColor, fontSize: 15),
                  decoration: _fieldDecoration(hint: 'Select Reminder Type'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _odometerStartController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: context.textColor, fontSize: 15),
                  decoration: _fieldDecoration(hint: 'Odometer Start'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _periodController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: context.textColor, fontSize: 15),
                  decoration: _fieldDecoration(
                    hint: 'Period of odometer in which you want alerts',
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pinkColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.tr('Add Reminder'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
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
