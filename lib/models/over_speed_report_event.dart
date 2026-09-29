class OverSpeedReportEvent {
  const OverSpeedReportEvent({
    required this.vehicleName,
    required this.timeLabel,
    required this.speedLabel,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.dateTime,
    this.speedKmph = 0,
  });

  final String vehicleName;
  final String timeLabel;
  final String speedLabel;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime? dateTime;
  final double speedKmph;
}
