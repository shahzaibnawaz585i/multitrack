class ExpenseModel {
  final String description;
  final String deviceName;
  final String odometer;
  final double quantity;
  final double amount;
  final String paymentMode;
  final String date;
  final String category;

  const ExpenseModel({
    required this.description,
    required this.deviceName,
    required this.odometer,
    required this.quantity,
    required this.amount,
    required this.paymentMode,
    required this.date,
    required this.category,
  });

}
