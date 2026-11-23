import SwiftUI

/// Single rupee amount editor (budgets).
struct AmountSheet: View {
    let title: String
    var hint: String?
    let value: Double
    var removeLabel = "Remove"
    var onSave: (Double) -> Void
    @State private var amount: Double?
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(title).font(.tHeadline).padding(.top, 20)
            if let hint { Text(hint).font(.tFootnote).foregroundStyle(Theme.sub).multilineTextAlignment(.center) }
            HStack(spacing: 8) {
                Text("₹").font(.app(34, .bold)).foregroundStyle(Theme.sub)
                TextField("0", value: $amount, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .focused($focused)
                    .font(.app(40, .bold))
                    .fixedSize()
            }
            .padding(.vertical, 12)
            Spacer()
            HStack(spacing: 12) {
                if value > 0 {
                    PrimaryButton(title: removeLabel, role: .destructive, action: remove).frame(width: 130)
                }
                PrimaryButton(title: "Save", action: save)
                    .disabled((amount ?? 0) <= 0)
            }
        }
        .padding(.horizontal, Theme.gutter).padding(.bottom, 12)
        .presentationDetents([.medium])
        .presentationBackground(Theme.card)
        .onAppear(perform: prepare)
    }

    private func prepare() {
        amount = value > 0 ? value : nil
        focused = true
    }

    private func remove() {
        onSave(0)
        dismiss()
    }

    private func save() {
        onSave(amount ?? 0)
        dismiss()
    }
}
