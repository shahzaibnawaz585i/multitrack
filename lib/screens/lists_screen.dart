// import 'package:flutter/material.dart';
//
// import '../data/vehicle_data.dart';
// import '../widgets/status_card.dart';
// import '../widgets/vehicle_card.dart';
//
// class ListScreen extends StatefulWidget {
//   const ListScreen({super.key});
//
//   @override
//   State<ListScreen> createState() => _ListScreenState();
// }
//
// class _ListScreenState extends State<ListScreen> {
//   String selectedFilter = "all";
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey.shade100,
//       body: SafeArea(
//         child: Column(
//           children: [
//             /// Header
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     "Vehicle List",
//                     style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                   ),
//
//                   Row(
//                     children: [
//                       _circleIcon(Icons.add, Colors.pink),
//
//                       const SizedBox(width: 10),
//
//                       _circleIcon(Icons.search, Colors.pink),
//
//                       const SizedBox(width: 10),
//
//                       Stack(
//                         children: [
//                           _circleIcon(Icons.notifications_none, Colors.cyan),
//
//                           Positioned(
//                             right: 0,
//                             top: 0,
//                             child: Container(
//                               padding: const EdgeInsets.all(4),
//                               decoration: const BoxDecoration(
//                                 color: Colors.white,
//                                 shape: BoxShape.circle,
//                               ),
//                               child: const Text(
//                                 "0",
//                                 style: TextStyle(
//                                   fontSize: 10,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//
//             /// Status Cards
//             SizedBox(
//               height: 180,
//               child: ListView(
//                 scrollDirection: Axis.horizontal,
//                 padding: const EdgeInsets.symmetric(horizontal: 10),
//                 children: [
//                   StatusCard(
//                     color: Colors.purple,
//                     title: "All vehicles",
//                     count: VehicleData.vehicles.length.toString(),
//                     isSelected: selectedFilter == "all",
//                     onTap: () {
//                       setState(() {
//                         selectedFilter = "all";
//                       });
//                     },
//                   ),
//
//                   StatusCard(
//                     color: Colors.green,
//                     title: "Running",
//                     count: VehicleData.vehicles
//                         .where((e) => e.status.toLowerCase() == "running")
//                         .length
//                         .toString(),
//                     isSelected: selectedFilter == "running",
//                     onTap: () {
//                       setState(() {
//                         selectedFilter = "running";
//                       });
//                     },
//                   ),
//
//                   StatusCard(
//                     color: Colors.orange,
//                     title: "Idle",
//                     count: VehicleData.vehicles
//                         .where((e) => e.status.toLowerCase() == "idle")
//                         .length
//                         .toString(),
//                     isSelected: selectedFilter == "idle",
//                     onTap: () {
//                       setState(() {
//                         selectedFilter = "idle";
//                       });
//                     },
//                   ),
//
//                   StatusCard(
//                     color: Colors.red,
//                     title: "Stopped",
//                     count: VehicleData.vehicles
//                         .where((e) => e.status.toLowerCase() == "stopped")
//                         .length
//                         .toString(),
//                     isSelected: selectedFilter == "stopped",
//                     onTap: () {
//                       setState(() {
//                         selectedFilter = "stopped";
//                       });
//                     },
//                   ),
//
//                   StatusCard(
//                     color: Colors.grey,
//                     title: "Inactive",
//                     count: VehicleData.vehicles
//                         .where((e) => e.status.toLowerCase() == "inactive")
//                         .length
//                         .toString(),
//                     isSelected: selectedFilter == "inactive",
//                     onTap: () {
//                       setState(() {
//                         selectedFilter = "inactive";
//                       });
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             SizedBox(height: 10),
//
//             Container(height: 5, color: Colors.white),
//
//             /// Vehicle List
//             Expanded(
//               child: Builder(
//                 builder: (context) {
//                   final vehicles = selectedFilter == "all"
//                       ? VehicleData.vehicles
//                       : VehicleData.vehicles
//                             .where(
//                               (e) =>
//                                   e.status.toLowerCase() ==
//                                   selectedFilter.toLowerCase(),
//                             )
//                             .toList();
//
//                   if (vehicles.isEmpty) {
//                     return const Center(
//                       child: Text(
//                         "No Vehicle Found",
//                         style: TextStyle(fontSize: 16),
//                       ),
//                     );
//                   }
//
//                   return ListView.builder(
//                     padding: const EdgeInsets.all(10),
//                     itemCount: vehicles.length,
//                     itemBuilder: (context, index) {
//                       return VehicleCard(vehicle: vehicles[index]);
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _circleIcon(IconData icon, Color color) {
//     return Container(
//       height: 42,
//       width: 42,
//       decoration: BoxDecoration(
//         color: color.withOpacity(.1),
//         shape: BoxShape.circle,
//       ),
//       child: Icon(icon, color: color, size: 22),
//     );
//   }
// }
import 'package:flutter/material.dart';

import '../data/vehicle_data.dart';
import '../models/vehicle_model.dart';
import '../widgets/status_card.dart';
import '../widgets/vehicle_card.dart';

class ListScreen extends StatefulWidget {
  final String initialFilter;

  const ListScreen({super.key, this.initialFilter = 'all'});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  late String selectedFilter;

  static const List<String> _validFilters = <String>[
    'all',
    'running',
    'idle',
    'stopped',
    'inactive',
  ];

  @override
  void initState() {
    super.initState();
    selectedFilter = _normalizeFilter(widget.initialFilter);
  }

  /// Agar parent screen future mein filter change kare to ListScreen
  /// automatically new filter apply karegi.
  @override
  void didUpdateWidget(covariant ListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialFilter != widget.initialFilter) {
      final String newFilter = _normalizeFilter(widget.initialFilter);

      if (selectedFilter != newFilter) {
        setState(() {
          selectedFilter = newFilter;
        });
      }
    }
  }

  String _normalizeFilter(String filter) {
    final String normalizedFilter = filter.trim().toLowerCase();

    if (_validFilters.contains(normalizedFilter)) {
      return normalizedFilter;
    }

    return 'all';
  }

  void _changeFilter(String filter) {
    final String normalizedFilter = _normalizeFilter(filter);

    if (selectedFilter == normalizedFilter) {
      return;
    }

    setState(() {
      selectedFilter = normalizedFilter;
    });
  }

  List<VehicleModel> get _filteredVehicles {
    if (selectedFilter == 'all') {
      return VehicleData.vehicles;
    }

    return VehicleData.vehicles
        .where((VehicleModel vehicle) {
          return vehicle.status.trim().toLowerCase() == selectedFilter;
        })
        .toList(growable: false);
  }

  int _getVehicleCount(String status) {
    if (status == 'all') {
      return VehicleData.vehicles.length;
    }

    return VehicleData.vehicles.where((VehicleModel vehicle) {
      return vehicle.status.trim().toLowerCase() == status;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    final List<VehicleModel> vehicles = _filteredVehicles;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            _buildStatusCards(),

            const SizedBox(height: 10),

            Container(height: 5, color: Colors.white),

            Expanded(
              child: vehicles.isEmpty
                  ? _buildEmptyState()
                  : _buildVehicleList(vehicles),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Vehicle List',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          _buildCircleIconButton(
            icon: Icons.add,
            color: Colors.pink,
            onTap: () {
              // Future: Add Vehicle Screen.
            },
          ),

          const SizedBox(width: 10),

          _buildCircleIconButton(
            icon: Icons.search,
            color: Colors.pink,
            onTap: () {
              // Future: Vehicle Search.
            },
          ),

          const SizedBox(width: 10),

          Stack(
            clipBehavior: Clip.none,
            children: [
              _buildCircleIconButton(
                icon: Icons.notifications_none,
                color: Colors.cyan,
                onTap: () {
                  // Future: Notification Screen.
                },
              ),

              Positioned(
                right: -1,
                top: -2,
                child: Container(
                  constraints: const BoxConstraints(
                    minHeight: 20,
                    minWidth: 20,
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '0',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCards() {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        children: [
          StatusCard(
            color: Colors.purple,
            title: 'All vehicles',
            count: _getVehicleCount('all').toString(),
            isSelected: selectedFilter == 'all',
            onTap: () => _changeFilter('all'),
          ),
          StatusCard(
            color: Colors.green,
            title: 'Running',
            count: _getVehicleCount('running').toString(),
            isSelected: selectedFilter == 'running',
            onTap: () => _changeFilter('running'),
          ),
          StatusCard(
            color: Colors.orange,
            title: 'Idle',
            count: _getVehicleCount('idle').toString(),
            isSelected: selectedFilter == 'idle',
            onTap: () => _changeFilter('idle'),
          ),
          StatusCard(
            color: Colors.red,
            title: 'Stopped',
            count: _getVehicleCount('stopped').toString(),
            isSelected: selectedFilter == 'stopped',
            onTap: () => _changeFilter('stopped'),
          ),
          StatusCard(
            color: Colors.grey,
            title: 'Inactive',
            count: _getVehicleCount('inactive').toString(),
            isSelected: selectedFilter == 'inactive',
            onTap: () => _changeFilter('inactive'),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList(List<VehicleModel> vehicles) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(10),
      itemCount: vehicles.length,
      itemBuilder: (BuildContext context, int index) {
        final VehicleModel vehicle = vehicles[index];

        return VehicleCard(
          key: ValueKey<String>('${vehicle.name}_${vehicle.status}_$index'),
          vehicle: vehicle,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_car_outlined,
              size: 55,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'No Vehicle Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              'No vehicles are available in the selected status.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.10),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          height: 42,
          width: 42,
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
