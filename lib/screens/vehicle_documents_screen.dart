import 'package:flutter/material.dart';

import '../l10n/app_l10n.dart';
import '../models/vehicle_document_model.dart';
import '../services/vehicle_document_service.dart';
import 'upload_vehicle_document_screen.dart';

class VehicleDocumentsScreen extends StatefulWidget {
  const VehicleDocumentsScreen({
    super.key,
    required this.deviceId,
    required this.vehicleName,
  });

  final int deviceId;
  final String vehicleName;

  @override
  State<VehicleDocumentsScreen> createState() => _VehicleDocumentsScreenState();
}

class _VehicleDocumentsScreenState extends State<VehicleDocumentsScreen> {
  static const Color _pink = Color(0xFFFF2F68);
  static const Color _cardBg = Color(0xFFFFF0F3);

  bool _loading = true;
  List<VehicleDocumentModel> _documents = <VehicleDocumentModel>[];
  final Set<String> _selectedIds = <String>{};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final List<VehicleDocumentModel> docs =
        await VehicleDocumentService.fetchDocuments(widget.deviceId);
    if (!mounted) {
      return;
    }
    setState(() {
      _documents = docs;
      _loading = false;
      _selectedIds.removeWhere(
        (String id) => !_documents.any((VehicleDocumentModel d) => d.id == id),
      );
    });
  }

  Future<void> _openUpload({VehicleDocumentModel? existing}) async {
    final bool? saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => UploadVehicleDocumentScreen(
          deviceId: widget.deviceId,
          existing: existing,
        ),
      ),
    );
    if (saved != null) {
      await _load();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? context.tr('Document saved successfully')
                : context.tr(
                    'Document saved on this device (server docs API unavailable).',
                  ),
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _delete(VehicleDocumentModel doc) async {
    await VehicleDocumentService.deleteDocument(
      deviceId: widget.deviceId,
      documentId: doc.id,
    );
    await _load();
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: _pink, size: 20),
        ),
        title: Text(
          context.tr('Documents'),
          style: const TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: PopupMenuButton<String>(
              onSelected: (String value) {
                setState(() {
                  if (value == 'select_all') {
                    _selectionMode = true;
                    _selectedIds
                      ..clear()
                      ..addAll(_documents.map((VehicleDocumentModel d) => d.id));
                  } else if (value == 'unselect_all') {
                    _selectedIds.clear();
                  }
                });
              },
              offset: const Offset(0, 40),
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'select_all',
                    child: Text(context.tr('Select All')),
                  ),
                  PopupMenuItem<String>(
                    value: 'unselect_all',
                    child: Text(context.tr('Unselect All')),
                  ),
                ];
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _pink,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      context.tr('Select'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.arrow_drop_down, color: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _pink))
                : _documents.isEmpty
                    ? Center(
                        child: Text(
                          context.tr('No documents yet'),
                          style: const TextStyle(color: Color(0xFF6B7280)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                        itemCount: _documents.length,
                        itemBuilder: (BuildContext context, int index) {
                          final VehicleDocumentModel doc = _documents[index];
                          final bool selected = _selectedIds.contains(doc.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DocumentCard(
                              document: doc,
                              selected: selected,
                              onToggleSelect: () => _toggleSelect(doc.id),
                              onEdit: () => _openUpload(existing: doc),
                              onDelete: () => _delete(doc),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openUpload(),
        backgroundColor: _pink,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    required this.selected,
    required this.onToggleSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final VehicleDocumentModel document;
  final bool selected;
  final VoidCallback onToggleSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  static const Color _pink = Color(0xFFFF2F68);
  static const Color _cardBg = Color(0xFFFFF0F3);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _cardBg,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            InkWell(
              onTap: onToggleSelect,
              child: Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _pink, width: 2),
                  color: selected ? _pink : Colors.transparent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF9CA3AF)),
                color: Colors.white,
              ),
              child: const Icon(Icons.description_outlined, color: Color(0xFF6B7280)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    document.documentType.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _pink),
                    ),
                    child: Text(
                      document.documentId,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  document.expiryLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  context.tr('Doc. Expiry Date'),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    IconButton(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
