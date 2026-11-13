# LedGix Rent

Flutter app (iOS + Android) for UAE landlords to manage rented units without an agent.
Version 1 = landlord app: portfolio, tenants and leases, cheque manager, direct debits,
hold requests, reminders, maintenance, vendors, dashboard and documents. English and Arabic (RTL), AED, `dd/MM/yyyy`, GST.

## Run it

```bash
flutter pub get
flutter run                                   # real Firebase backend (the default)
flutter run --dart-define=USE_FIREBASE=false  # demo mode: in-memory data, any login works
flutter test                                  # always demo mode
flutter test integration_test -d <device-id> --dart-define=USE_FIREBASE=false   # same flows + every screen, on a real phone
```

Firebase is the default, so builds from Xcode, Xcode Cloud and Android Studio use the real backend without any extra flags. Demo mode (in-memory repositories and a fake login, forgotten on every launch) is only used by `flutter test` or when you pass `--dart-define=USE_FIREBASE=false`.

## Branding

Amber brand colours live in `lib/core/theme/app_colors.dart`; the light and dark Material 3 themes and the
semantic status colours (`context.status`) are in `lib/core/theme/app_theme.dart`. Don't create colours elsewhere.
Logos: `assets/ledgix-rent-logo.png` (mark + "Rent") and `assets/ledgix-rent-logo-mark.png`.

After changing a logo, regenerate the icons and splash screens:

```bash
dart run flutter_launcher_icons        # config: flutter_launcher_icons.yaml (sources in assets/icon/)
dart run flutter_native_splash:create  # config: flutter_native_splash.yaml
```

## Releasing to test tracks

Bump `version:` in `pubspec.yaml` (the `+N` build number must increase every upload), then:

```bash
flutter build ipa --release --dart-define=USE_FIREBASE=true --export-options-plist=ios/ExportOptions.plist   # upload build/ios/ipa/*.ipa with Transporter
flutter build appbundle --release --dart-define=USE_FIREBASE=true   # upload build/app/outputs/bundle/release/app-release.aab in Play Console
```

### Web (Firebase Hosting)

Live at https://rent.getledgix.com (custom domain on Firebase Hosting; https://ledgix-rent.web.app also serves it).

| Path | What | Source |
| --- | --- | --- |
| `/` | Landing page (EN/AR, light/dark) | `landing/` |
| `/privacy/` | Privacy policy | `landing/privacy/` |
| `/app/` | The Flutter web app | `flutter build web --base-href /app/` |
| `/hub-callback` | LedGix ID return URL, rewritten to the app | `firebase.json` |

