import SwiftUI

/// Paste a bank message, see how it's read, and add it to the review list.
struct MessageTester: View {
    @State private var text = ""
    @FocusState private var focused: Bool

    private var parsed: ParsedBankMessage? { BankMessageParser.parse(text) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $text)
                .focused($focused)
                .font(.app(14))
                .scrollContentBackground(.hidden)
                .frame(minHeight: 110)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 14).fill(Theme.raised))
                .overlay(alignment: .topLeading) {
                    if text.isEmpty {
                        Text("Paste a bank SMS here").font(.app(14)).foregroundStyle(Theme.faint)
                            .padding(.horizontal, 15).padding(.vertical, 18).allowsHitTesting(false)
                    }
                }
                .accessibilityLabel("Bank message")
            if !text.isEmpty {
                if let parsed {
                    ParsedMessageSummary(message: parsed)
                    PrimaryButton(title: "Add to review", icon: "tray.and.arrow.down", action: addToReview)
                } else {
                    Label("Not recognised as a completed transaction", systemImage: "questionmark.circle")
                        .font(.tFootnote).foregroundStyle(Theme.sub)
                }
            }
        }
    }

    private func addToReview() {
        guard let parsed else { return }
        guard let s = ReviewInbox.shared.suggestion(from: parsed) else {
            ToastCenter.shared.error("Already in Expy")
            return
        }
        ReviewInbox.shared.add(s)
        Haptics.success()
        ToastCenter.shared.show("Added to History → To review")
        text = ""
        focused = false
    }
}
