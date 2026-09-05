class DriverModel {
  const DriverModel({
    this.id,
    required this.name,
    required this.phone,
    required this.uniqueId,
  });

  final int? id;
  final String name;
  final String phone;
  final String uniqueId;

  static DriverModel? fromJson(Map<String, dynamic> json) {
    final String name = (json['name'] ?? json['driver_name'] ?? json['title'] ?? '')
        .toString()
        .trim();
    if (name.isEmpty) {
      return null;
    }

    final String phone = (json['phone'] ??
            json['mobile'] ??
            json['phone_number'] ??
            json['tel'] ??
            '')
        .toString()
        .trim();

    final String uniqueId = (json['unique_id'] ??
            json['rfid'] ??
            json['identifier'] ??
            json['id_number'] ??
            phone)
        .toString()
        .trim();

    return DriverModel(
      id: _parseInt(json['id']),
      name: name,
      phone: phone,
      uniqueId: uniqueId,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }
}
