# PRIVACY_NOTES.md — GDPR, Data Minimisation & Storage Architecture

This document provides the complete privacy, GDPR data-protection, minor-safety, and storage inventory for **M Mobilnost 2.0** (Marprom Maribor public transit and ticketing prototype).

---

## 1. Core Privacy Principles (GDPR by Design & by Default)

1. **Strict Data Minimisation (Art. 5(1)(c) GDPR)**: The application collects only the minimum fields required to plan Maribor bus trips, display departures, and issue/validate digital bus tickets.
2. **Zero Ad-Tech, Zero Third-Party Trackers**: There are no advertising SDKs, cross-app identifiers, fingerprinting scripts, or behavioural profiling libraries.
3. **Guest-First Access**: Timetables, live/simulated bus tracking, stop maps, route planning, nearest-stop search, the 5-step rider guide, and ticket catalogue browsing require **no account**. An account is optional and requested only when purchasing and storing tickets.
4. **Privacy by Default (Art. 25 GDPR)**: Optional anonymous usage statistics (`analyticsConsent`) and arrival/delay notifications (`notificationsConsent`) default to **off (`false`)** on first launch.
5. **Full Offline & Manual Location Fallback**: Riders can disable GPS entirely (`locationManualMode = true`) and select any Maribor stop (defaulting to `glavni_trg`) with full app functionality.

---

## 2. Complete GDPR Data Inventory

| Data Category | Exact Fields | Purpose & Legal Basis | Local Storage (Current Prototype) | Production Target (Firebase / PSP) |
| :--- | :--- | :--- | :--- | :--- |
| **Accessibility & UI Preferences** | `themeMode`, `localeCode`, `extraLargeText`, `reducedMotion`, `readAloudEnabled`, `voiceInputEnabled`, `hapticAlertsEnabled`, `soundAlertsOptional`, `showDataSource`, `useSimulatedLive`, `simulationSeed`, `usabilityTestMode`, `onboardingDone` | Remembers the rider's language (`sl`, `en`, `de`, `sr_Latn`) and accessibility configuration across launches. *(Legitimate interest / user-requested service)* | `SharedPreferences` (`a11y_*` keys on device only) | Device-local `SharedPreferences` (never uploaded to server unless user opts into cloud profile sync) |
| **GDPR Consent Flags** | `analyticsConsent`, `notificationsConsent`, `locationManualMode` | Records explicit opt-in/opt-out choices made during Onboarding or in Settings. *(Art. 6(1)(a) Consent)* | `SharedPreferences` (`a11y_analytics_consent`, `a11y_notifications_consent`, `a11y_location_manual`) | Device-local `SharedPreferences` + audit timestamp in `Cloud Firestore` (`users/{uid}/consents`) when authenticated |
| **Favourites & Manual Stop** | `stopIds` (`Set<String>`), `lineIds` (`Set<String>`), `manualStopId` (`String?`) | Quick access to the rider's regular Maribor stops/lines and GPS-free starting stop. *(User-requested functionality)* | `SharedPreferences` (`fav_stop_ids`, `fav_line_ids`, `fav_manual_stop_id`) | Device-local `SharedPreferences` (optional sync to `Cloud Firestore` `users/{uid}/preferences`) |
| **User Account Profile** | `id`, `email`, `name`, `dateOfBirth`, `preferredLocaleCode`, `guardianConfirmed`, `createdAt` | Authenticates ticket purchases, verifies youth/student (`<26`) or senior (`65+`) concession eligibility, and enforces minor guardian rules. *(Art. 6(1)(b) Contract performance)* | `SharedPreferences` (`mock_auth_users_v1`, `mock_auth_current_user_id`) | `FirebaseAuth` (identity/email) + `Cloud Firestore` (`users/{uid}` document with strict security rules) |
| **Purchased Tickets** | `id`, `typeId`, `userId`, `purchasedAt`, `validFrom`, `validUntil`, `qrPayload`, `driverFallbackCode`, `priceEur`, `zone` | Offline-capable proof of fare payment for QR/driver inspection and NFC boarding. *(Art. 6(1)(b) Contract & statutory accounting)* | `Hive` box `tickets_box_v1` (with in-memory fallback via `LocalKeyValueStore`) | `Cloud Firestore` (`users/{uid}/tickets/{ticketId}`) + signed cryptographic QR payload issued by `Cloud Functions`, cached locally in `Hive` for offline inspection |
| **Tokenized Payment Methods** | `id`, `type`, `brand`, `last4Digits`, `label`, `isDefault`, `fakeToken` | Allows convenient repeat checkout without re-entering payment details. *(Art. 6(1)(b) Contract / Art. 6(1)(a) Consent to save card)* | In-memory / mock repository (`MockPaymentRepository`) | PCI-DSS Level 1 Payment Service Provider (PSP) vault; `Cloud Firestore` stores **only** `brand`, `last4Digits`, and opaque PSP token |
| **Cached Timetables & Notices** | Stop departure snapshots (`timetable_cache_v1`), read notice IDs (`notices_box_v1`) | Enables offline timetable viewing and tracks dismissed service alerts. | `Hive` boxes (`timetable_cache_v1`, `notices_box_v1`) | Public GTFS/Firestore cache on device (`Hive`) |
| **Device Location (GPS)** | Ephemeral `LatLng(latitude, longitude)` while app is open | Computes walking distance to nearby Maribor bus stops. **Never persisted to disk and never transmitted off device in mock mode.** | Ephemeral RAM only | Ephemeral RAM only (queries against locally cached stop coordinates) |
| **Usability Evaluation Logs** | `scenarioId`, `durationSeconds`, `tapCount`, `errorCount`, `startedAtUtc`, `completedAtUtc` | Academic/UX usability benchmark export (CSV/JSON) when Usability Test Mode is explicitly enabled. **Contains zero PII (`containsPersonalData: false`).** | Ephemeral RAM + user-initiated clipboard/file export | Ephemeral local evaluator export only |

