import AppIntents
import SwiftUI

/// Step-by-step setup for logging without opening Expy: Siri, Shortcuts,
/// Action button, Back Tap, Control Center, Lock Screen and Home Screen.
struct QuickLaunchView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("“Log Transaction” is built into Expy, so there's nothing to create. It asks: Credit or debit → Amount → Account → Category → Note, then saves and tells you the account's new balance.")
                    .font(.tFootnote).foregroundStyle(Theme.sub)

                SettingsSection(title: "Siri") {
                    SiriTipView(intent: LogTransactionIntent())
                        .siriTipViewStyle(.dark)
                    QuickLaunchCard {
                        QuickLaunchStep(number: 1, text: "Say “Hey Siri, log transaction in Expy”.")
                        QuickLaunchStep(number: 2, text: "Siri asks each question out loud; answer by voice or tap.")
                    }
                }

                SettingsSection(title: "Shortcuts app") {
                    QuickLaunchCard {
                        QuickLaunchStep(number: 1, text: "Open Shortcuts and find Expy under App Shortcuts.")
                        QuickLaunchStep(number: 2, text: "Tap Log Transaction to run it, or drag it into your own shortcut.")
                    }
                    ShortcutsLink()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 4)
                }

                SettingsSection(title: "Action button", hint: "iPhone 15 Pro and later.") {
                    QuickLaunchCard {
                        QuickLaunchStep(number: 1, text: "Open Settings → Action Button.")
                        QuickLaunchStep(number: 2, text: "Swipe to Shortcut, then tap Choose a Shortcut.")
                        QuickLaunchStep(number: 3, text: "Pick Log Transaction under Expy.")
                    }
                }

                SettingsSection(title: "Back Tap") {
                    QuickLaunchCard {
                        QuickLaunchStep(number: 1, text: "Open Settings → Accessibility → Touch → Back Tap.")
                        QuickLaunchStep(number: 2, text: "Choose Double Tap, scroll to Shortcuts, pick Log Transaction.")
                    }
                }

                SettingsSection(title: "Control Center", hint: "iOS 18 and later.") {
                    QuickLaunchCard {
                        QuickLaunchStep(number: 1, text: "Swipe down from the top-right corner, then tap + → Add a Control.")
                        QuickLaunchStep(number: 2, text: "Search for Shortcut, add it, then choose Log Transaction.")
                    }
                }

                SettingsSection(title: "Lock Screen & Home Screen") {
                    QuickLaunchCard {
                        QuickLaunchStep(number: 1, text: "Lock Screen: long-press → Customize → Lock Screen → add the Shortcuts widget → Log Transaction.")
                        QuickLaunchStep(number: 2, text: "Home Screen: long-press an empty area → Edit → Add Widget → Shortcuts → choose Log Transaction.")
                    }
                }

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                } label: {
                    Text("Open the Settings app")
                        .font(.tBodySemibold)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .foregroundStyle(.white)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.raised))
                }
                .buttonStyle(PressableStyle())
                .padding(.top, 28)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, Theme.gutter)
        }
        .background(Theme.canvas)
        .navigationTitle("Quick Launch")
        .navigationBarTitleDisplayMode(.inline)
    }
}
