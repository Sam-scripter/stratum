# Stratum — Play Store deployment checklist

Use this before submitting to Play Console and for testers.

---

## 1. Code & config

- [ ] **API keys / secrets**  
  - Do not ship real keys in repo if public. Use `key.properties` (already gitignored for signing) and consider env or backend for Gemini/OpenRouter.  
  - `lib/core/secrets.dart`: ensure production keys are set (or loaded from env).

- [ ] **Signing**  
  - `android/app/build.gradle.kts` expects `android/key.properties` with:
    - `storeFile`, `storePassword`, `keyAlias`, `keyPassword`  
  - Create a release keystore if you haven’t:  
    `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`  
  - Add `key.properties` (and `.jks`) to `.gitignore` if not already.

- [ ] **Version**  
  - `pubspec.yaml`: `version: 1.0.0+9` — bump `versionCode` (+9) for each upload.

- [ ] **App ID**  
  - `applicationId = "com.shadivah.stratum"` is set; ensure it matches Play Console and is final.

---

## 2. Permissions & privacy

- [ ] **Sensitive permissions**  
  - **SMS** (READ_SMS, RECEIVE_SMS): Declare use in Play Console (Sensitive permissions / Special app access).  
  - **Notifications** (POST_NOTIFICATIONS): Declare if you request at runtime.  
  - **Foreground service** (DATA_SYNC): Declare “Data sync” in Console.  
  - **Battery / Wake lock**: Declare if you request “Ignore battery optimizations”.

- [ ] **Privacy policy**  
  - Required for SMS and any personal/financial data.  
  - Add URL in Play Console and in-app (e.g. Settings or signup).

- [ ] **Data safety form**  
  - Fill out “Data safety” in Play Console: what you collect (e.g. SMS for parsing), how it’s used, stored (local/cloud), and whether it’s shared.

---

## 3. Store listing

- [ ] **App name**  
  - `AndroidManifest.xml`: `android:label="stratum"` — consider “Stratum” or full product name.

- [ ] **Icons**  
  - Launcher icon set (e.g. `ic_launcher`) present; replace placeholders if any.

- [ ] **Screenshots**  
  - Phone (and optionally tablet) for Play Console.

- [ ] **Short & full description**  
  - Emphasize finance tracking, SMS-based detection, and that SMS is processed on-device if true.

- [ ] **Content rating**  
  - Complete questionnaire in Play Console (likely Everyone or similar if no mature content).

- [ ] **Target audience**  
  - Set age group and country/region.

---

## 4. Testing & quality

- [ ] **Release build**  
  - `flutter build appbundle --release` (or `flutter build apk --release` for testing).  
  - Install and test: login, SMS scan, notifications, navigation, Atlas (with and without network/API limits).

- [ ] **New transaction notification**  
  - Trigger a new transaction (SMS), confirm:  
    - In-app notification appears (Notifications screen).  
    - System notification appears (background).  
    - Tapping either opens **Transaction detail** screen where user can edit category and the app can learn.

- [ ] **Atlas / API errors**  
  - When API fails (quota, credits, etc.), user sees “Atlas is not available right now” (or similar) instead of raw errors.

- [ ] **Min SDK**  
  - Confirm `minSdk` in Flutter / `build.gradle.kts` is acceptable (e.g. 21+).

---

## 5. Optional but recommended

- [ ] **ProGuard / R8**  
  - Release already uses ProGuard. Test release build and confirm no crashes from obfuscation (e.g. Firebase/Hive/reflection).

- [ ] **Remove or guard debug**  
  - `print()` / `debugPrint` are fine for development; avoid logging sensitive data in production.

- [ ] **Internal test track**  
  - Upload first to “Internal testing”, then “Closed” (testers), then “Open” / Production.

- [ ] **App bundle**  
  - Prefer `appbundle` for Play Store (smaller downloads, no APK upload for new devices).

---

## 6. Quick commands

```bash
# Release app bundle (for Play Store)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
```

---

## Summary

- **Notification → Transaction detail**: Implemented. New transaction creates `NotificationModel` with `transactionId`; background shows system notification with `payload: transaction.id`. Tap (system or in-app) navigates to `TransactionDetailScreen`.
- **Token/credits errors**: OpenRouter requests capped with `max_tokens: 2048`; “Ask Atlas” uses one-shot call to reduce usage; quota/credits/afford errors show “Atlas is not available right now.”
- **Payment**: Not implemented; friendly error message is the feasible short-term approach.

After completing the checklist, upload the AAB to Play Console and fill in store listing, privacy, and permissions.
