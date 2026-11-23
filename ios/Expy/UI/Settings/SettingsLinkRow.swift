import SwiftUI

/// A settings card that pushes a `SettingsRoute`.
struct SettingsLinkRow: View {
    let title: String
    var subtitle: String?
    var value: String?
    let route: SettingsRoute

    var body: some View {
        NavigationLink(value: route) {
            SettingsRow(title: title, subtitle: subtitle, chevron: false, action: nil) {
                if let value {
                    Text("\(value) ›").font(.tBody).foregroundStyle(Theme.sub)
                } else {
                    Image(systemName: "chevron.right").font(.app(15, .semibold)).foregroundStyle(Theme.sub)
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(RowPressStyle())
    }
}
