import AppIntents
import SwiftUI

/// Settings → Bank SMS & email: how to set up the Shortcuts automations,
/// the auto-log switch, and a box to try (or add) any bank message.
struct BankMessagesView: View {
    @AppStorage(ReviewInbox.autoLogKey) private var autoLog = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("iOS doesn't let apps read your SMS or email. A Shortcuts automation can, and it passes each bank message to Expy, which suggests the entry in History → To review.")
                    .font(.tFootnote).foregroundStyle(Theme.sub)

                SettingsSection(title: "Review") {
                    SettingsRow(title: "Add without review", subtitle: "Log straight into History when the account is known and it isn't a duplicate",
                                chevron: false, action: nil) {
                        Toggle("Add without review", isOn: $autoLog).labelsHidden().tint(Theme.positive)
                    }
                }

                SettingsSection(title: "Bank SMS", hint: "Once per bank. Takes a minute.") {
                    QuickLaunchCard {
                        QuickLaunchStep(number: 1, text: "Open Shortcuts → Automation → + → Message.")
                        QuickLaunchStep(number: 2, text: "Set Message Contains to “Rs” (and Sender to your bank, if you like).")
                        QuickLaunchStep(number: 3, text: "Choose Run Immediately and turn off Notify When Run, then tap Next.")
                        QuickLaunchStep(number: 4, text: "Tap New Blank Automation → Add Action, search “Expy” and pick Add from Bank Message.")
                        QuickLaunchStep(number: 5, text: "Tap Message in the action and choose Shortcut Input. Done.")
                    }
                    ShortcutsLink()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }

                SettingsSection(title: "Bank email", hint: "For banks that send alerts by email.") {
                    QuickLaunchCard {
                        QuickLaunchStep(number: 1, text: "Shortcuts → Automation → + → Email.")
                        QuickLaunchStep(number: 2, text: "Set Sender to the bank's alert address (e.g. alerts@hdfcbank.net) or Subject Contains “debited”.")
                        QuickLaunchStep(number: 3, text: "Run Immediately, then add Expy's Add from Bank Message with Shortcut Input, like for SMS.")
                    }
                }

                SettingsSection(title: "Try a message", hint: "Paste any bank SMS to see what Expy reads, or add it by hand.") {
                    MessageTester()
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 32)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.canvas)
        .navigationTitle("Bank SMS & email")
        .navigationBarTitleDisplayMode(.inline)
    }
}
