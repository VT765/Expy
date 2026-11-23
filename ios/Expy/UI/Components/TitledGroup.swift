import SwiftUI

/// Grey section label above a group of controls.
struct TitledGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: title)
            content
        }
    }
}
