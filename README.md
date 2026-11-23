# M Mobilnost 2.0 — Marprom Maribor Public Transit & Ticketing App

**M Mobilnost 2.0** is an accessible, multi-language, cross-platform (Mobile & Web) public transit and digital ticketing application for **Marprom** (Maribor, Slovenia). It unifies timetables, live/simulated bus tracking, multimodal route planning, and digital ticket purchasing into a single WCAG AA / AAA compliant experience.

---

## 1. Product Overview & How It Solves Real Rider Pain Points

Previous generations of Maribor transit apps split timetables/tracking and ticket purchasing across separate interfaces and suffered from recurring rider frustrations. M Mobilnost 2.0 directly addresses each pain point:

| Rider Pain Point from Reviews | How M Mobilnost 2.0 Solves It |
| :--- | :--- |
| **Fragmented apps for schedules vs. tickets** | Unified 4-tab shell (**Home**, **Map**, **Plan**, **Tickets**) with 1-tap transitions between route planning, live tracking, and ticket wallet/shop. |
| **Buses arriving early or late without actionable advice** | **Live Bus Tracker** (`/tracker`) computes real-time schedule deviation (`< -60s` early, `-60s..+120s` on time, `> +120s` late) and displays explicit action cards: *"This bus is X min early — be at the stop Y min sooner"* or *"This bus is X min late — expected at HH:mm"* with a 1-tap link to alternative routes. |
| **Unreliable or opaque live data** | Every live departure and vehicle view displays a transparent **`SimulatedDataBadge`** (`Live data`, `Simulated data`, `Cached`, or `Live data not available, showing timetable`) plus `Last updated: HH:mm:ss` timestamps, and degrades gracefully to cached static schedules when offline. |
| **Delayed ticket activation locks riders out on boarding** | **Immediate validity by default** (`validFrom = now`) during checkout, with an optional *"Choose start time"* toggle for pre-purchased trips. |
| **QR scanning failures on dim screens** | **`TicketViewScreen`** (`/tickets/view/:ticketId`) automatically boosts screen brightness on mobile (`!kIsWeb`), shows a live ticking anti-screenshot clock, and includes a human-readable **Driver fallback code** (`MP-XXXX-XXXX`). |
| **App blocked when GPS permission is denied** | Calm explanation banner + **Manual Maribor Stop Mode** (`favoritesProvider.setManualStop`, defaulting to `glavni_trg`) so riders can use the entire app without GPS. |
| **Inaccessible small controls & color-only indicators** | `>= 56x56 dp` `BigButton`s (always icon + text, never icon-only), **200% extra-large text scale** support, **WCAG AAA High Contrast** black/white/yellow theme, **color + pattern + text** `OccupancyStrip`, and a **Map / List-view toggle** on every map screen. |

---

## 2. Getting Started (Mobile & Web)

### Prerequisites
- Flutter SDK `>= 3.47.0` (Dart SDK `^3.13.7`)

### Install Dependencies & Generate Localizations
```powershell
flutter pub get
flutter gen-l10n
```

### Run on Mobile (Android / iOS) or Desktop
```powershell
flutter run
```

### Run & Build for Web
```powershell
# Run in Chrome
flutter run -d chrome

# Production web build
flutter build web
```

### Static Analysis & Automated Tests
Run each command individually:
```powershell
flutter gen-l10n
flutter analyze
flutter test
```
Verify `build/l10n_untranslated.txt` contains `{}` (0 untranslated keys across all locales).

---

## 3. Multi-Language Support (`sl`, `en`, `de`, `sr_Latn`)

M Mobilnost 2.0 ships with **418 localized keys** across all supported locales with zero untranslated strings:
- **Slovenščina (`sl`)** — Default template (`lib/l10n/app_sl.arb`, with full ICU plural forms `=0`, `one`, `two`, `few`, `other`)
- **English (`en`)** — (`lib/l10n/app_en.arb`)
- **Deutsch (`de`)** — (`lib/l10n/app_de.arb`)
- **Srpski / Hrvatski (`sr_Latn`)** — Neutral Latin-script vocabulary (`lib/l10n/app_sr_Latn.arb` + base fallback `lib/l10n/app_sr.arb` with ICU plural forms `=0`, `one`, `few`, `other`)

