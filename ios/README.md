# Expy for iOS (native SwiftUI)

This is a native rewrite of the Expy PWA. It talks to the **same Vercel + MongoDB backend**, so the iPhone app and the web app share data.

**Requirements:** iOS 17+, Xcode 16+.

**Stack:** SwiftUI, SwiftData (on-device storage), Swift Charts, LocalAuthentication (Face ID), the Keychain, App Intents (Siri and Shortcuts) and URLSession sync. There are no third-party dependencies.

```
Expy/
  App/        ExpyApp (lifecycle, root view, tabs)
  Models/     SwiftData models + default categories
  Data/       DataStore (writes + outbox), periods, analytics, formatting, rates
  Sync/       API client, sync engine (outbox push → incremental pull), DTOs
  Security/   Keychain, LockManager (PIN PBKDF2 + Face ID), Session
  Export/     Native .xlsx writer (styled, formulas), CSV, JSON backup
  Intents/    “Log Expense” / “Log Credit” App Intents + App Shortcuts
  UI/         Theme, components, Tap / History / Analytics / Settings / Lock / Login
```

The project uses Xcode 16 synchronized folders, so new `.swift` files under `Expy/` are included automatically.

## Run it

1. Open `ios/Expy.xcodeproj` in Xcode.
2. Select the **Expy** target → **Signing & Capabilities** → choose your **Team** (your Apple ID). If Xcode complains that the bundle identifier `com.varunthacker.expy` is taken, change it to something unique.
3. Choose an iPhone simulator, or your own iPhone connected by cable, and press **⌘R**.

### On your iPhone

- **Settings → Privacy & Security → Developer Mode** → turn it on (iOS asks for this the first time).
- With a free Apple ID, the app works for **7 days**, then needs reinstalling from Xcode. A paid Apple Developer membership removes that limit and enables TestFlight.

## First launch

You'll see **Set up Expy** / **Welcome back**, which talks to `https://expy-iota.vercel.app`. To use a different server, tap **Server** on that screen. Sign in with your numeric password, or choose **Use without sync**.

## Siri, Shortcuts, Back Tap

No setup or API key is needed. Logging happens on the device and syncs the next time the app is open and online.

- **Shortcuts app:** "Log Expense" and "Log Credit" appear under **Expy** automatically. Each one asks for a category, an amount and an optional note.
- **Siri:** "Log expense in Expy" / "Log credit in Expy".
- **Back Tap:** Settings → Accessibility → Touch → Back Tap → Double Tap → **Log Expense**.
- **Action button / Control Center / Lock Screen widget:** add the **Log Expense** shortcut.
- **URL prefill:** `expy://add?amount=80&cat=Food&type=expense&note=Chai`.
