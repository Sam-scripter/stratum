# Stratum App Flow Documentation

## Complete Application Flow from First Install

### 1. App Launch & Initialization
**File: `lib/main.dart`**
- App starts → `main()` function runs
- Initializes Firebase
- Initializes Hive (local database)
- Registers Hive adapters for models
- Initializes NotificationService
- Launches `SplashScreen`

### 2. Authentication Flow
**Files:**
- `lib/screens/splash/splash_screen.dart` - Checks if user is authenticated
- `lib/screens/auth/login_screen.dart` - Login UI
- `lib/services/auth_service.dart` - Handles Firebase authentication

**Flow:**
1. `SplashScreen` checks `AuthService.isSignedIn`
2. If **NOT signed in** → Navigate to `LoginScreen`
3. User enters email/password or uses Google Sign-In
4. `AuthService.loginWithEmail()` or `AuthService.signInWithGoogle()` called
5. Firebase authenticates user
6. On success → Navigate to `MainScreen` (which shows `HomeScreen`)

### 3. Permission Granting
**File: `lib/screens/home/home_screen.dart`**
- Method: `_initializeFinancials()` (line ~80)
- Uses: `permission_handler` package

**Flow:**
1. `HomeScreen.initState()` calls `_initializeFinancials()`
2. Checks SMS permission: `Permission.sms.status`
3. If not granted → Requests: `Permission.sms.request()`
4. Sets `_hasSmsPermission` state variable
5. If permission granted → Proceeds to SMS reading

### 4. SMS Reading
**File: `lib/services/sms_reader_service.dart`**
- Main service responsible for reading SMS
- Uses: `flutter_sms_inbox` package

**Flow:**
1. `HomeScreen._readSmsMessages()` is called (line ~161)
2. Checks if first launch (`AppSettings.lastMpesaSmsTimestamp == null`)
3. If first launch:
   - Shows `SmsReadingDialog` (progress dialog)
   - Calls `SmsReaderService.readAllSms()` which returns a Stream
4. `SmsReaderService.readAllSms()`:
   - Opens Hive boxes via `BoxManager.openAllBoxes(userId)`
   - Queries SMS using `SmsQuery.querySms()` (reads up to 10,000 messages)
   - Filters by financial senders: `{'MPESA', 'M-PESA', 'SAFARICOM', 'KCB', 'EQUITY', ...}`
   - For each financial SMS:
     - Calls `_parseSmsToTransaction()` to parse SMS
     - Creates `Transaction` object
   - Yields progress updates via `SmsReadProgress` stream
   - Calls `_saveTransactions()` to save all transactions

### 5. SMS Parsing
**File: `lib/services/sms_reader_service.dart`**
- Method: `_parseSmsToTransaction()` (line ~110)
- Uses financial_tracker's regex patterns

**Flow:**
1. Determines sender type (MPESA, KCB, EQUITY, etc.)
2. Gets or creates `Account` from Hive:
   - Tries to find by `senderAddress` first
   - If not found, tries by account type
   - If still not found, creates new `Account`
3. Checks for learned pattern via `PatternLearningService.getCategoryForPattern()`
4. Parses SMS using regex patterns:
   - **MPESA**: Uses patterns like `mpesaSentPattern`, `mpesaReceivedPattern`, etc.
   - **Banks**: Uses simpler patterns for debited/credited
5. Extracts:
   - Amount
   - Balance (`newBalance` field)
   - Reference code
   - Date/time
   - Recipient/sender
6. Creates `Transaction` object with:
   - `id`, `title`, `amount`, `type`, `category`, `date`, `accountId`
   - `originalSms`, `newBalance`, `reference`

### 6. Saving Transactions
**File: `lib/services/sms_reader_service.dart`**
- Method: `_saveTransactions()` (line ~200+)

**Flow:**
1. Opens Hive boxes: `BoxManager.openAllBoxes(userId)`
2. Gets `transactionsBox` and `accountsBox` from `BoxManager`
3. For each transaction:
   - Checks for duplicates (same date, amount, accountId)
   - If not duplicate → Saves to Hive: `transactionsBox.put(transaction.id, transaction)`
4. Updates account balances:
   - Finds most recent transaction per account
   - Updates account balance from `transaction.newBalance`
   - Saves updated account: `accountsBox.put(account.id, updatedAccount)`
5. Updates `AppSettings.lastMpesaSmsTimestamp` (high water mark)

### 7. Pattern Learning
**File: `lib/services/pattern_learning_service.dart`**
- Used when user updates transaction category

**Flow:**
1. User updates category in `TransactionDetailScreen`
2. `PatternLearningService.learnPattern()` generalizes SMS:
   - Replaces amounts with `KshAMOUNT`
   - Replaces phone numbers with `PHONE`
   - Replaces transaction codes with `TXNCODE`
   - Replaces dates/times with `DATE`/`TIME`
3. `PatternLearningService.savePattern()` saves pattern to Hive:
   - Stores in `MessagePattern` model
   - Links pattern to category and account type
4. Future SMS matching same pattern → Auto-categorized

---

## How Services Work with Models

