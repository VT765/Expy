import SwiftUI

/// Grey section label above a rounded card.
struct AnalyticsCard<Content: View>: View {
    let title: String
    var padded = true
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(text: title).accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 0) { content }
                .padding(padded ? 16 : 0)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: Theme.cardRadius).fill(Theme.card))
                .clipShape(.rect(cornerRadius: Theme.cardRadius))
        }
        .padding(.top, 28)
    }
}
