import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/app_theme.dart';
import '../../services/general_settings_controller.dart';
import '../../data/expense_local_store.dart';
import '../../data/vehicle_data.dart';
import '../../l10n/app_l10n.dart';
import '../../models/expense_model.dart';
import 'add_expense_screen.dart';
import 'expense_detail_screen.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  static const Color pinkColor = AppThemeContext.pinkColor;

  int _selectedFilterIndex = 0;
  int? _selectedMonthIndex;
  final TextEditingController _searchController = TextEditingController();

  List<String> get _vehicles =>
      VehicleData.vehicles.map((vehicle) => vehicle.name).toList();

  Set<String> _selectedVehicles = {};

  final List<String> _filters = [
    'Today',
    'Yesterday',
    'Week',
    'Month',
  ];

  final List<String> _months = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  List<ExpenseModel> _expenses = <ExpenseModel>[];
  bool _loadingExpenses = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    final List<ExpenseModel> loaded = await ExpenseLocalStore.loadAll();
    if (!mounted) {
      return;
    }
    setState(() {
      _expenses = loaded;
      _loadingExpenses = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    return _expenses.fold(0, (sum, item) => sum + item.amount);
  }

  String? get _selectedVehicleForAdd {
    if (_selectedVehicles.length == 1) {
      return _selectedVehicles.first;
    }

    final String searchText = _searchController.text.trim();
    if (searchText.isNotEmpty && !searchText.contains('vehicles selected')) {
      return searchText;
    }

    return null;
  }

  void _openAddExpenseScreen() {
    if (_selectedVehicleForAdd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Please select a vehicle first')),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => AddExpenseScreen(
          initialVehicle: _selectedVehicleForAdd,
        ),
      ),
    ).then((_) {
      if (mounted) {
        _loadExpenses();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpenseScreen,
        backgroundColor: pinkColor,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildTopSection(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildChartSection(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 90),
                      child: Column(
                        children: [
                          for (final expense in _expenses)
                            _ExpenseListTile(
                              item: expense,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (context) => ExpenseDetailScreen(
                                      expense: expense,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: context.appSurface,
      padding: const EdgeInsets.fromLTRB(4, 6, 16, 8),
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
            context.tr('Expense'),
            style: TextStyle(
              color: context.appTextColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: context.appTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: 'Total: '),
                TextSpan(
                  text: context
                      .watch<GeneralSettingsController>()
                      .formatCurrency(_totalAmount),
                  style: const TextStyle(
                    color: pinkColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSection() {
    return Container(
      color: context.appSurface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        children: [
          GestureDetector(
            onTap: _showVehicleSearchDialog,
            child: AbsorbPointer(
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: context.appTextColor, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search Vehicle',
                    hintStyle: TextStyle(
                      color: context.appSecondaryText,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: pinkColor,
                      size: 20,
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 20,
                    ),
                    filled: true,
                    fillColor: context.appFieldFill,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: context.appBorder,
                        width: 0.9,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: context.appTextColor,
                        width: 1,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide(
                        color: context.appBorder,
                        width: 0.9,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < _filters.length; i++) ...[
                Expanded(
                  child: _FilterChip(
                    label: _filters[i],
                    isSelected: _selectedFilterIndex == i,
                    onTap: () {
                      setState(() {
                        _selectedFilterIndex = i;
                      });
                    },
                  ),
                ),
                if (i != _filters.length - 1) const SizedBox(width: 6),
              ],
              const SizedBox(width: 8),
              Material(
                color: pinkColor,
                borderRadius: BorderRadius.circular(6),
                child: InkWell(
                  onTap: _showChooseMonthSheet,
                  borderRadius: BorderRadius.circular(6),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.tune,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    final Color axisColor = context.appTextColor;

    return Container(
      color: context.appSurface,
      width: double.infinity,
      height: 210,
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 4),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 1,
          minY: 0,
          maxY: 198,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(
            show: true,
            border: Border(
              top: BorderSide(color: axisColor, width: 1),
              right: BorderSide(color: axisColor, width: 1),
              left: const BorderSide(color: Colors.transparent),
              bottom: const BorderSide(color: Colors.transparent),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 33,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: axisColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  if (value != 0) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    '7/2026',
                    style: TextStyle(
                      color: axisColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: const [],
        ),
      ),
    );
  }

  void _showVehicleSearchDialog() {
    final TextEditingController dialogSearchController = TextEditingController();
    Set<String> tempSelected = Set<String>.from(_selectedVehicles);
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
                            tempSelected.clear();
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
                        controller: dialogSearchController,
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
                          final bool isChecked = tempSelected.contains(vehicle);

                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                if (isChecked) {
                                  tempSelected.remove(vehicle);
                                } else {
                                  tempSelected.add(vehicle);
                                }
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
                          child: _VehicleDialogButton(
                            label: 'CANCEL',
                            onTap: () => Navigator.pop(dialogContext),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _VehicleDialogButton(
                            label: 'Apply',
                            onTap: () {
                              setState(() {
                                _selectedVehicles =
                                    Set<String>.from(tempSelected);
                                if (_selectedVehicles.isEmpty) {
                                  _searchController.clear();
                                } else if (_selectedVehicles.length == 1) {
                                  _searchController.text =
                                      _selectedVehicles.first;
                                } else {
                                  _searchController.text =
                                      '${_selectedVehicles.length} vehicles selected';
                                }
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
    ).whenComplete(dialogSearchController.dispose);
  }

  void _showChooseMonthSheet() {
    int tempSelectedMonth = _selectedMonthIndex ?? DateTime.now().month - 1;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose month',
                    style: TextStyle(
                      color: context.appTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _months.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.4,
                    ),
                    itemBuilder: (context, index) {
                      final bool isSelected = tempSelectedMonth == index;

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setSheetState(() {
                              tempSelectedMonth = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: context.appFieldFill,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? pinkColor
                                    : context.appBorder,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _months[index],
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: context.appTextColor,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Material(
                      color: pinkColor,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMonthIndex = tempSelectedMonth;
                          });
                          Navigator.pop(sheetContext);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: const Center(
                          child: Text(
                            'Apply',
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
            );
          },
        );
      },
    );
  }
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
      color: _ExpenseScreenState.pinkColor,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              context.tr(label),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.appChipBackground,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Text(
            context.tr(label),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: _ExpenseScreenState.pinkColor,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseListTile extends StatelessWidget {
  final ExpenseModel item;
  final VoidCallback onTap;

  const _ExpenseListTile({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: context.appBorder, width: 1.2),
                ),
                child: Icon(
                  Icons.restaurant,
                  color: context.appSecondaryText,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.deviceName,
                      style: TextStyle(
                        color: context.appTextColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _ExpenseScreenState.pinkColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(
                          color: _ExpenseScreenState.pinkColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    context
                        .watch<GeneralSettingsController>()
                        .formatCurrency(item.amount),
                    style: TextStyle(
                      color: context.appTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.date,
                    style: TextStyle(
                      color: context.appSecondaryText,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: context.appSecondaryText,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
