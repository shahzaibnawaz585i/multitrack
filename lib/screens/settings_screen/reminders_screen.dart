import 'package:flutter/material.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);
  static const Color _greenColor = Color(0xFF4CAF50);
  static const Color _greenHalo = Color(0xFFB9E4BA);
  static const Color _bgColor = Color(0xFFF5F5F5);

  bool _isLoading = true;

  final List<_ReminderItem> _reminders = <_ReminderItem>[
    const _ReminderItem(
      title: 'Service',
      type: 'odometer',
      period: 60000.0,
      previousValue: 50000.0,
    ),
    const _ReminderItem(
      title: 'Battery Change',
      type: 'odometer',
      period: 50000.0,
      previousValue: 40000.0,
    ),
    const _ReminderItem(
      title: 'Changement de',
      type: 'odometer',
      period: 100000.0,
      previousValue: 80000.0,
    ),
    const _ReminderItem(
      title: 'Autres',
      type: 'odometer',
      period: 10000.0,
      previousValue: 5000.0,
    ),
    const _ReminderItem(
      title: 'Changement',
      type: 'odometer',
      period: 20000.0,
      previousValue: 15000.0,
    ),
  ];

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
    });
  }

  Future<void> _openAddReminder() async {
    final _ReminderItem? created = await Navigator.push<_ReminderItem>(
      context,
      MaterialPageRoute<_ReminderItem>(
        builder: (_) => const _AddNewReminderScreen(),
      ),
    );

    if (created == null || !mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _reminders.insert(0, created);
    });
  }

  Future<void> _openEditReminder(_ReminderItem item) async {
    final int index = _reminders.indexOf(item);
    final _ReminderItem? updated = await Navigator.push<_ReminderItem>(
      context,
      MaterialPageRoute<_ReminderItem>(
        builder: (_) => _ReminderFormScreen(
          appBarTitle: 'Add New Reminder',
          buttonLabel: 'Update Reminder',
          initialTitle: item.title,
          initialPrevious: item.previousValue,
          initialPeriod: item.period,
        ),
      ),
    );

    if (updated == null || !mounted || index < 0) {
      return;
    }

    setState(() {
      _reminders[index] = updated;
    });
  }

  Future<void> _confirmDelete(_ReminderItem item) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black45,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'You Want To Delete This User?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
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
                          child: const Text(
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
                          child: const Text(
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
        _reminders.remove(item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isLoading ? Colors.white : _bgColor,
      appBar: AppBar(
        backgroundColor: _isLoading ? Colors.white : _bgColor,
        surfaceTintColor: Colors.transparent,
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
        title: const Text(
          'Maintenance Reminders',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddReminder,
        backgroundColor: _pinkColor,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: _isLoading
          ? const Center(child: _LoadingDots())
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
              itemCount: _reminders.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (BuildContext context, int index) {
                final _ReminderItem item = _reminders[index];
                return Container(
                  padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: _greenHalo,
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _greenColor,
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Type: ${item.type}',
                              style: const TextStyle(
                                color: Color(0xFF555555),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              'Period: ${item.period}',
                              style: const TextStyle(
                                color: Color(0xFF555555),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _openEditReminder(item),
                        icon: const Icon(
                          Icons.edit_square,
                          color: _greenColor,
                          size: 24,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _confirmDelete(item),
                        icon: const Icon(
                          Icons.delete_outline,
                          color: _pinkColor,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _ReminderItem {
  final String title;
  final String type;
  final double period;
  final double previousValue;

  const _ReminderItem({
    required this.title,
    required this.type,
    required this.period,
    required this.previousValue,
  });
}

class _AddNewReminderScreen extends StatefulWidget {
  const _AddNewReminderScreen();

  @override
  State<_AddNewReminderScreen> createState() => _AddNewReminderScreenState();
}

class _AddNewReminderScreenState extends State<_AddNewReminderScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);

  String? _selectedType;
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _odometerStartController =
      TextEditingController();
  final TextEditingController _periodController = TextEditingController();

  @override
  void dispose() {
    _typeController.dispose();
    _odometerStartController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF666666),
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
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

  Future<void> _pickReminderType() async {
    final String? type = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const _AddReminderTypeScreen(),
      ),
    );

    if (type == null || !mounted) {
      return;
    }

    setState(() {
      _selectedType = type;
      _typeController.text = type;
    });
  }

  void _submit() {
    final String type = (_selectedType ?? '').trim();
    final double? start = double.tryParse(_odometerStartController.text.trim());
    final double? period = double.tryParse(_periodController.text.trim());

    if (type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select reminder type')),
      );
      return;
    }

    if (start == null || period == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter odometer values')),
      );
      return;
    }

    Navigator.pop(
      context,
      _ReminderItem(
        title: type,
        type: 'odometer',
        period: period,
        previousValue: start,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
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
        title: const Text(
          'Add New Reminder',
          style: TextStyle(
            color: Colors.black87,
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
                  readOnly: true,
                  onTap: _pickReminderType,
                  controller: _typeController,
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  decoration: _fieldDecoration(hint: 'Select Reminder Type'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _odometerStartController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  decoration: _fieldDecoration(hint: 'Odometer Start'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _periodController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
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
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pinkColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Reminder',
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

class _AddReminderTypeScreen extends StatefulWidget {
  const _AddReminderTypeScreen();

  @override
  State<_AddReminderTypeScreen> createState() => _AddReminderTypeScreenState();
}

class _AddReminderTypeScreenState extends State<_AddReminderTypeScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);
  static const List<String> _types = <String>[
    'Service',
    'Oil Change',
    'AC service',
    'Filter Change',
    'Tyre Change',
    'Battery Change',
    'Others',
  ];

  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
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
        title: const Text(
          'Add New Reminder',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final String type in _types)
                      InkWell(
                        onTap: () {
                          setState(() {
                            _selected = type;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            type,
                            style: TextStyle(
                              color: _selected == type
                                  ? _pinkColor
                                  : Colors.black87,
                              fontSize: 16,
                              fontWeight: _selected == type
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, _selected ?? 'Service');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _pinkColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Reminder',
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

class _ReminderFormScreen extends StatefulWidget {
  final String appBarTitle;
  final String buttonLabel;
  final String initialTitle;
  final double initialPrevious;
  final double initialPeriod;

  const _ReminderFormScreen({
    required this.appBarTitle,
    required this.buttonLabel,
    required this.initialTitle,
    required this.initialPrevious,
    required this.initialPeriod,
  });

  @override
  State<_ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<_ReminderFormScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);

  late final TextEditingController _titleController;
  late final TextEditingController _previousController;
  late final TextEditingController _periodController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _previousController =
        TextEditingController(text: widget.initialPrevious.toString());
    _periodController =
        TextEditingController(text: widget.initialPeriod.toString());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _previousController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
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
    final String title = _titleController.text.trim();
    final double? previous = double.tryParse(_previousController.text.trim());
    final double? period = double.tryParse(_periodController.text.trim());

    if (title.isEmpty || previous == null || period == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    Navigator.pop(
      context,
      _ReminderItem(
        title: title,
        type: 'odometer',
        period: period,
        previousValue: previous,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
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
          widget.appBarTitle,
          style: const TextStyle(
            color: Colors.black,
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
                  controller: _titleController,
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  decoration: _fieldDecoration(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _previousController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
                  decoration: _fieldDecoration(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _periodController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black87, fontSize: 15),
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
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    widget.buttonLabel,
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
