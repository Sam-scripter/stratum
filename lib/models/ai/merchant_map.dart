import 'package:hive/hive.dart';

part 'merchant_map.g.dart';

@HiveType(typeId: 20)
class MerchantMap {
  @HiveField(0)
  final String rawName;

  @HiveField(1)
  final String cleanName;

  @HiveField(2)
  final String category;

  MerchantMap({
    required this.rawName,
    required this.cleanName,
    required this.category,
  });
}
