import 'package:flutter/material.dart';

import '../../l10n/app_l10n.dart';
import '../../theme/app_theme_tokens.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);
  static const Color _greenColor = Color(0xFF4CAF50);
  static const Color _greenHalo = Color(0xFFB9E4BA);

  bool _isLoading = false;
  final List<_GroupItem> _groups = <_GroupItem>[
    const _GroupItem(name: 'halku transport', groupId: 0),
    const _GroupItem(name: 'Vikash grup', groupId: 0),
  ];

  Future<void> _openAddGroup() async {
    final String? name = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => const _GroupFormScreen(
          title: 'Add new group',
          buttonLabel: 'Add new group',
        ),
      ),
    );

    if (name == null || name.trim().isEmpty || !mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _groups.insert(0, _GroupItem(name: name.trim(), groupId: 0));
    });
  }

  Future<void> _openUpdateGroup(_GroupItem item) async {
    final int index = _groups.indexOf(item);
    final String? name = await Navigator.push<String>(
      context,
      MaterialPageRoute<String>(
        builder: (_) => _GroupFormScreen(
          title: 'Update group',
          buttonLabel: 'Update group',
          initialName: item.name,
        ),
      ),
    );

    if (name == null || name.trim().isEmpty || !mounted || index < 0) {
      return;
    }

    setState(() {
      _groups[index] = _GroupItem(name: name.trim(), groupId: item.groupId);
    });
  }

  Future<void> _confirmDelete(_GroupItem item) async {
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
                  'You want to delete this group?',
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
        _groups.remove(item);
      });
    }
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
          context.tr('Groups'),
          style: TextStyle(
            color: context.textColor,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddGroup,
        backgroundColor: _pinkColor,
        elevation: 4,
        child: Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: _isLoading
          ? const Center(child: _LoadingDots())
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 90),
              itemCount: _groups.length,
              separatorBuilder: (_, __) => const SizedBox(height: 18),
              itemBuilder: (BuildContext context, int index) {
                final _GroupItem item = _groups[index];
                return Row(
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
                          Icons.person_outline,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Group Id : ${item.groupId}',
                            style: TextStyle(
                              color: context.mutedTextColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openUpdateGroup(item),
                      icon: Icon(
                        Icons.edit_square,
                        color: _greenColor,
                        size: 24,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _confirmDelete(item),
                      icon: Icon(
                        Icons.delete_outline,
                        color: _pinkColor,
                        size: 26,
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _GroupItem {
  final String name;
  final int groupId;

  const _GroupItem({
    required this.name,
    required this.groupId,
  });
}

class _GroupFormScreen extends StatefulWidget {
  final String title;
  final String buttonLabel;
  final String? initialName;

  const _GroupFormScreen({
    required this.title,
    required this.buttonLabel,
    this.initialName,
  });

  @override
  State<_GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends State<_GroupFormScreen> {
  static const Color _pinkColor = Color(0xFFFF2F68);

  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please enter group name'))),
      );
      return;
    }
    Navigator.pop(context, name);
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
          context.tr(widget.title),
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
            child: TextField(
              controller: _nameController,
              style: TextStyle(
                color: context.textColor,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'Name',
                hintStyle: TextStyle(
                  color: context.labelTextColor,
                  fontSize: 15,
                ),
                filled: true,
                fillColor: context.fieldFillColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
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
                    widget.buttonLabel,
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
