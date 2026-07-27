import 'package:flutter/material.dart';

import '../constants/app_theme.dart';
import '../models/vehicle_model.dart';

class VehiclePickerDialog extends StatefulWidget {
  final List<VehicleModel> vehicles;
  final VehicleModel? selectedVehicle;

  const VehiclePickerDialog({
    super.key,
    required this.vehicles,
    this.selectedVehicle,
  });

  @override
  State<VehiclePickerDialog> createState() =>
      _VehiclePickerDialogState();
}

class _VehiclePickerDialogState
    extends State<VehiclePickerDialog> {

  late List<VehicleModel> filteredVehicles;

  VehicleModel? selectedVehicle;

  final TextEditingController searchController =
  TextEditingController();

  @override
  void initState() {
    super.initState();

    filteredVehicles = List.from(widget.vehicles);

    selectedVehicle = widget.selectedVehicle;

    searchController.addListener(_searchVehicle);
  }

  void _searchVehicle() {
    final query = searchController.text.toLowerCase();

    setState(() {
      filteredVehicles = widget.vehicles.where((vehicle) {
        return vehicle.name
            .toLowerCase()
            .contains(query) ||
            vehicle.status
                .toLowerCase()
                .contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        backgroundColor: context.appSurface,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),

        insetPadding:
        const EdgeInsets.symmetric(horizontal: 20),

        child: SizedBox(
            width: double.infinity,
          height: MediaQuery.of(context).size.height * .75,
            child: Column(
                children: [
                const SizedBox(height: 20),
             Text(
              "Select Vehicle",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.appTextColor,
              ),
            ),
             const SizedBox(height: 20),

            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 18),
              child: TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                style: TextStyle(color: context.appTextColor),
                decoration: InputDecoration(
                  hintText: "Search Vehicle",
                  hintStyle: TextStyle(color: context.appSecondaryText),

                  prefixIcon: const Icon(
                    Icons.search,
                    color: Colors.pink,
                  ),

                  filled: true,

                  fillColor: context.appFieldFill,

                  contentPadding:
                  const EdgeInsets.symmetric(
                    vertical: 15,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(12),

                    borderSide: BorderSide(
                      color: context.appBorder,
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                    BorderRadius.circular(12),

                    borderSide:
                    const BorderSide(
                      color: Colors.pink,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Divider(color: context.appBorder),

            Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),

                  itemCount: filteredVehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = filteredVehicles[index];

                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedVehicle = vehicle;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: context.appFieldFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: RadioListTile<VehicleModel>(
                          value: vehicle,
                          groupValue: selectedVehicle,
                          activeColor: Colors.pink,

                          onChanged: (value) {
                            setState(() {
                              selectedVehicle = value;
                            });
                          },

                          secondary: CircleAvatar(
                            radius: 9,
                            backgroundColor: vehicle.color,
                          ),

                          title: Text(
                            vehicle.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: context.appTextColor,
                            ),
                          ),

                          subtitle: Text(
                            vehicle.status,
                            style: TextStyle(
                              color: vehicle.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ),

                  Divider(height: 1, color: context.appBorder),

                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [

                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 55),
                              side: const BorderSide(
                                color: Colors.pink,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),

                            onPressed: () {
                              Navigator.pop(context);
                            },

                            child: const Text(
                              "CANCEL",
                              style: TextStyle(
                                color: Colors.pink,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 15),

                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              minimumSize: const Size(0, 55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),

                            onPressed: () {
                              if (selectedVehicle != null) {
                                Navigator.pop(context, selectedVehicle);
                              }
                            },

                            child: const Text(
                              "APPLY",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
            ),
        ),
    );
  }
}
