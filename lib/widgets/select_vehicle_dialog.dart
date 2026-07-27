import 'package:flutter/material.dart';

import '../models/vehicle_model.dart';

class SelectVehicleDialog extends StatefulWidget {
  final VehicleModel? initialSelected;
  final List<VehicleModel> vehicles;

  const SelectVehicleDialog({
    super.key,
    required this.initialSelected,
    required this.vehicles,
  });

  @override
  State<SelectVehicleDialog> createState() => _SelectVehicleDialogState();
}

class _SelectVehicleDialogState extends State<SelectVehicleDialog> {
  static const Color _pinkColor = Color(0xfff53d6b);

  final TextEditingController dialogSearchController = TextEditingController();
  VehicleModel? tempSelected;
  List<VehicleModel> filteredList = [];

  @override
  void initState() {
    super.initState();
    tempSelected = widget.initialSelected;
    filteredList = widget.vehicles;
    dialogSearchController.addListener(_filterVehicles);
  }

  @override
  void dispose() {
    dialogSearchController.dispose();
    super.dispose();
  }

  void _filterVehicles() {
    final String query = dialogSearchController.text.trim().toLowerCase();
    setState(() {
      filteredList = widget.vehicles
          .where((vehicle) => vehicle.name.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
      ),
      backgroundColor: Theme.of(context).cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      child: SizedBox(
        width: screenSize.width * 0.94,
        height: screenSize.height * 0.72,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Vehicle',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF292B32),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xfff5f5f5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: dialogSearchController,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'Search vehicle...',
                          hintStyle: TextStyle(color: Colors.black38),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    if (dialogSearchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: dialogSearchController.clear,
                        child: const Icon(
                          Icons.clear,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filteredList.isEmpty
                    ? const Center(
                        child: Text(
                          'No vehicles found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final VehicleModel vehicle = filteredList[index];
                          final bool isSelected =
                              tempSelected?.name == vehicle.name;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                tempSelected = vehicle;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected
                                            ? _pinkColor
                                            : Colors.black45,
                                        width: 2,
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(3),
                                    child: isSelected
                                        ? Container(
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: _pinkColor,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    vehicle.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF292B32),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pinkColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, tempSelected),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _pinkColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
