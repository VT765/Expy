import SwiftUI

/// Settings row as its own rounded card: title (+ grey subtitle) left,
/// grey value + › right.
struct SettingsRow<Trailing: View>: View {
    let title: String
    var subtitle: String?
    var value: String?
    var destructive = false
    var chevron = true
    var action: (() -> Void)?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        if let action {
            Button(action: action) { content }.buttonStyle(RowPressStyle())
        } else {
            content
        }
    }

    private var content: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.app(16, .semibold)).foregroundStyle(destructive ? Theme.danger : .white)
                if let subtitle { Text(subtitle).font(.tFootnote).foregroundStyle(Theme.sub).multilineTextAlignment(.leading) }
            }
            Spacer(minLength: 8)
            trailing
            if let value {
                Text(value + (chevron && action != nil ? " ›" : "")).font(.tBody).foregroundStyle(Theme.sub).lineLimit(1)
            } else if chevron && action != nil {
                Image(systemName: "chevron.right").font(.app(15, .semibold)).foregroundStyle(Theme.sub).accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .frame(minHeight: 58)
        .background(RoundedRectangle(cornerRadius: Theme.cardRadius).fill(Theme.card))
        .contentShape(.rect)
    }
}

extension SettingsRow where Trailing == EmptyView {
    init(title: String, subtitle: String? = nil, value: String? = nil, destructive: Bool = false, chevron: Bool = true,
         action: (() -> Void)? = nil) {
        self.init(title: title, subtitle: subtitle, value: value, destructive: destructive, chevron: chevron,
                  action: action, trailing: { EmptyView() })
    }
}
