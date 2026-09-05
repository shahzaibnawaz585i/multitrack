/// GPSWOX report type IDs used with `/api/generate_report`.
class ReportIds {
  ReportIds._();

  static const int ignition = 1;
  static const int trip = 2;
  static const int daily = 3;
  static const int speed = 4;
  static const int summary = 5;
  static const int ac = 6;
  static const int stoppage = 7;
  static const int geofence = 8;
}
