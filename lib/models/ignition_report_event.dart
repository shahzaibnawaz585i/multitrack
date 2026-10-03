class IgnitionReportEvent {
  const IgnitionReportEvent({
    required this.vehicleName,
    required this.timeLabel,
    required this.statusLabel,
    required this.isOn,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.dateTime,
  });

  final String vehicleName;
  final String timeLabel;
  final String statusLabel;
  final bool isOn;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime? dateTime;
}
