import SwiftUI

/// Grey uppercase section label with wide tracking.
struct SectionLabel: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.tLabel)
            .tracking(1)
            .foregroundStyle(Theme.faint)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
