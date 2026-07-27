import 'package:flutter/material.dart';

import '../../constants/app_theme.dart';
import 'raise_ticket_screen.dart';

class LiveSupportScreen extends StatefulWidget {
  const LiveSupportScreen({super.key});

  @override
  State<LiveSupportScreen> createState() => _LiveSupportScreenState();
}

class _LiveSupportScreenState extends State<LiveSupportScreen> {
  static const Color _pinkColor = AppThemeContext.pinkColor;

  int _selectedTabIndex = 2;

  late DateTime _fromDate;
  late DateTime _endDate;

  final List<String> _tabLabels = const [
    'All',
    'Open',
    'In Progress',
    'Closed',
  ];

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _fromDate = DateTime(now.year, now.month, now.day);
    _endDate = DateTime(now.year, now.month, now.day, 23, 59);
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

  Future<void> _pickDateTime(bool isFromDate) async {
    final DateTime initial = isFromDate ? _fromDate : _endDate;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null || !mounted) {
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );

    if (pickedTime == null || !mounted) {
      return;
    }

    setState(() {
      final DateTime combined = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (isFromDate) {
        _fromDate = combined;
      } else {
        _endDate = combined;
      }
    });
  }

  void _showSupportHelpDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: context.appSurface,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Support & Helps',
                  style: TextStyle(
                    color: context.appTextColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: context.appBorder, height: 1),
                const SizedBox(height: 8),
                _SupportHelpRow(
                  label: 'Phone()',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.phone, color: _pinkColor, size: 22),
                      const SizedBox(width: 10),
                      Icon(Icons.chat, color: Colors.green.shade600, size: 22),
                    ],
                  ),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening WhatsApp call...')),
                    );
                  },
                ),
                const SizedBox(height: 6),
                _SupportHelpRow(
                  label: 'Email()',
                  trailing: Icon(Icons.email_outlined, color: _pinkColor, size: 22),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening email...')),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appSurface,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.appBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _DateField(
                            label: 'From Date',
                            value: _formatDateTime(_fromDate),
                            onTap: () => _pickDateTime(true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DateField(
                            label: 'End Date',
                            value: _formatDateTime(_endDate),
                            onTap: () => _pickDateTime(false),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildTabBar(),
                Expanded(
                  child: Center(
                    child: Text(
                      'No tickets found',
                      style: TextStyle(
                        color: context.appSecondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 16,
              bottom: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Material(
                    color: context.appSurface,
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _showSupportHelpDialog,
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: 54,
                        height: 54,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/live_support.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.support_agent,
                                color: _pinkColor,
                                size: 28,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: _pinkColor,
                    elevation: 4,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (context) => const RaiseTicketScreen(),
                          ),
                        );
                      },
                      customBorder: const CircleBorder(),
                      child: const SizedBox(
                        width: 58,
                        height: 58,
                        child: Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 32,
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
            'Support Tickets',
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: context.appFieldFill,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          for (int i = 0; i < _tabLabels.length; i++) ...[
            Expanded(
              child: _StatusTab(
                label: '${_tabLabels[i]} (0)',
                isSelected: _selectedTabIndex == i,
                onTap: () {
                  setState(() {
                    _selectedTabIndex = i;
                  });
                },
              ),
            ),
            if (i != _tabLabels.length - 1)
              Container(
                width: 1,
                height: 36,
                color: context.appBorder,
              ),
          ],
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.appTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: context.appBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: AppThemeContext.pinkColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: context.appTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? AppThemeContext.pinkColor
                  : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected
                ? AppThemeContext.pinkColor
                : context.appTextColor,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SupportHelpRow extends StatelessWidget {
  final String label;
  final Widget trailing;
  final VoidCallback onTap;

  const _SupportHelpRow({
    required this.label,
    required this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: context.appTextColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
