class DeviceGroupModel {
  const DeviceGroupModel({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  @override
  bool operator ==(Object other) {
    return other is DeviceGroupModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