### Switching Languages at Runtime
- **First Launch**: Pick any of the 4 languages at the top of **`OnboardingScreen`** (`/onboarding`); the entire UI updates immediately.
- **Anytime**: Open **Settings** (`/settings`) -> **Language** (`Jezik`) or update `preferredLocaleCode` in **Account** (`/account`).
- State is persisted in `SharedPreferences` via `a11ySettingsProvider.notifier.setLocaleCode(code)` and resolved in `MMobilnostApp` (`lib/app/app.dart`) via `A11ySettings.toLocale()`.

---

## 4. Accessibility Architecture

- **WCAG AA & AAA Themes (`lib/core/theme/`)**:
  - `AppTheme.light` & `AppTheme.dark`: Marprom transit blue (`#004B87`) and mobility green (`#0B6E4F`) meeting `>= 4.5:1` contrast.
  - `HighContrastTheme.build`: Pure black (`#000000`), crisp white (`#FFFFFF`, `21:1`), and transit yellow (`#FFD600`, `14.7:1`) with `2dp` borders meeting WCAG AAA (`>= 7:1`).
- **200% Extra-Large Text Scaling**:
  - Toggleable in Onboarding or Settings (`extraLargeText`), applying `TextScaler.linear(2.0)` globally in `MMobilnostApp`. All cards and rows use `Wrap`/`Flexible` layouts verified at `390x844` with `2.0x` scaling.
- **Screen Readers, TTS & Voice Input (`lib/core/accessibility/`)**:
  - Every interactive control and status badge exposes localized `Semantics` labels (`context.l10n.a11y*`).
  - `ReadAloudService` (`readAloudProvider`) wraps `flutter_tts` with safe web/test guards to speak departures, route steps, ticket validity, and beginner guide cards.
  - `VoiceInputService` (`voiceInputProvider`) wraps `speech_to_text` with web/test guards for voice queries in **Ask Marprom** and stop search.
- **Deaf / Hard-of-Hearing & Color-Blind Support**:
  - `HapticCues.trigger` provides distinct vibration patterns (`arriving`, `late`, `ticketExpiring`, `disruption`, `tap`) guarded by `!kIsWeb` and `try/catch`, paired with prominent visual banners and optional sound alerts.
  - `OccupancyStrip` renders custom-painted fill patterns (solid, diagonal stripes, cross-hatch, dense fill) alongside icons and localized text.
  - Every map view (`MapScreen`, `LineDetailScreen`, `LiveTrackerScreen`, `TripPlannerScreen`) provides a **List-view toggle** with 100% information parity.
- **Usability Test Mode (`lib/features/settings/domain/usability_tracker.dart`)**:
  - Built-in timed scenario runner recording task duration, tap counts, and error counts, exporting **zero-PII CSV and JSON** reports.

---

## 5. Swapping Mock Data for Firebase & Real Marprom GTFS-RT

All UI and domain layers depend exclusively on abstract repository contracts in `lib/data/repositories/` and Riverpod providers in **`lib/data/repositories/repository_providers.dart`** (marked with `// TODO(firebase)`).

To connect production Firebase & Marprom GTFS / GTFS-RT feeds:
1. Implement the 8 repository interfaces in `lib/data/repositories/`:
   - `LineRepository` (`line_repository.dart`) -> Marprom static GTFS stops, lines, and route polylines
   - `TimetableRepository` (`timetable_repository.dart`) -> GTFS schedules merged with GTFS-RT TripUpdates + local `Hive` offline cache
   - `LiveBusRepository` (`live_bus_repository.dart`) -> GTFS-RT VehiclePositions stream & APC passenger-counting occupancy sensors (replacing `BusSimulator`, `DelayModel`, and `OccupancyModel`)
   - `TripRepository` (`trip_repository.dart`) -> Multimodal routing engine / OTP endpoint
   - `AuthRepository` (`auth_repository.dart`) -> `FirebaseAuth` + `Cloud Firestore` user profile document
   - `TicketRepository` (`ticket_repository.dart`) -> `Cloud Firestore` + signed QR token Cloud Function + local `Hive` offline cache
   - `PaymentRepository` (`payment_repository.dart`) -> PCI-DSS PSP SDK (Stripe / Braintree / Flik) storing only tokenized references
   - `NoticeRepository` (`notice_repository.dart`) -> Marprom service alerts Firestore collection / GTFS-RT Alerts feed
2. Update the provider bindings in **`lib/data/repositories/repository_providers.dart`**. Zero changes are required in `lib/features/` or `lib/app/`.

> **Demo Credentials (Mock Auth)**:
> `demo@marprom.test` / `demo1234` (or use the 1-tap demo fill button on `/account`).

---

## 6. Future NFC Boarding Extension Point