---

## 3. Protection of Minors (`< 16` and `< 18` Safeguards)

Under **GDPR Article 8** (and Slovenian ZVOP-2 implementation) as well as consumer contract rules for digital purchases:

- **Age Calculation (`UserProfile`)**:
  - `isUnder16(DateTime now)`: `ageAt(now) < 16`
  - `isUnder18(DateTime now)`: `ageAt(now) < 18`
- **Account Registration (`AccountScreen`)**:
  - When a user enters a date of birth indicating they are **under 16** (`isUnder16`) or **between 16 and 18** (`isUnder18`), the form displays a clear localized notice (`ticketsMinorUnder16Warning` / `ticketsMinorUnder18Notice`) and requires the **Parent or legal guardian confirmation** checkbox (`ticketsMinorGuardianConfirm`) before account creation or profile update can proceed.
- **Ticket Checkout (`TicketCheckoutScreen`)**:
  - When a signed-in rider is under 18 (`user.isUnder18`), Step 1 of checkout requires explicit parent/guardian confirmation (`guardianConfirmed`) before advancing to payment selection.

---

## 4. Payment Card Safety (Zero PAN / Zero CVV Storage)

- **Never Stored**: Full Primary Account Numbers (PAN), expiration dates, and CVV/CVC security codes are **never stored** in `SharedPreferences`, `Hive`, logs, or memory models.
- **Last-4 Enforcement (`PaymentMethod` & `MockPaymentRepository.addCardMethod`)**:
  - The add-card UI (`PaymentMethodsScreen`) accepts **only** the card brand (e.g. `Visa`) and the **last 4 digits** (`RegExp(r'^\d{4}$')`).
  - Even if a longer string is passed programmatically to `MockPaymentRepository.addCardMethod`, the repository strips non-digits, extracts only the final 4 digits, and generates a synthetic opaque token (`tok_demo_<timestamp>_<last4>`).

---

## 5. Right to Erasure ("Delete My Account and Data") & Cache Clearing

M Mobilnost 2.0 provides two immediate self-service erasure controls:

1. **Delete Account & All Local Data (`AccountScreen` -> `accountDeleteAccount`)**:
   - Invokes `authRepositoryProvider.deleteAccount(userId)` (wired in `lib/data/repositories/repository_providers.dart`).
   - Permanently deletes:
     - The user's profile and active session from `MockAuthRepository` (`SharedPreferences`).
     - All saved/purchased tickets (`ticketRepository.clearAllTickets()` -> wipes `Hive` box `tickets_box_v1`).
     - All cached timetables (`timetableRepository.clearCache()` -> wipes `Hive` box `timetable_cache_v1`).
     - All saved payment methods (`paymentRepository.clearAll()`).
     - All accessibility and app preferences (`a11ySettingsProvider.notifier.resetAll()`).
2. **Clear Local Cached Data (`SettingsScreen` -> `settingsClearLocalData`)**:
   - Allows any guest or signed-in user to wipe cached timetables, tickets, and favourite stops/lines without needing an account.
