import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_theme.dart';
import '../../widgets/vehicle_search_dialog.dart';

class RaiseTicketScreen extends StatefulWidget {
  const RaiseTicketScreen({super.key});

  @override
  State<RaiseTicketScreen> createState() => _RaiseTicketScreenState();
}

class _RaiseTicketScreenState extends State<RaiseTicketScreen> {
  static const Color _pinkColor = AppThemeContext.pinkColor;

  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _vehicleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  String? _selectedTicketType;
  File? _selectedImage;

  final List<String> _ticketTypes = const [
    'Technical Issue',
    'Billing',
    'Device Problem',
    'General Support',
  ];

  @override
  void dispose() {
    _vehicleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _openVehicleDialog() async {
    final String? selected = await showVehicleSearchDialog(
      context,
      initialSelection: _vehicleController.text,
    );

    if (selected != null && mounted) {
      setState(() {
        _vehicleController.text = selected;
      });
    }
  }

  void _showTicketTypeDialog() {
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
                for (final type in _ticketTypes)
                  ListTile(
                    title: Text(
                      type,
                      style: TextStyle(
                        color: context.appTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedTicketType = type;
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

  void _submitTicket() {
    if (_vehicleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle')),
      );
      return;
    }

    if (_selectedTicketType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select ticket type')),
      );
      return;
    }

    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter message')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ticket raised successfully')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: context.appSurface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(22),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('select vehicle'),
                      GestureDetector(
                        onTap: _openVehicleDialog,
                        child: AbsorbPointer(
                          child: _buildOutlinedField(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.search,
                                  color: context.appTextColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _vehicleController.text.isEmpty
                                        ? 'Search Vehicle'
                                        : _vehicleController.text,
                                    style: TextStyle(
                                      color: _vehicleController.text.isEmpty
                                          ? context.appSecondaryText
                                          : context.appTextColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Ticket Type'),
                      GestureDetector(
                        onTap: _showTicketTypeDialog,
                        child: _buildOutlinedField(
                          child: Text(
                            _selectedTicketType ?? 'Select Ticket Type',
                            style: TextStyle(
                              color: _selectedTicketType == null
                                  ? context.appSecondaryText
                                  : context.appTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Message'),
                      TextField(
                        controller: _messageController,
                        minLines: 4,
                        maxLines: 5,
                        style: TextStyle(color: context.appTextColor),
                        decoration: InputDecoration(
                          hintText: 'Enter Message',
                          hintStyle: TextStyle(
                            color: context.appSecondaryText,
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: context.appSurface,
                          contentPadding: const EdgeInsets.all(14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: context.appTextColor.withValues(alpha: 0.85),
                              width: 0.9,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: context.appTextColor,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Select Image'),
                      GestureDetector(
                        onTap: _showSelectImageDialog,
                        child: Container(
                          width: double.infinity,
                          height: 170,
                          decoration: BoxDecoration(
                            color: context.appSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: context.appTextColor.withValues(alpha: 0.85),
                              width: 0.9,
                            ),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
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
                                            color: _pinkColor.withValues(
                                              alpha: 0.15,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.image_outlined,
                                            color: _pinkColor,
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
                                              color: _pinkColor,
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
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: Material(
                  color: _pinkColor,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: _submitTicket,
                    borderRadius: BorderRadius.circular(8),
                    child: const Center(
                      child: Text(
                        'Raise Ticket',
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: _pinkColor,
              size: 20,
            ),
          ),
          Text(
            'Raise Ticket',
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

  Widget _buildOutlinedField({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.appTextColor.withValues(alpha: 0.85),
          width: 0.9,
        ),
      ),
      child: child,
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
            Icon(icon, color: AppThemeContext.pinkColor, size: 28),
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
