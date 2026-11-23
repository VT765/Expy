import SwiftUI

/// "How much?" and the big rupee amount.
struct AmountHeader: View {
    let model: TapModel

    var body: some View {
        let shown = AmountInput.display(model.amount)
        let size = shown.count > 10 ? 32.0 : shown.count > 7 ? 38 : 46
        VStack(spacing: 2) {
            Text(model.isTransfer ? "How much to move?" : model.credit ? "How much came in?" : "How much?").font(.app(13)).foregroundStyle(Theme.sub)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text((model.credit && model.value > 0 ? "+" : "") + "₹").font(.app(size, .bold)).accessibilityHidden(true)
                Text(shown)
                    .font(.app(size, .bold))
                    .monospacedDigit()
                    .contentTransition(.numericText(value: model.value))
                    .animation(.snappy(duration: 0.18), value: model.amount)
            }
            .scaleEffect(model.savePulse ? 0.9 : 1)
            .opacity(model.savePulse ? 0 : 1)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Fmt.money(model.value))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
