# Expy

A personal expense tracker for iPhone: native SwiftUI, rupees only, and all data stays on the device (no server, no account).

The app lives in [`ios/`](ios/README.md). `ui-ss/` holds design reference screenshots.

## Highlights

- **Tap** to log a debit, credit or transfer in a couple of taps, with per-kind categories and accounts.
- **History** grouped by day or category, with filters, search, and a Total Net card (Spent / Received).
- **Analytics**: balances, budget progress, spending over time, a multi-period trend and "Where it went".
- **Accounts** with balances from your own entries; **transfers** between them (e.g. HDFC → Cash) never count as spending.
- **Recurring entries** (rent, subscriptions, EMIs) and **budget alerts** at 80% and 100%, via local notifications.
- **Bank SMS & email**: a Shortcuts automation hands each bank message to Expy, which suggests the entry for one-tap review.
- **Siri and Shortcuts** ("Log Transaction"), bank statement import (CSV/XLSX), Excel/CSV export, JSON backup and restore.
- **App Lock** with PIN and Face ID.

Your data is protected by iCloud Backup of the phone and by Expy's own backup file (Settings → Data).
