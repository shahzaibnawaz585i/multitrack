class TripReportEvent {
  const TripReportEvent({
    required this.vehicleName,
    required this.durationLabel,
    required this.distanceLabel,
    required this.startTimeLabel,
    required this.endTimeLabel,
    required this.startLocation,
    required this.endLocation,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    this.deviceId,
    this.startDateTime,
    this.endDateTime,
  });

  final String vehicleName;
  final String durationLabel;
  final String distanceLabel;
  final String startTimeLabel;
  final String endTimeLabel;
  final String startLocation;
  final String endLocation;
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;
  final int? deviceId;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
}
