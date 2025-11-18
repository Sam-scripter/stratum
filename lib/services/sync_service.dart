import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart'; // Add this package
import '../models/account/account_model.dart';
import '../models/account/account_snapshot.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId; // You get this from your Auth Service

  SyncService(this.userId);

  // Collection References
  CollectionReference get _accountsRef =>
      _firestore.collection('users').doc(userId).collection('accounts');

  // 1. Main Sync Function (Call this on App Startup & on Refresh)
  Future<void> syncAccounts() async {
    // Check internet first
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) return;

    final box = Hive.box<Account>('accounts');

    // A. PULL: Get Cloud Data
    final snapshot = await _accountsRef.get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final cloudLastUpdated = (data['lastUpdated'] as Timestamp).toDate();
      final accountId = doc.id;

      // Check if we have this account locally
      if (box.containsKey(accountId)) {
        final localAccount = box.get(accountId)!;

        // CONFLICT RESOLUTION: Cloud is newer? Overwrite Local.
        if (cloudLastUpdated.isAfter(localAccount.lastUpdated)) {
          localAccount.currentBalance = (data['currentBalance'] as num).toDouble();
          localAccount.lastUpdated = cloudLastUpdated;
          localAccount.name = data['name'];
          await localAccount.save();
        }
        // Local is newer? Push to Cloud.
        else if (localAccount.lastUpdated.isAfter(cloudLastUpdated)) {
          await pushAccountToCloud(localAccount);
        }
      } else {
        // Account exists in cloud but not locally (New Device scenario)
        // Create local account
        final newAccount = Account(
          id: accountId,
          name: data['name'],
          currentBalance: (data['currentBalance'] as num).toDouble(),
          type: AccountType.values[data['typeIndex']], // Store enum index in FB
          lastUpdated: cloudLastUpdated,
          isAutomated: data['isAutomated'] ?? false,
        );
        await box.put(accountId, newAccount);
      }
    }

    // B. PUSH: Check for local accounts that don't exist in cloud yet
    for (var localAccount in box.values) {
      final doc = await _accountsRef.doc(localAccount.id).get();
      if (!doc.exists) {
        await pushAccountToCloud(localAccount);
      }
    }
  }

  // 2. Push Single Account (Call this immediately after _updateAccountBalance)
  Future<void> pushAccountToCloud(Account account) async {
    await _accountsRef.doc(account.id).set({
      'name': account.name,
      'currentBalance': account.currentBalance,
      'typeIndex': account.type.index, // Simple way to store Enum
      'isAutomated': account.isAutomated,
      'lastUpdated': Timestamp.fromDate(account.lastUpdated),
    });

    // Also save a Snapshot for History (Infinity Tracking)
    await _saveHistorySnapshot(account);
  }

  Future<void> _saveHistorySnapshot(Account account) async {
    // Save to Firestore sub-collection for long-term analysis
    await _accountsRef.doc(account.id).collection('history').add({
      'balance': account.currentBalance,
      'timestamp': Timestamp.now(),
    });

    // Save to local Hive Snapshot box for charts
    final snapshotBox = await Hive.openBox<AccountSnapshot>('account_snapshots');
    snapshotBox.add(AccountSnapshot(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        accountId: account.id,
        balance: account.currentBalance,
        timestamp: DateTime.now()
    ));
  }
}