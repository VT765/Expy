import SwiftUI

/// One parsed statement transaction: include checkbox, narration, date,
/// category picker, duplicate warning, amount.
struct StatementReviewRow: View {
    @Binding var row: StatementImportView.ReviewRow
    let categories: [ExpenseCategory]

    private var category: ExpenseCategory? { categories.first { $0.id == row.categoryId } }

    var body: some View {
        HStack(spacing: 12) {
            Button(row.include ? "Included" : "Excluded", systemImage: row.include ? "checkmark.circle.fill" : "circle",
                   action: toggleInclude)
                .labelStyle(.iconOnly)
                .font(.app(22))
                .foregroundStyle(row.include ? .white : Theme.faint)
                .frame(minWidth: 44, minHeight: 44)
                .accessibilityLabel("Include \(row.source.narration)")
                .accessibilityAddTraits(row.include ? .isSelected : [])
            VStack(alignment: .leading, spacing: 3) {
                Text(row.source.narration.isEmpty ? "—" : row.source.narration).font(.tBodySemibold).lineLimit(1)
                HStack(spacing: 6) {
                    Text(Fmt.shortDate(row.source.date))
                    Menu {
                        Picker("Category", selection: $row.categoryId) {
                            ForEach(categories) { c in Text("\(c.emoji) \(c.name)").tag(c.id) }
                        }
                    } label: {
                        Text("\(category?.emoji ?? "✨") \(category?.name ?? "Other") ▾")
                            .padding(.horizontal, 8).padding(.vertical, 2)
                            .background(Capsule().fill(Theme.raised))
                    }
                    .accessibilityLabel("Category: \(category?.name ?? "Other")")
                    if row.duplicate {
                        Label("Possible duplicate", systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color(hex: "#FFB340"))
                    }
                }
                .font(.app(12)).foregroundStyle(Theme.sub)
            }
            Spacer(minLength: 6)
            Text((row.source.isCredit ? "+" : "−") + Fmt.money(row.source.amount))
                .font(.app(15, .bold)).monospacedDigit()
                .foregroundStyle(row.source.isCredit ? Theme.positive : .white)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .opacity(row.include ? 1 : 0.5)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.well).frame(height: 0.5).padding(.leading, 48) }
    }

    private func toggleInclude() {
        row.include.toggle()
        Haptics.selection()
    }
}
