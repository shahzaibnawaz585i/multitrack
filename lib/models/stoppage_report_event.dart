class StoppageReportEvent {
  const StoppageReportEvent({
    required this.vehicleName,
    required this.startTimeLabel,
    required this.endTimeLabel,
    required this.durationLabel,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.dateTime,
  });

  final String vehicleName;
  final String startTimeLabel;
  final String endTimeLabel;
  final String durationLabel;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime? dateTime;
}
