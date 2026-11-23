import SwiftUI

/// Label over a big rolling number, with optional extra content.
struct StatTile<Extra: View>: View {
    let label: String
    let value: String
    var big = false
    @ViewBuilder var extra: Extra

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.tFootnote).foregroundStyle(Theme.sub)
            // Proportional figures read better than tabular ones at this size.
            Text(value).font(.app(big ? 32 : 20, .bold))
                .lineLimit(1).minimumScaleFactor(0.6)
                .contentTransition(.numericText())
                .animation(.snappy, value: value)
            extra
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.cardRadius).fill(Theme.card))
        .accessibilityElement(children: .combine)
    }
}

extension StatTile where Extra == EmptyView {
    init(label: String, value: String, big: Bool = false) {
        self.init(label: label, value: value, big: big, extra: { EmptyView() })
    }
}
