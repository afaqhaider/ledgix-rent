# LedGix Rent

Flutter app (iOS + Android) for UAE landlords to manage rented units without an agent.
Version 1 = landlord app: portfolio, tenants and leases, cheque manager, direct debits,
hold requests, reminders, maintenance, vendors, dashboard and documents. English and Arabic (RTL), AED, `dd/MM/yyyy`, GST.

## Run it now (no Firebase needed)

```bash
flutter pub get
flutter run          # demo mode: in-memory data, any login works
flutter test
```

Demo mode is the default. It uses in-memory repositories and a fake login so you can click through the whole app.

## Architecture

- `lib/features/<feature>/{data,domain,presentation}`, shared code in `lib/core`.
- Riverpod for state, go_router for routing.
- Repository interfaces live in `domain` (`CrudRepository<T>`). Implementations: `InMemoryRepository` (demo/tests) and `FirestoreRepository`. Financial data can move to Cloud SQL Postgres later by adding one more implementation.
- Domain logic with unit tests: payment schedule from cheque count, hold-request rules, reminder dates, dashboard totals.

## Connecting Firebase (owner steps, nothing here creates cloud resources)

Secrets are git-ignored. **Never commit them.**

1. Create a Firebase project in the console. Enable **Auth** (Email/Password and Phone), **Firestore**, **Storage**, **Cloud Messaging**.
2. Register the Android app `com.ledgix.ledgix_rent` and the iOS app `com.ledgix.ledgixRent`.
3. Download and place the files (both are git-ignored):
   - `android/app/google-services.json`
   - `ios/Runner/GoogleService-Info.plist`
4. Android: add the Google Services Gradle plugin (`com.google.gms.google-services`) to `android/settings.gradle.kts` and `android/app/build.gradle.kts` as shown in the FlutterFire docs. iOS: add the plist to the Runner target in Xcode and enable Push Notifications + Background Modes.
5. Copy `.env.example` to `.env` (placeholders only, kept for your own tooling).
6. Security rules: start from `firestore.rules.example` (each landlord can only access `landlords/{uid}/**`) and add equivalent Storage rules.
7. Run with Firebase on:
   ```bash
   flutter run --dart-define=USE_FIREBASE=true
   ```
8. Cloud Functions (reminders), run these yourself:
   ```bash
   cd functions && npm install && npm run build
   firebase deploy --only functions   # you run this, not the build agent
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
