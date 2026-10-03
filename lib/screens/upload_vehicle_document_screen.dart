import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_l10n.dart';
import '../models/vehicle_document_model.dart';
import '../services/vehicle_document_service.dart';

class UploadVehicleDocumentScreen extends StatefulWidget {
  const UploadVehicleDocumentScreen({
    super.key,
    required this.deviceId,
    this.existing,
  });

  final int deviceId;
  final VehicleDocumentModel? existing;

  @override
  State<UploadVehicleDocumentScreen> createState() =>
      _UploadVehicleDocumentScreenState();
}

class _UploadVehicleDocumentScreenState
    extends State<UploadVehicleDocumentScreen> {
  static const Color _pink = Color(0xFFFF2F68);

  static const List<String> _documentTypes = <String>[
    'RC',
    'PERMIT',
    'FITMENT',
    'Insurance',
    'PUC',
    'Other',
  ];

  String? _documentType;
  final TextEditingController _docIdController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  DateTime? _expiryDate;
  File? _imageFile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final VehicleDocumentModel? e = widget.existing;
    if (e != null) {
      _documentType = e.documentType;
      _docIdController.text = e.documentId;
      _remarksController.text = e.remarks;
      _expiryDate = e.expiryDate;
      if (e.imagePath.isNotEmpty) {
        _imageFile = File(e.imagePath);
      }
    } else {
      _expiryDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _docIdController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: context.tr(label),
      labelStyle: const TextStyle(color: Color(0xFF374151)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF111827)),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) {
      return;
    }
    setState(() {
      _imageFile = File(file.path);
    });
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now.add(const Duration(days: 365 * 20)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _submit() async {
    final String type = (_documentType ?? '').trim();
    final String docId = _docIdController.text.trim();
    if (type.isEmpty || docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Please fill document details'))),
      );
      return;
    }

    setState(() => _saving = true);
    final String id =
        widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final VehicleDocumentModel model = VehicleDocumentModel(
      id: id,
      documentType: type,
      documentId: docId,
      expiryDate: _expiryDate,
      remarks: _remarksController.text.trim(),
      imagePath: _imageFile?.path ?? widget.existing?.imagePath ?? '',
    );

    try {
      final bool synced = await VehicleDocumentService.saveDocument(
        deviceId: widget.deviceId,
        document: model,
        imageFile: _imageFile,
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context, synced);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String dateLabel = _expiryDate == null
        ? '—'
        : _expiryDate!.toIso8601String().split('T').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: _pink, size: 20),
        ),
        title: Text(
          context.tr('Upload Document'),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              DropdownButtonFormField<String>(
                value: _documentType,
                decoration: _fieldDecoration('Document Type'),
                hint: Text(context.tr('Select Document Type')),
                items: _documentTypes
                    .map(
                      (String t) => DropdownMenuItem<String>(
                        value: t,
                        child: Text(context.tr(t)),
                      ),
                    )
                    .toList(),
                onChanged: (String? v) => setState(() => _documentType = v),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _docIdController,
                decoration: _fieldDecoration('Document ID'),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: _fieldDecoration('Document Expiry Date'),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.calendar_today, color: _pink, size: 18),
                      const SizedBox(width: 8),
                      Text(dateLabel),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: _fieldDecoration('Remarks'),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('Upload Image'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF111827)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(_imageFile!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(Icons.image_outlined,
                                color: _pink.withValues(alpha: 0.8), size: 40),
                            const SizedBox(height: 8),
                            Text(context.tr('Upload Image')),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _saving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      context.tr('Update'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
