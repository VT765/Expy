import SwiftUI

/// Icon, name, "₹15,000 · Monthly · Next 1 Dec" (or Paused / Ended).
struct RecurringRuleRow: View {
    let rule: RecurringRule
    let category: ExpenseCategory?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if rule.kind == .transfer {
                    TransferCircle(size: 36)
                } else {
                    EmojiCircle(emoji: category?.emoji ?? "✨", colorHex: category?.colorHex ?? "#9DB0C4", size: 36)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(rule.note.isEmpty ? category?.name ?? "Recurring" : rule.note).font(.app(16, .semibold)).lineLimit(1)
                    Text(detail).font(.tFootnote).foregroundStyle(Theme.sub).lineLimit(1)
                }
                Spacer()
                Text((rule.kind == .credit ? "+" : "") + Fmt.money(rule.amount)).font(.app(16, .semibold)).monospacedDigit()
                    .foregroundStyle(rule.kind == .credit ? Theme.positive : .white)
                Image(systemName: "chevron.right").font(.app(13, .semibold)).foregroundStyle(Theme.faint).accessibilityHidden(true)
            }
            .padding(.horizontal, 16).frame(minHeight: 64)
            .opacity(rule.isPaused || ended ? 0.5 : 1)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    private var ended: Bool { RecurrenceSchedule.hasEnded(next: rule.nextDate, end: rule.endDate) }

    private var detail: String {
        let state = rule.isPaused ? "Paused" : ended ? "Ended" : "Next \(Fmt.shortDate(rule.nextDate))"
        return "\(rule.frequency.label) · \(state)"
    }
}
