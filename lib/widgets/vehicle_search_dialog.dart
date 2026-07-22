import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../data/vehicle_data.dart';

Future<String?> showVehicleSearchDialog(
  BuildContext context, {
  String? initialSelection,
}) {
  final TextEditingController searchController = TextEditingController();
  final List<String> vehicles =
      VehicleData.vehicles.map((vehicle) => vehicle.name).toList();

  String? tempSelected = initialSelection?.isNotEmpty == true
      ? initialSelection
      : null;
  List<String> filteredVehicles = List<String>.from(vehicles);

  return showDialog<String>(
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
                          color: AppThemeContext.pinkColor,
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
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appTextColor,
                      ),
                      onChanged: (query) {
                        setDialogState(() {
                          filteredVehicles = vehicles
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
                          borderSide: const BorderSide(
                            color: AppThemeContext.pinkColor,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppThemeContext.pinkColor,
                            width: 1.2,
                          ),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppThemeContext.pinkColor,
                          ),
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
                                        ? AppThemeContext.pinkColor
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
                        child: _VehicleDialogButton(
                          label: 'CANCEL',
                          onTap: () => Navigator.pop(dialogContext),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _VehicleDialogButton(
                          label: 'Apply',
                          onTap: () =>
                              Navigator.pop(dialogContext, tempSelected),
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

class _VehicleDialogButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _VehicleDialogButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppThemeContext.pinkColor,
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
