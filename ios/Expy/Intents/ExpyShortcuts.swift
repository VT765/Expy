import AppIntents
import SwiftData

/// Zero-setup shortcuts: appear in the Shortcuts app and Siri automatically.
struct ExpyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: LogTransactionIntent(),
                    phrases: ["Log transaction in \(.applicationName)", "Log expense in \(.applicationName)",
                              "Add to \(.applicationName)", "\(.applicationName) entry"],
                    shortTitle: "Log Transaction", systemImageName: "plus.circle")
        AppShortcut(intent: AddFromBankMessageIntent(),
                    phrases: ["Add bank message to \(.applicationName)"],
                    shortTitle: "Add from Bank Message", systemImageName: "message.badge")
    }
}