Contactless NFC boarding/validation is architected behind **`lib/features/tickets/nfc/ticket_card_reader.dart`**:
- **`TicketCardReader`** abstract interface:
  - `Future<bool> isAvailable()`
  - `Future<NfcCardReaderStatus> readCardStatus()`
  - `Future<DateTime> simulateTapValidation(String ticketId)`
- **`StubTicketCardReader`**: Current default implementation bound to `ticketCardReaderProvider`, returning `isAvailable: false` with `StubTicketCardReader.comingSoonMessage` (`"NFC card in app coming soon"`) and supporting simulated tap validation in `TicketViewScreen`.
- To enable hardware HCE / NFC validation on Android & iOS, provide a platform `TicketCardReader` implementation in `ticketCardReaderProvider`.

---

## 7. Folder Structure Overview

```text
m_mobilnost/
├── l10n.yaml                         # Flutter gen-l10n configuration (template: app_sl.arb)
├── pubspec.yaml                      # Dependencies & Flutter configuration
├── README.md                         # Setup, architecture, and extension guide
├── PRIVACY_NOTES.md                  # GDPR data inventory, minor safeguards & storage map
├── lib/
│   ├── main.dart                     # Hive, SharedPreferences & ProviderScope bootstrap
│   ├── app/
│   │   ├── app.dart                  # MMobilnostApp (MaterialApp.router, 200% text scaler, themes)
│   │   ├── router.dart               # GoRouter deep links & first-launch /onboarding redirect
│   │   └── shell_scaffold.dart       # Adaptive NavigationBar (<600px) / NavigationRail (>=600px)
│   ├── core/
│   │   ├── accessibility/            # A11ySettings, FavoritesNotifier, HapticCues, ReadAloud, VoiceInput
│   │   ├── layout/                   # LayoutBreakpoints (compact/medium/expanded) & ResponsiveBuilder
│   │   ├── network/                  # Connectivity provider, DataFreshness, mapTileProviderProvider
│   │   ├── theme/                    # WCAG AA light/dark themes & WCAG AAA HighContrastTheme
│   │   ├── utils/                    # 24h/EUR TimeFormatUtils, DistanceUtils, Haversine GeoUtils
│   │   └── widgets/                  # BigButton (>=56dp), StatusChip, OccupancyStrip, OfflineBanner
│   ├── data/
│   │   ├── models/                   # BusStop, BusLine, Departure, BusPosition, TripOption, Ticket, etc.
│   │   ├── seed/                     # 40 Maribor stops, 12 lines, timetables, 7 EUR tickets, notices
│   │   ├── simulation/               # Deterministic DelayModel, OccupancyModel, BusSimulator, notices
│   │   ├── repositories/             # Abstract repository interfaces & repository_providers.dart
│   │   └── mock/                     # Mock*Repository implementations & safe Hive LocalKeyValueStore
│   ├── features/
│   │   ├── home/                     # Personalized HomeScreen dashboard & Ask Marprom assistant
│   │   ├── lines/                    # LinesScreen, LineDetailScreen & LineBadge
│   │   ├── timetable/                # StopDetailScreen grouped departures & amenities
│   │   ├── map/                      # MapScreen (flutter_map + List-view toggle + split view)
│   │   ├── live_tracker/             # LiveTrackerScreen with early/late advice cards & arrival alerts
│   │   ├── trip_planner/             # Multimodal TripPlannerScreen & step-by-step assistant
│   │   ├── nearest_stop/             # NearestStopScreen ranked by earliest destination arrival
│   │   ├── tickets/                  # TicketsWalletScreen, TicketShop, 3-step Checkout, QR View & NFC stub
│   │   ├── account/                  # AccountScreen (guest/auth, minor <16/<18 guard, GDPR wipe) & Payments
│   │   ├── notices/                  # NoticesScreen disruption filter & smart alerts
│   │   ├── onboarding/               # OnboardingScreen & 5-card NewRiderGuideScreen
│   │   └── settings/                 # SettingsScreen & zero-PII UsabilityTracker console
│   └── l10n/                         # app_sl.arb, app_en.arb, app_de.arb, app_sr_Latn.arb, app_sr.arb
├── test/
│   ├── widget_test.dart              # App shell, routing, locale, theme, and core widget tests
│   ├── data/                         # Simulator, delay/occupancy model, and repository unit tests
│   └── features/                     # Feature, accessibility 200% text-scale, and breakpoint tests
└── web/                              # index.html, manifest.json, and PWA icons
```
#   m _ m o b i l n o s t  
 