import SwiftUI

/// Sticky footer card: "Total Net" with the big net amount (green "+" when
/// more came in than went out), then Spent (red, left) and Received
/// (green, right) underneath.
struct HistoryTotalBar: View {
    let spent: Double
    let received: Double

    private var net: Double { received - spent }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Total Net").font(.app(18, .semibold)).foregroundStyle(Theme.sub)
                Spacer()
                Text(signed(net)).font(.app(26, .bold)).monospacedDigit()
                    .foregroundStyle(net > 0.004 ? Theme.positive : net < -0.004 ? Theme.danger : .white)
                    .contentTransition(.numericText(value: net))
                    .animation(.snappy, value: net)
            }
            HStack(alignment: .bottom) {
                TotalFigure(label: "Spent", value: spent > 0.004 ? "-" + Fmt.money(spent) : Fmt.money(0), color: Theme.danger)
                Spacer()
                TotalFigure(label: "Received", value: "+" + Fmt.money(received), color: Theme.positive, alignment: .trailing)
            }
        }
        .padding(.horizontal, 18).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: Theme.cardRadius).fill(Theme.card))
        .overlay(RoundedRectangle(cornerRadius: Theme.cardRadius).strokeBorder(Theme.well, lineWidth: 1))
        .padding(.horizontal, Theme.gutter)
        .padding(.vertical, 8)
        .background(Theme.canvas) // rows scroll under the gaps around the card
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Total net \(signed(net)). Spent \(Fmt.money(spent)), received \(Fmt.money(received)).")
    }

    /// "+₹5,000", "-₹3,000" or "₹0".
    private func signed(_ v: Double) -> String {
        v > 0.004 ? "+" + Fmt.money(v) : Fmt.money(v)
    }
}
