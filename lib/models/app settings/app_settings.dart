import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 4) // Assuming 4 is the next available HiveTypeId
class AppSettings extends HiveObject {
  // Timestamp of the latest SMS successfully parsed and recorded.
  @HiveField(0)
  final int? lastMpesaSmsTimestamp;

  // We can use this to track when the full initial scan was completed.
  @HiveField(1)
  final bool initialScanComplete;

  // Track when the user first installed/started using the app
  // This is used for progressive period filtering (walking the journey)
  @HiveField(2)
  final DateTime? appInstallDate;

  // Track completed weeks (every Sunday marks a completed week)
  // Format: "YYYY-WW" where WW is week number (1-52/53)
  @HiveField(3)
  final List<String> completedWeeks;

  // Track completed months (last day of each month marks a completed month)
  // Format: "YYYY-MM" (e.g., "2024-11")
  @HiveField(4)
  final List<String> completedMonths;

  AppSettings({
    this.lastMpesaSmsTimestamp,
    this.initialScanComplete = false,
    this.appInstallDate,
    this.completedWeeks = const [],
    this.completedMonths = const [],
  });

  AppSettings copyWith({
    int? lastMpesaSmsTimestamp,
    bool? initialScanComplete,
    DateTime? appInstallDate,
    List<String>? completedWeeks,
    List<String>? completedMonths,
  }) {
    return AppSettings(
      lastMpesaSmsTimestamp: lastMpesaSmsTimestamp ?? this.lastMpesaSmsTimestamp,
      initialScanComplete: initialScanComplete ?? this.initialScanComplete,
      appInstallDate: appInstallDate ?? this.appInstallDate,
      completedWeeks: completedWeeks ?? this.completedWeeks,
      completedMonths: completedMonths ?? this.completedMonths,
    );
  }
}