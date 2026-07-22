import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_theme.dart';
import '../../data/vehicle_data.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? initialVehicle;

  const AddExpenseScreen({
    super.key,
    this.initialVehicle,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  static const Color pinkColor = AppThemeContext.pinkColor;

  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _paymentModeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedExpenseType;
  File? _selectedImage;

  final List<String> _expenseTypes = const [
    'Food',
    'Fuel',
    'Maintenance',
    'Toll',
    'Parking',
    'Other',
  ];

  List<String> get _vehicles =>
      VehicleData.vehicles.map((vehicle) => vehicle.name).toList();

  @override
  void initState() {
    super.initState();
    if (widget.initialVehicle != null && widget.initialVehicle!.isNotEmpty) {
      _vehicleController.text = widget.initialVehicle!;
    }
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _quantityController.dispose();
    _amountController.dispose();
    _paymentModeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final int hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    final String period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} '
        '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  InputDecoration _fieldDecoration({
    required String hint,
    Color? fillColor,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.appSecondaryText, fontSize: 14),
      filled: true,
      fillColor: fillColor ?? context.appFieldFill,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: context.appBorder, width: 0.9),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: context.appTextColor, width: 1),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: context.appBorder, width: 0.9),
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _showVehicleSearchDialog() {
    final TextEditingController searchController = TextEditingController();
    String? tempSelected = _vehicleController.text.isEmpty
        ? null
        : _vehicleController.text;
    List<String> filteredVehicles = List<String>.from(_vehicles);

    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: context.appSurface,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          setDialogState(() {
                            tempSelected = null;
                          });
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Clear All',
                          style: TextStyle(
                            color: pinkColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 36,
                      child: TextField(
                        controller: searchController,
                        style: TextStyle(fontSize: 13, color: context.appTextColor),
                        onChanged: (query) {
                          setDialogState(() {
                            filteredVehicles = _vehicles
                                .where(
                                  (vehicle) => vehicle
                                      .toLowerCase()
                                      .contains(query.toLowerCase()),
                                )
                                .toList();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(
                            color: context.appSecondaryText,
                            fontSize: 13,
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: pinkColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: pinkColor,
                              width: 1.2,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: pinkColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredVehicles.length,
                        itemBuilder: (context, index) {
                          final String vehicle = filteredVehicles[index];
                          final bool isChecked = tempSelected == vehicle;

                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                tempSelected = isChecked ? null : vehicle;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: context.appTextColor,
                                        width: 1.2,
                                      ),
                                      color: isChecked
                                          ? pinkColor
                                          : Colors.transparent,
                                    ),
                                    child: isChecked
                                        ? const Icon(
                                            Icons.check,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      vehicle,
                                      style: TextStyle(
                                        color: context.appTextColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
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
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _DialogButton(
                            label: 'CANCEL',
                            onTap: () => Navigator.pop(dialogContext),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DialogButton(
                            label: 'Apply',
                            onTap: () {
                              setState(() {
                                _vehicleController.text = tempSelected ?? '';
                              });
                              Navigator.pop(dialogContext);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(searchController.dispose);
  }

  void _showExpenseTypeDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: context.appSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final type in _expenseTypes)
                  ListTile(
                    title: Text(
                      type,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.appTextColor,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedExpenseType = type;
                      });
                      Navigator.pop(dialogContext);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSelectImageDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: context.appSurface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Image',
                  style: TextStyle(
                    color: context.appTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _ImageSourceTile(
                  icon: Icons.photo_library_outlined,
                  label: 'From Gallery',
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 8),
                _ImageSourceTile(
                  icon: Icons.photo_camera_outlined,
                  label: 'From camera',
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedImage = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedImage == null || !mounted) {
        return;
      }

      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image Error: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appHeaderBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(18),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Date'),
                      GestureDetector(
                        onTap: _pickDateTime,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: context.appFieldFill,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: context.appBorder,
                              width: 0.9,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: pinkColor,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _formatDateTime(_selectedDate),
                                style: TextStyle(
                                  color: context.appTextColor,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Vehicle'),
                      GestureDetector(
                        onTap: _showVehicleSearchDialog,
                        child: AbsorbPointer(
                          child: TextField(
                            controller: _vehicleController,
                            decoration: _fieldDecoration(
                              hint: 'Search Vehicle',
                              prefixIcon: const Icon(
                                Icons.search,
                                color: pinkColor,
                                size: 20,
                              ),
                              suffixIcon: Icon(
                                Icons.arrow_drop_down,
                                color: context.appTextColor,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Expense Type'),
                      GestureDetector(
                        onTap: _showExpenseTypeDialog,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: context.appFieldFill,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: context.appBorder,
                              width: 0.9,
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedExpenseType ?? 'Enter Expense Type',
                                  style: TextStyle(
                                    color: _selectedExpenseType == null
                                        ? context.appSecondaryText
                                        : context.appTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: context.appTextColor,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Quantity'),
                      TextField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _fieldDecoration(
                          hint: 'Enter Quantity',
                          fillColor: context.appFieldFill,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Amount'),
                      TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _fieldDecoration(
                          hint: 'Enter Amount',
                          fillColor: context.appFieldFill,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Payment Mode'),
                      TextField(
                        controller: _paymentModeController,
                        decoration: _fieldDecoration(
                          hint: 'Enter Payment Mode',
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Expense Description'),
                      TextField(
                        controller: _descriptionController,
                        minLines: 2,
                        maxLines: 3,
                        decoration: _fieldDecoration(
                          hint: 'Enter Expense Description',
                          fillColor: context.appFieldFill,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildLabel('Upload Image'),
                      GestureDetector(
                        onTap: _showSelectImageDialog,
                        child: Container(
                          width: double.infinity,
                          height: 150,
                          decoration: BoxDecoration(
                            color: context.appFieldFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: context.appBorder,
                              width: 0.9,
                            ),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: pinkColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.image_outlined,
                                            color: pinkColor,
                                            size: 28,
                                          ),
                                        ),
                                        Positioned(
                                          right: -6,
                                          bottom: -4,
                                          child: Container(
                                            width: 22,
                                            height: 22,
                                            decoration: const BoxDecoration(
                                              color: pinkColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.arrow_upward,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Upload Image',
                                      style: TextStyle(
                                        color: context.appTextColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: Material(
                          color: pinkColor,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: const Center(
                              child: Text(
                                'Add Expense',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 16, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: pinkColor,
              size: 20,
            ),
          ),
          Text(
            'Add new Expense',
            style: TextStyle(
              color: context.appTextColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          color: context.appTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _AddExpenseScreenState.pinkColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImageSourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ImageSourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: _AddExpenseScreenState.pinkColor, size: 28),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                color: context.appTextColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
