class VehicleDocumentModel {
  const VehicleDocumentModel({
    required this.id,
    required this.documentType,
    required this.documentId,
    required this.expiryDate,
    this.remarks = '',
    this.imagePath = '',
    this.imageUrl = '',
  });

  final String id;
  final String documentType;
  final String documentId;
  final DateTime? expiryDate;
  final String remarks;
  final String imagePath;
  final String imageUrl;

  String get expiryLabel {
    if (expiryDate == null) {
      return '—';
    }
    const List<String> months = <String>[
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
    final DateTime d = expiryDate!;
    final String month = months[d.month - 1];
    return '${d.day.toString().padLeft(2, '0')} $month ${d.year}';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'documentType': documentType,
      'documentId': documentId,
      'expiryDate': expiryDate?.toIso8601String(),
      'remarks': remarks,
      'imagePath': imagePath,
      'imageUrl': imageUrl,
    };
  }

  factory VehicleDocumentModel.fromJson(Map<String, dynamic> json) {
    DateTime? expiry;
    final dynamic rawDate =
        json['expiryDate'] ?? json['expiry_date'] ?? json['expires_at'];
    if (rawDate != null && rawDate.toString().isNotEmpty) {
      expiry = DateTime.tryParse(rawDate.toString());
    }

    final String rawId =
        (json['id'] ?? json['document_id'] ?? '').toString().trim();
    return VehicleDocumentModel(
      id: rawId.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : rawId,
      documentType: (json['documentType'] ??
              json['type'] ??
              json['name'] ??
              json['title'] ??
              'Document')
          .toString(),
      documentId: (json['documentId'] ??
              json['document_id'] ??
              json['doc_id'] ??
              json['number'] ??
              '')
          .toString(),
      expiryDate: expiry,
      remarks: (json['remarks'] ?? json['description'] ?? '').toString(),
      imagePath: (json['imagePath'] ?? '').toString(),
      imageUrl: (json['imageUrl'] ?? json['image'] ?? json['file'] ?? '')
          .toString(),
    );
  }

  VehicleDocumentModel copyWith({
    String? documentType,
    String? documentId,
    DateTime? expiryDate,
    String? remarks,
    String? imagePath,
    String? imageUrl,
  }) {
    return VehicleDocumentModel(
      id: id,
      documentType: documentType ?? this.documentType,
      documentId: documentId ?? this.documentId,
      expiryDate: expiryDate ?? this.expiryDate,
      remarks: remarks ?? this.remarks,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
