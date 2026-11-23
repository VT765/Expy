import SwiftUI

/// Grey uppercase label (+ optional hint) above a group of setting cards.
struct SettingsSection<Content: View>: View {
    let title: String
    var hint: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            SectionLabel(text: title).padding(.bottom, hint == nil ? 4 : 0)
            if let hint { Text(hint).font(.tFootnote).foregroundStyle(Theme.sub).padding(.bottom, 6) }
            content
        }
        .padding(.top, 26)
    }
}