`tool/build_web.sh` builds the app and assembles everything into `build/hosting` (Hosting's public folder). It needs the git-ignored `lib/firebase_options.dart`, `web/firebase-messaging-sw.js` and `firebase.json` (copies in `secrets/`) and reads the Web Push key from `secrets/secrets.txt`.

```bash
tool/build_web.sh
firebase deploy --only hosting --project ledgix-rent
```

Phone sign-in is not wired up for web (it needs reCAPTCHA); LedGix ID, email, Google and Apple work.

## Properties, tenants, rent agreements and Scan to fill

- **Add property** (`/property/new`, edit at `/property/:id/edit`): type, name and address are mandatory (marked *); DEWA premise/account, Mollak registration, HOA, title deed, owner's Emirates ID/passport and annual rent are optional. Documents are a list of typed files (DEWA bill, Title deed *, owner's Emirates ID/passport, Mollak, Ejari, tenancy contract, other), uploaded on Save to `landlords/{uid}/documents/{propertyId}/` (20 MB max each).
- **Add tenant** (`/tenants/new`): first/last name, contact no. and Emirates ID no. are mandatory, plus the Emirates ID copy. Older tenants saved with a single `name` still load (it is split into first/middle/last).
- **Rent agreements** (`/leases`): unit, tenant (with an **Add tenant** shortcut that comes back with the new tenant selected), Ejari no., term, rent, deposit, cheques and documents. A new agreement still generates the cheque schedule.
- **My profile** (`/profile`): the landlord's own Emirates ID and passport numbers.
- **Scan to fill** (top of each form): pick a photo or PDF; the app recognises DEWA bills, Ejari certificates, DLD tenancy contracts, title deeds, Emirates ID cards and passports (MRZ), and fills the matching fields. Filled fields are highlighted for review; anything you already typed is only replaced if you tick it. The scanned file is attached as a document.
  - OCR is **on the device** (Apple Vision on iOS, Google ML Kit on Android, through the `ledgix/ocr` channel in `AppDelegate.swift` / `MainActivity.kt`); nothing is uploaded to read it. PDFs: first 3 pages.
  - It reads the **English** half of bilingual documents; Arabic-only text is ignored. Scanning is not available in the web app.
  - Parsing is plain Dart in `lib/features/documents/domain/` (unit-tested with made-up documents).
  - **Your own ID is never a tenant:** if a scanned ID, passport or tenant section matches your profile (or a property's owner ID), nothing is filled in as a tenant and saving a tenant with it is blocked. Add your own Emirates ID in My profile so this works.

## Roles and the tenant app

- **Onboarding** asks only for your name, number of units and role (Landlord or Property manager). Properties are added afterwards from the property form.
- **Tenant sign-up**: on "Create account", choose "I'm a tenant". Tenant onboarding asks for a name and, optionally, an invite code.
- **Invite codes**: after adding a tenant (or a rent agreement for a tenant who hasn't joined) the landlord gets an 8-character code to copy or share; "Invite to app" on the tenant list makes a new one. Codes expire after 30 days and work once.
- **Several landlords**: a tenant adds more landlords with codes under Landlords. When every lease with a landlord has ended, that landlord moves to "Former" (read-only) and can be removed.
- **Sharing**: each document row has a "Share with tenant" switch (off by default). Cheque copies are shared with that lease's tenant by default and can be switched off per cheque.
- **Tenant app** (`/t/...`): Home, Landlords (name, email, phone, Emirates ID), Properties ("{name} · Agreement AED x", expand for details and shared documents), Payments (status and cheque copies), Inspections, Maintenance requests, Settings.
- **Reminders for tenants**: 7, 3 and 1 days before each payment and on the due day, when a cheque bounces or is put on hold, and 60/30 days before a lease ends.
- **Demo preview**: a demo web build (`USE_FIREBASE=false`) opened at `/app/?demo=tenant` signs in as a sample tenant with made-up data.

How it works: tenants never read `landlords/{uid}/**`. Cloud Functions (`functions/src/tenants.ts`) keep a filtered copy per tenant in `tenantViews/{tenantUid}/…` and the links in `tenantLinks/{tenantUid}/landlords/{landlordUid}`; both are read-only to the tenant. Invite codes live server-side in `invites/`. Test the whole flow offline:

```bash
cd functions && npm run build && cd ..
firebase emulators:exec --only firestore,functions,auth,storage --project demo-ledgix-rent "node functions/scripts/tenant_flow_emulator_test.mjs"
```

(`firebase.json` needs an `emulators` block with auth 9099, firestore 8080, functions 5001 and storage 9199.)

## Architecture

- `lib/features/<feature>/{data,domain,presentation}`, shared code in `lib/core`.
- Riverpod for state, go_router for routing.
- Repository interfaces live in `domain` (`CrudRepository<T>`). Implementations: `InMemoryRepository` (demo/tests) and `FirestoreRepository`. Financial data can move to Cloud SQL Postgres later by adding one more implementation.
- Domain logic with unit tests: payment schedule from cheque count, hold-request rules, reminder dates, dashboard totals.

## Connecting Firebase (owner steps, nothing here creates cloud resources)

Secrets are git-ignored. **Never commit them.**

1. Create a Firebase project in the console. Enable **Auth** (Email/Password and Phone), **Firestore**, **Storage**, **Cloud Messaging**.
2. Register the Android and iOS apps, both `com.ledgix.rent`.
3. Download and place the files (both are git-ignored):
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
   - `lib/firebase_options.dart` (`flutterfire configure`; `main.dart` imports it for the web options)
4. Android: add the Google Services Gradle plugin (`com.google.gms.google-services`) to `android/settings.gradle.kts` and `android/app/build.gradle.kts` as shown in the FlutterFire docs. iOS: add the plist to the Runner target in Xcode and enable Push Notifications + Background Modes.
5. Copy `.env.example` to `.env` (placeholders only, kept for your own tooling).
6. Security rules: `firestore.rules` and `storage.rules` (each landlord can only access `landlords/{uid}/**`). Deploy with `firebase deploy --only firestore:rules,storage --project ledgix-rent`.
7. Google and Apple sign-in: enable both under Authentication → Sign-in method. Google on Android also needs the debug and release SHA-1 fingerprints in Project settings, then a fresh `google-services.json`. The iOS Google callback (`REVERSED_CLIENT_ID`) is in `Info.plist` under `CFBundleURLTypes`; update it if you ever change the iOS Firebase app. Apple shows on iOS and web only.
8. Run with Firebase on:
   ```bash
   flutter run --dart-define=USE_FIREBASE=true
   ```
9. Cloud Functions (reminders), run these yourself:
   ```bash
   cd functions && npm install && npm run build
   firebase deploy --only functions --project ledgix-rent   # Node 22, us-central1 (same area as Firestore nam5)
   ```
   `dailyReminders` runs at 08:00 GST and sends the 3-day and 1-day deposit reminders plus the 90/60/30-day lease renewal alerts to tokens saved in `landlords/{uid}.fcmTokens`.

## Add-ons (all mock-first)

Every external integration sits behind an interface with a mock, runs **server-side only** (Cloud Functions, called from the app via `httpsCallable`), and has a feature flag. Demo mode uses the Dart mocks, so everything works without credentials.

| Add-on | App | Server (`functions/src`) |
|---|---|---|
| Maintenance forwarding | ticket detail, work order, quotes, company profiles | `deliverWorkOrder` (push or email), `quotePage` (no-signup quote page) |
| Utility bills | per-property bills screen, manual entry + photo | `utilityBillCheck` (daily; per-landlord `utilityCheckDay`), `utilityFetch` |
| Ejari | Verify Ejari on lease, status badge, renewal alerts from Ejari expiry | `ejariLookup` |
| Mollak | jointly-owned toggle, service-charge card, in unit reports | `mollakQuery` |

Interfaces: `EjariService`, `MollakService`, `UtilityBillService` (Dart: `lib/features/integrations`, TS: `functions/src/integrations/services.ts`), plus `EmailService` (TS only).

**Feature flags**: app `--dart-define=FF_EJARI=false` (also `FF_MOLLAK`, `FF_UTILITY_BILLS`, `FF_FORWARDING`); server env vars with the same names; `*_MODE=live` switches a gateway from mock to live.

### What you must obtain for each real integration

| Integration | You need | Where it goes |
|---|---|---|
| Ejari and Mollak | A registered business account with the Dubai Land Department and access to the **DLD API Gateway** (Ejari Contract Enquiry on the Dubai developer portal is a lighter option) | Client id/secret in Secret Manager as `DLD_GATEWAY_CLIENT_ID` / `DLD_GATEWAY_CLIENT_SECRET`; implement `LiveEjariService` / `LiveMollakService`; set `EJARI_MODE=live` / `MOLLAK_MODE=live` |
| DEWA / chiller bills | DEWA's enquiry API is for partners only, so use a bank bill-payment API (for example Mashreq utility bill payment) or a licensed aggregator and sign its agreement | `UTILITY_PROVIDER_API_KEY` in Secret Manager; implement `LiveUtilityBillService`; `UTILITY_MODE=live` |
| Work-order email | An email provider of your choice (SendGrid, Postmark, SES...) with a verified sender domain | `EMAIL_PROVIDER_API_KEY` in Secret Manager; implement `LiveEmailService`; `EMAIL_MODE=live`; set `QUOTE_PAGE_URL` to the deployed `quotePage` URL |

Never commit keys. Deploy yourself with `firebase deploy --only functions`.

**Not built yet**: the maintenance company's own in-app inbox (work orders are stored and pushed to a linked company account, but the company-side screens are a later version), bill payment, Ejari registration/renewal and fee payment, and PDF bill upload (needs a file-picker package; photos work now).

## Data layout (Firestore)

`users/{uid}` (role, name, units, push tokens) · `landlords/{uid}/…` (landlord data) · `tenantViews/{uid}/…` and `tenantLinks/{uid}/…` (tenant read model, server-written) · `invites/{code}` (server-only).

`landlords/{uid}/{profile|properties|tenants|leases|payments|holdRequests|maintenanceTickets|vendors|workOrders|quotes|utilityBills|serviceCharges}/{id}`

## Offline

Firestore's local cache keeps data viewable offline and syncs when back online.

## Later versions (design is ready, not built)

Tenant app, online payments (Network International, Telr or Stripe UAE), DEWA/chiller bills, Ejari integration, Postgres migration.
