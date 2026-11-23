import SwiftUI

/// Grey label on the left, value on the right.
struct SummaryLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(.tFootnote).foregroundStyle(Theme.sub)
            Spacer()
            Text(value.isEmpty ? "—" : value).font(.tBodySemibold).multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}
