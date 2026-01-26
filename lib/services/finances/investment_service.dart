import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/box_manager.dart';
import '../../models/investment/investment_model.dart';

class InvestmentService {
  final String userId;
  late final BoxManager _boxManager;

  InvestmentService(this.userId) {
    _boxManager = BoxManager();
  }

  Future<void> _ensureBoxOpen() async {
    await _boxManager.openAllBoxes(userId);
  }

  Box<InvestmentModel> get _box {
    return _boxManager.getBox<InvestmentModel>(BoxManager.investmentsBoxName, userId);
  }

  // --- CRUD ---

  Future<void> addInvestment({
    required String name,
    required InvestmentType type,
    required double principalAmount,
    required double currentValue,
    double quantity = 0.0,
    String notes = '',
  }) async {
    await _ensureBoxOpen();
    final id = const Uuid().v4();
    final investment = InvestmentModel(
      id: id,
      name: name,
      type: type,
      principalAmount: principalAmount,
      currentValue: currentValue,
      quantity: quantity,
      notes: notes,
      lastUpdated: DateTime.now(),
    );
    await _box.put(id, investment);
  }

  Future<void> updateInvestment(
    String id, {
    String? name,
    InvestmentType? type,
    double? principalAmount,
    double? currentValue,
    double? quantity,
    String? notes,
  }) async {
    await _ensureBoxOpen();
    final item = _box.get(id);
    if (item != null) {
      // Direct field update for HiveObject might not trigger notify if not saving?
      // Better to create new object or make fields mutable and save()
      // Since fields are final in my model? No, they are not final in generated adapter usually unless I made them final.
      // In my model definition I made them NOT final except id.
      
      if (name != null) item.name = name;
      if (type != null) item.type = type;
      if (principalAmount != null) item.principalAmount = principalAmount;
      if (currentValue != null) item.currentValue = currentValue;
      if (quantity != null) item.quantity = quantity;
      if (notes != null) item.notes = notes;
      item.lastUpdated = DateTime.now();
      
      await item.save();
    }
  }

  Future<void> deleteInvestment(String id) async {
    await _ensureBoxOpen();
    await _box.delete(id);
  }

  Future<List<InvestmentModel>> getAllInvestments() async {
    await _ensureBoxOpen();
    return _box.values.toList();
  }

  // --- CALCULATIONS ---

  Future<double> getTotalValue() async {
    await _ensureBoxOpen();
    return _box.values.fold<double>(0.0, (sum, item) => sum + item.currentValue);
  }

  Future<double> getTotalCost() async {
    await _ensureBoxOpen();
    return _box.values.fold<double>(0.0, (sum, item) => sum + item.principalAmount);
  }
}