### Models (Data Structures)
Located in `lib/models/`:
- **`Transaction`** - Stores transaction data (amount, date, category, etc.)
- **`Account`** - Stores account data (name, balance, type, senderAddress)
- **`AppSettings`** - Stores app settings (lastMpesaSmsTimestamp, etc.)
- **`MessagePattern`** - Stores learned SMS patterns for auto-categorization

### Services (Business Logic)
Located in `lib/services/`:

#### 1. **SmsReaderService** (Active)
- **Purpose**: Reads SMS and parses into transactions
- **Uses Models**: `Transaction`, `Account`, `AppSettings`
- **Interacts with**: `BoxManager` to save/load from Hive
- **Key Methods**:
  - `readAllSms()` - Reads SMS and returns progress stream
  - `_parseSmsToTransaction()` - Parses SMS to Transaction
  - `_saveTransactions()` - Saves transactions and updates balances

#### 2. **PatternLearningService** (Active)
- **Purpose**: Learns from user category updates
- **Uses Models**: `MessagePattern`, `Transaction`
- **Interacts with**: `BoxManager` to save patterns
- **Key Methods**:
  - `learnPattern()` - Generalizes SMS into pattern
  - `savePattern()` - Saves pattern to Hive
  - `getCategoryForPattern()` - Retrieves learned category

#### 3. **FinancialService** (Active)
- **Purpose**: Provides financial summaries and statistics
- **Uses Models**: `Transaction`
- **Interacts with**: `BoxManager` to read transactions
- **Key Methods**:
  - `getFinancialSummary()` - Calculates income/expense totals
  - `getRecentTransactions()` - Gets recent transactions
  - `getTopSpendingCategories()` - Gets spending by category

#### 4. **AuthService** (Active)
- **Purpose**: Handles Firebase authentication
- **Uses Models**: None (uses Firebase User directly)
- **Key Methods**:
  - `loginWithEmail()` - Email/password login
  - `signInWithGoogle()` - Google Sign-In
  - `signOut()` - Logout

#### 5. **SyncService** (Active)
- **Purpose**: Syncs data with Firebase Firestore
- **Uses Models**: `Account`, `Transaction`
- **Interacts with**: `BoxManager` and Firebase Firestore
- **Key Methods**:
  - `syncAccounts()` - Syncs accounts to/from cloud

#### 6. **NotificationService** (Active)
- **Purpose**: Shows local notifications for new transactions
- **Uses Models**: `Transaction`, `Account`
- **Key Methods**:
  - `showTransactionNotification()` - Shows notification

### BoxManager (Data Access Layer)
**File: `lib/models/box_manager.dart`**
- **Purpose**: Manages Hive database boxes (user-scoped)
- **Key Methods**:
  - `openAllBoxes(userId)` - Opens all Hive boxes for user
  - `getBox<T>(boxName, userId)` - Gets a Hive box
  - `registerAdapters()` - Registers Hive type adapters

**How it works:**
- Each user has their own Hive boxes (scoped by userId)
- Box names: `accounts_$userId`, `transactions_$userId`, etc.
- Services call `BoxManager.openAllBoxes()` before accessing data
- Services use `BoxManager.getBox<T>()` to get boxes for reading/writing

---

## Data Flow Diagram

```
User Opens App
    ↓
SplashScreen → Check Auth
    ↓
LoginScreen (if not authenticated)
    ↓
HomeScreen → Check SMS Permission
    ↓
Permission Granted? → Yes
    ↓
_readSmsMessages()
    ↓
SmsReaderService.readAllSms()
    ↓
Query SMS (flutter_sms_inbox)
    ↓
Filter Financial SMS
    ↓
For each SMS:
    ↓
_parseSmsToTransaction()
    ↓
Get/Create Account (from Hive)
    ↓
Check Learned Pattern
    ↓
Parse with Regex
    ↓
Create Transaction Object
    ↓
_saveTransactions()
    ↓
Save to Hive (transactionsBox.put())
    ↓
Update Account Balance (accountsBox.put())
    ↓
Update AppSettings (lastMpesaSmsTimestamp)
    ↓
UI Updates (HomeScreen shows accounts/transactions)
```

---

## Key Files Summary

### Active Files (Currently Used)
- ✅ `lib/services/sms_reader_service.dart` - Main SMS reading service
- ✅ `lib/services/pattern_learning_service.dart` - Pattern learning
- ✅ `lib/services/financial_service.dart` - Financial calculations
- ✅ `lib/services/auth_service.dart` - Authentication
- ✅ `lib/services/sync_service.dart` - Cloud sync
- ✅ `lib/services/notification_service.dart` - Notifications
- ✅ `lib/models/box_manager.dart` - Hive database manager
- ✅ `lib/screens/home/home_screen.dart` - Main screen with SMS reading

### Potentially Unused Files (Need Verification)
- ⚠️ `lib/services/native_sms_receiver.dart` - Not imported/used (Kotlin removed)
- ⚠️ `lib/services/background_sms_receiver.dart` - Imported in main.dart but not used
- ⚠️ `lib/services/sms_parser_service.dart` - May be replaced by sms_reader_service
- ⚠️ `lib/services/transaction_sync_service.dart` - Used in add_transaction_screen (verify if needed)

