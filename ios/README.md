# Expy for iOS

**Requirements:** iOS 17+, Xcode 16+ (built with Xcode 27). No third-party dependencies.

**Stack:** SwiftUI, SwiftData (versioned schema with migrations), Swift Charts, App Intents (Siri, Shortcuts, bank-message action), UserNotifications (recurring reminders, budget alerts), LocalAuthentication (Face ID) and the Keychain. Everything runs on the device; there is no backend.

```
Expy/
  App/        App entry, root tabs (system tab bar + swipe between pages), router, notification delegate
  Models/     SwiftData models (SchemaV4) and frozen V1–V3 snapshots + migration plan, Money (paise), kinds, defaults
  Data/       DataStore, analytics, periods, formatting, statement parser
    Recurring/       recurrence date maths + engine
    Notifications/   local notifications, budget alerts
    BankMessages/    bank SMS/email parser, account matcher, review inbox
  Export/     Native .xlsx writer, CSV, versioned JSON backup (v1 files still restore)
  Intents/    Log Transaction, Add from Bank Message, App Shortcuts
  Security/   Keychain, LockManager (PIN PBKDF2 + Face ID)
  UI/         Tap, History, Analytics, Settings, Review, Lock, Splash, shared components
ExpyTests/    Swift Testing unit tests (parsers, money, analytics, migrations, backups…)
ExpyUITests/  XCUITest swipe/tab/category tests
```

The project uses Xcode synchronized folders, so new `.swift` files under each folder are included automatically. One type per file.

## Run it

1. Open `ios/Expy.xcodeproj` in Xcode.
2. **Expy** target → **Signing & Capabilities** → choose your **Team** (your Apple ID). Change the bundle identifier `com.varunthacker.expy` if Xcode says it's taken.
3. Pick a simulator or your iPhone and press **⌘R**. Run tests with **⌘U**.

### On your iPhone

- **Settings → Privacy & Security → Developer Mode** → on (asked the first time).
- With a free Apple ID the app runs for **7 days**, then needs reinstalling from Xcode. Data is kept across reinstalls. A paid Apple Developer membership removes the limit and enables TestFlight.

## Data and upgrades

- Amounts are stored as exact paise. The store is versioned (`Models/Schema`): each install migrates older data in place, after saving a copy in `Application Support/PreMigrationV4`.
- Back up from **Settings → Data → Export backup** before installing a build that changes the schema.

## Bank SMS & email

iOS doesn't let apps read messages. Set up a Shortcuts automation (Message or Email trigger → Run Immediately → Expy's **Add from Bank Message** with Shortcut Input). Steps are in **Settings → Bank SMS & email**, which also has a box to try any message.

## Debug launch arguments

`-seedDemo` sample data · `-solo history|analytics|settings` single screen · `-startTab 0…3` · `-noSplash` · `-splashAt 0.4` freeze the splash · `-demoAmount 250`, `-demoCredit`, `-demoTransfer`, `-demoInbox`, `-demoAnchor 0.5` for screenshots. Debug builds only.
