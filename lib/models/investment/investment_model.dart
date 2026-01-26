import 'package:hive/hive.dart';

part 'investment_model.g.dart';

@HiveType(typeId: 23)
enum InvestmentType {
  @HiveField(0)
  stock,
  @HiveField(1)
  mmf,
  @HiveField(2)
  crypto,
  @HiveField(3)
  bond,
  @HiveField(4)
  property,
  @HiveField(5)
  other,
}

@HiveType(typeId: 24)
class InvestmentModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  InvestmentType type;

  @HiveField(3)
  double principalAmount; // Cost basis

  @HiveField(4)
  double currentValue; // Market Value

  @HiveField(5)
  double quantity; // For shares/coins

  @HiveField(6)
  String notes;

  @HiveField(7)
  DateTime lastUpdated;

  InvestmentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.principalAmount,
    required this.currentValue,
    this.quantity = 0.0,
    this.notes = '',
    required this.lastUpdated,
  });

  // Helper getters
  double get profitOrLoss => currentValue - principalAmount;
  double get profitOrLossPercentage => principalAmount == 0 ? 0 : (profitOrLoss / principalAmount) * 100;
}
