import 'package:flutter/material.dart';

import '../../l10n/app_l10n.dart';
import '../../models/driver_model.dart';
import '../../services/driver_service.dart';
import '../../theme/app_theme_tokens.dart';

class DriversScreen extends StatefulWidget {
  const DriversScreen({super.key});

  @override
  State<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends State<DriversScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);
  static const Color _greenColor = Color(0xFF4CAF50);
  static const Color _greenHalo = Color(0xFFB9E4BA);

  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  final List<_DriverItem> _drivers = <_DriverItem>[];

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    setState(() => _isLoading = true);
    try {
      final List<DriverModel> remote = await DriverService.getDrivers();
      if (!mounted) {
        return;
      }
      if (remote.isNotEmpty) {
        setState(() {
          _drivers
            ..clear()
            ..addAll(remote.map(_DriverItem.fromModel));
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_DriverItem> get _filteredDrivers {
    final String query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _drivers;
    }
    return _drivers
        .where(
          (_DriverItem item) =>
              item.name.toLowerCase().contains(query) ||
              item.phone.contains(query) ||
              item.uniqueId.contains(query),
        )
        .toList();
  }

  Future<void> _openAddDriver() async {
    final _DriverItem? created = await Navigator.push<_DriverItem>(
      context,
      MaterialPageRoute<_DriverItem>(
        builder: (_) => const _AddDriverScreen(),
      ),
    );

    if (created == null || !mounted) {
      return;
    }

    setState(() => _isLoading = true);
    final bool saved = await DriverService.addDriver(
      name: created.name,
      phone: created.phone,
      uniqueId: created.uniqueId,
    );

    if (!mounted) {
      return;
    }

    if (saved) {
      await _loadDrivers();
    } else {
      setState(() {
        _isLoading = false;
        _drivers.insert(0, created);
      });
    }
  }

  Future<void> _openEditDriver(_DriverItem item) async {
    final int index = _drivers.indexOf(item);
    final _DriverItem? updated = await Navigator.push<_DriverItem>(
      context,
      MaterialPageRoute<_DriverItem>(
        builder: (_) => _EditDriverScreen(driver: item),
      ),
    );

    if (updated == null || !mounted || index < 0) {
      return;
    }

    setState(() {
      _drivers[index] = updated;
    });
  }

  Future<void> _confirmDelete(_DriverItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black45,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Theme.of(context).cardColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'You want to delete this driver?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, false),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pinkColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(dialogContext, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pinkColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'OK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
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
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() {
        _drivers.remove(item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<_DriverItem> visible = _filteredDrivers;

    return Scaffold(
      backgroundColor: Theme.of(context).cardColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        surfaceTintColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: _pinkColor,
            size: 20,
          ),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Text(
              context.tr('Drivers'),
              style: TextStyle(
                color: context.textColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: context.tr('Search User'),
                    hintStyle: TextStyle(
                      color: context.labelTextColor,
                      fontSize: 14,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    suffixIcon: Icon(
                      Icons.search,
                      color: _pinkColor,
                      size: 20,
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                    filled: true,
                    fillColor: context.fieldFillColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: Color(0xFF555555),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(
                        color: Color(0xFF555555),
                        width: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDriver,
        backgroundColor: _pinkColor,
        elevation: 4,
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: _isLoading
          ? const Center(child: _LoadingDots())
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 90),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (BuildContext context, int index) {
                final _DriverItem item = visible[index];
                return _DriverRow(
                  item: item,
                  onAdd: () {},
                  onEdit: () => _openEditDriver(item),
                  onDelete: () => _confirmDelete(item),
                );
              },
            ),
    );
  }
}

class _DriverItem {
  final int? id;
  final String name;
  final String phone;
  final String uniqueId;

  const _DriverItem({
    this.id,
    required this.name,
    required this.phone,
    required this.uniqueId,
  });

  factory _DriverItem.fromModel(DriverModel model) {
    return _DriverItem(
      id: model.id,
      name: model.name,
      phone: model.phone,
      uniqueId: model.uniqueId,
    );
  }
}

class _DriverRow extends StatelessWidget {
  final _DriverItem item;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _DriverRow({
    required this.item,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  static const Color _pinkColor = Color(0xFFFF2F68);
  static const Color _greenColor = Color(0xFF4CAF50);
  static const Color _greenHalo = Color(0xFFB9E4BA);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _greenHalo,
          ),
          alignment: Alignment.center,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _greenColor,
            ),
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Phone : ${item.phone}',
                style: TextStyle(
                  color: context.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              height: 30,
              child: ElevatedButton(
                onPressed: onAdd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _pinkColor,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'Add Driver',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onEdit,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  icon: Icon(
                    Icons.edit_square,
                    color: _greenColor,
                    size: 22,
                  ),
                ),
                IconButton(
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                  icon: Icon(
                    Icons.delete_outline,
                    color: _pinkColor,
                    size: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _AddDriverScreen extends StatefulWidget {
  const _AddDriverScreen();

  @override
  State<_AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<_AddDriverScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _uniqueIdController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _uniqueIdController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
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

  void _submit() {
    final String name = _nameController.text.trim();
    final String uniqueId = _uniqueIdController.text.trim();

    if (name.isEmpty || uniqueId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter name and unique id'))),
      );
      return;
    }

    Navigator.pop(
      context,
      _DriverItem(name: name, phone: uniqueId, uniqueId: uniqueId),
    );
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
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: _pinkColor,
            size: 20,
          ),
        ),
        titleSpacing: 0,
        title: Text(
          context.tr('Add new driver'),
          style: TextStyle(
            color: context.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: context.textColor, fontSize: 15),
                  decoration: _fieldDecoration(hint: 'Name'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _uniqueIdController,
                  style: TextStyle(color: context.textColor, fontSize: 15),
                  decoration: _fieldDecoration(hint: 'Unique Id'),
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
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pinkColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Add new driver',
                    style: TextStyle(
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

class _EditDriverScreen extends StatefulWidget {
  final _DriverItem driver;

  const _EditDriverScreen({required this.driver});

  @override
  State<_EditDriverScreen> createState() => _EditDriverScreenState();
}

class _EditDriverScreenState extends State<_EditDriverScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);

  late final TextEditingController _nameController;
  late final TextEditingController _uniqueIdController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.driver.name);
    _uniqueIdController = TextEditingController(text: widget.driver.uniqueId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _uniqueIdController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
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

  void _submit() {
    final String name = _nameController.text.trim();
    final String uniqueId = _uniqueIdController.text.trim();

    if (name.isEmpty || uniqueId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter name and unique id'))),
      );
      return;
    }

    Navigator.pop(
      context,
      _DriverItem(name: name, phone: uniqueId, uniqueId: uniqueId),
    );
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
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: _pinkColor,
            size: 20,
          ),
        ),
        titleSpacing: 0,
        title: Text(
          widget.driver.name,
          style: TextStyle(
            color: context.textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: context.textColor, fontSize: 15),
                  decoration: _fieldDecoration(),
                ),
                const SizedBox(height: 14),
                Text(
                  'Unique Id',
                  style: TextStyle(
                    color: context.textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _uniqueIdController,
                  style: TextStyle(color: context.textColor, fontSize: 15),
                  decoration: _fieldDecoration(),
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
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pinkColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'UPDATE USER',
                    style: TextStyle(
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

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final int active = (_controller.value * 3).floor() % 3;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(3, (int index) {
            final bool isActive = index == active;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isActive ? 12 : 9,
                height: isActive ? 12 : 9,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFF2F68)
                      : const Color(0xFFFF2F68).withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
