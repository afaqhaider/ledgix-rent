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

## Data layout (Firestore)

`landlords/{uid}/{profile|properties|tenants|leases|payments|holdRequests|maintenanceTickets|vendors}/{id}`

## Offline

Firestore's local cache keeps data viewable offline and syncs when back online.

## Later versions (design is ready, not built)

Tenant app, online payments (Network International, Telr or Stripe UAE), DEWA/chiller bills, Ejari integration, Postgres migration.
