import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stratum/services/sync_service.dart';
import '../models/account/account_model.dart';

class SmsParserService {
  static const String _boxName = 'accounts';

  // Inject SyncService
  final SyncService _syncService = SyncService("CURRENT_USER_ID");

  // Main entry point
  Future<void> parseAndSyncMessages() async {
    final SmsQuery query = SmsQuery();
    // Fetch generic messages (optimization: filter by specific sender IDs if possible)
    List<SmsMessage> messages = await query.querySms(kinds: [SmsQueryKind.inbox]);

    // Ensure box is open before processing
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<Account>(_boxName);
    }

    for (var msg in messages) {
      String sender = msg.address ?? "";
      String body = msg.body ?? "";

      if (sender == "MPESA") {
        await _handleMpesaMessage(body);
      } else if (sender == "KCB") {
        await _handleKCBMessage(body);
      } else if (sender == "EquityBank") {
        await _handleEquityMessage(body);
      }
      // ... add others
    }
  }

  Future<void> _handleMpesaMessage(String body) async {
    // 1. Check for M-Shwari (It usually comes from MPESA sender ID too)
    if (body.contains("M-Shwari")) {
      // Parse M-Shwari Balance -> Update 'M-Shwari' Account
      double bal = _extractBalance(body, r'M-Shwari balance is Ksh([\d,.]+)');
      await _updateAccountBalance("mshwari_id", bal);
      return;
    }

    // 2. Check for Fuliza (Overdraft)
    if (body.contains("Outstanding Fuliza")) {
      // Parse Debt -> Update 'Fuliza' Account (Liability)
      double debt = _extractBalance(body, r'Outstanding Fuliza.*?Ksh([\d,.]+)');
      await _updateAccountBalance("fuliza_id", debt); // Store as positive liability

      // Usually if you have fuliza outstanding, M-Pesa balance is 0
      await _updateAccountBalance("mpesa_id", 0.0);
      return;
    }

    // 3. Standard M-Pesa
    if (body.contains("New M-PESA balance")) {
      double bal = _extractBalance(body, r'New M-PESA balance is Ksh([\d,.]+)');
      await _updateAccountBalance("mpesa_id", bal);
    }
  }

  Future<void> _handleKCBMessage(String body) async {
    // Regex for KCB often looks like: "Available Balance KES 12,000.00"
    if (body.contains("Available Balance")) {
      double bal = _extractBalance(body, r'Available Balance.*?KES\s?([\d,.]+)');
      await _updateAccountBalance("kcb_id", bal);
    }
  }

  Future<void> _handleEquityMessage(String body) async {
    // Placeholder for Equity logic
  }

  // Helper to extract double from regex
  double _extractBalance(String body, String pattern) {
    final reg = RegExp(pattern, caseSensitive: false);
    final match = reg.firstMatch(body);
    if (match != null) {
      return double.tryParse(match.group(1)!.replaceAll(',', '')) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _updateAccountBalance(String accountId, double newBalance) async {
    try {
      final box = Hive.box<Account>(_boxName);

      // Find the account where the 'id' field matches our internal ID (e.g., "mpesa_id")
      // Using 'firstWhere' effectively searches the local DB
      final account = box.values.firstWhere(
            (acc) => acc.id == accountId,
        orElse: () => throw Exception("Account not found"),
      );

      // Update fields
      account.currentBalance = newBalance;
      account.lastUpdated = DateTime.now();
      account.isAutomated = true; // Flag this as an auto-update

      // Persist changes to Hive
      await account.save();

      // NEW: Trigger Sync
      // We don't await this so the UI doesn't freeze.
      // It runs in background.
      _syncService.pushAccountToCloud(account);

      print("Updated $accountId to KES $newBalance");

    } catch (e) {
      // Handle case where account doesn't exist yet (e.g., prompt user to create it)
      print("Error updating account $accountId: $e");
    }
  }
}