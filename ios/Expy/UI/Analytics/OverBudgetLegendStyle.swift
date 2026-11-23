import SwiftUI

/// Legend key for over-budget bars: a red swatch plus the warning icon, so
/// the status never relies on colour alone.
struct OverBudgetLegendStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2).fill(Theme.danger).frame(width: 10, height: 10)
            configuration.icon.foregroundStyle(Theme.danger).font(.app(11))
            configuration.title
        }
    }
}
