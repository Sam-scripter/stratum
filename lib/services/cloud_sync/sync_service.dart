import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../models/account/account_model.dart';
import '../../models/account/account_snapshot.dart';
import '../../models/box_manager.dart';

class SyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BoxManager _boxManager = BoxManager();
  final String userId;

  SyncService(this.userId);

  // Collection References
  CollectionReference get _accountsRef =>
      _firestore.collection('users').doc(userId).collection('accounts');

  // 1. Main Sync Function (Accounts)
  Future<void> syncAccounts() async {
    try {
      var connectivityResult = await (Connectivity().checkConnectivity());
      if (connectivityResult == ConnectivityResult.none) return;

      await _boxManager.openAllBoxes(userId);
      final accountsBox = _boxManager.getBox<Account>(BoxManager.accountsBoxName, userId);

      // A. PULL: Get Cloud Data
      final snapshot = await _accountsRef.get();

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final cloudLastUpdated = (data['lastUpdated'] as Timestamp).toDate();
        final accountId = doc.id;

        final localAccount = accountsBox.get(accountId);

        // Extract balance with fallback
        final cloudBalance = (data['balance'] ?? data['currentBalance'] ?? 0.0) as num;

        final cloudAccount = Account(
          id: accountId,
          name: data['name'] as String,
          balance: cloudBalance.toDouble(),
          type: AccountType.values[data['typeIndex'] as int],
          lastUpdated: cloudLastUpdated,
          isAutomated: data['isAutomated'] ?? false,
          senderAddress: data['senderAddress'] ?? '',
        );

        if (localAccount != null) {
          // CONFLICT RESOLUTION
          if (cloudLastUpdated.isAfter(localAccount.lastUpdated)) {
            // Cloud is newer -> Overwrite Local
            await accountsBox.put(accountId, cloudAccount);
          } else if (localAccount.lastUpdated.isAfter(cloudLastUpdated)) {
            // Local is newer -> Push to Cloud
            await pushAccountToCloud(localAccount);
          }
        } else {
          // New account from cloud -> Save to Local
          await accountsBox.put(accountId, cloudAccount);
        }
      }

      // B. PUSH: Check for local accounts missing in cloud
      for (var localAccount in accountsBox.values) {
        final doc = await _accountsRef.doc(localAccount.id).get();
        if (!doc.exists) {
          await pushAccountToCloud(localAccount);
        }
      }
    } catch (e) {
      print("Error syncing accounts: $e");
    }
  }

  // 2. Push Single Account
  Future<void> pushAccountToCloud(Account account) async {
    try {
      await _accountsRef.doc(account.id).set({
        'name': account.name,
        'balance': account.balance,
        'typeIndex': account.type.index,
        'isAutomated': account.isAutomated,
        'lastUpdated': Timestamp.fromDate(account.lastUpdated),
        'senderAddress': account.senderAddress,
      });

      await _saveHistorySnapshot(account);
    } catch (e) {
      print("Error pushing account: $e");
    }
  }

  // 3. Save Snapshot History
  Future<void> _saveHistorySnapshot(Account account) async {
    try {
      final snapshotBox = _boxManager.getBox<AccountSnapshot>(BoxManager.accountSnapshotBoxName, userId);

      // Cloud Snapshot
      await _accountsRef.doc(account.id).collection('history').add({
        'balance': account.balance,
        'timestamp': Timestamp.now(),
      });

      // Local Snapshot
      await snapshotBox.add(AccountSnapshot(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          accountId: account.id,
          balance: account.balance,
          timestamp: DateTime.now()
      ));
    } catch (e) {
      print("Error saving snapshot: $e");
    }
  }
}