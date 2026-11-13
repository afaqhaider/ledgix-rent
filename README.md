# LedGix Rent

Flutter app (iOS + Android) for UAE landlords to manage rented units without an agent.
Version 1 = landlord app: portfolio, tenants and leases, cheque manager, direct debits,
hold requests, reminders, maintenance, vendors, dashboard and documents. English and Arabic (RTL), AED, `dd/MM/yyyy`, GST.

## Run it now (no Firebase needed)

```bash
flutter pub get
flutter run          # demo mode: in-memory data, any login works
flutter test
flutter test integration_test -d <device-id>   # same flows + every screen, on a real phone
```

Demo mode is the default. It uses in-memory repositories and a fake login so you can click through the whole app.

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

`landlords/{uid}/{profile|properties|tenants|leases|payments|holdRequests|maintenanceTickets|vendors|workOrders|quotes|utilityBills|serviceCharges}/{id}`

## Offline

Firestore's local cache keeps data viewable offline and syncs when back online.

## Later versions (design is ready, not built)

Tenant app, online payments (Network International, Telr or Stripe UAE), DEWA/chiller bills, Ejari integration, Postgres migration.
