import SwiftUI

/// Emoji, who/what, "HDFC ·6821 · 23 Nov · Food", amount, then Add / Dismiss.
struct SuggestionRow: View {
    let suggestion: Suggestion
    let category: ExpenseCategory?
    let account: Account?
    let add: () -> Void
    let dismiss: () -> Void
    let edit: () -> Void

    private var credit: Bool { suggestion.kind == .credit }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: edit) {
                HStack(spacing: 12) {
                    EmojiCircle(emoji: category?.emoji ?? "✨", colorHex: category?.colorHex ?? "#9DB0C4", size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.note.isEmpty ? (category?.name ?? "Bank transaction") : suggestion.note)
                            .font(.tBodySemibold).lineLimit(1)
                        Text(detail).font(.tFootnote).foregroundStyle(Theme.sub).lineLimit(1)
                    }
                    Spacer(minLength: 8)
                    Text((credit ? "+" : "") + Fmt.money(suggestion.amount)).font(.app(16, .bold)).monospacedDigit()
                        .foregroundStyle(credit ? Theme.positive : .white)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Edit before adding")
            if suggestion.possibleDuplicate {
                Label("Looks like an entry you already have", systemImage: "exclamationmark.triangle.fill")
                    .font(.tFootnote).foregroundStyle(Color(hex: "#FFB340"))
            }
            HStack(spacing: 10) {
                Button("Dismiss", systemImage: "xmark", action: dismiss)
                    .buttonStyle(.bordered).tint(Theme.sub)
                Button("Add", systemImage: "checkmark", action: add)
                    .buttonStyle(.borderedProminent).tint(Theme.positive).foregroundStyle(.black)
            }
            .font(.app(14, .semibold))
            .controlSize(.regular)
        }
        .padding(.vertical, 6)
    }

    private var detail: String {
        let where_ = account?.name ?? suggestion.bank.map { "\($0) (pick account)" } ?? "No account"
        let digits = suggestion.last4.map { " ·\($0)" } ?? ""
        return "\(where_)\(digits) · \(Fmt.shortDate(suggestion.date)) · \(category?.name ?? "Other")"
    }
}
