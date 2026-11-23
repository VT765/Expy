import SwiftUI

/// Numbered instruction: white circle with the step number, then the text.
struct QuickLaunchStep: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text("\(number)")
                .font(.app(13, .bold))
                .foregroundStyle(.black)
                .frame(width: 22, height: 22)
                .background(Circle().fill(.white))
                .accessibilityHidden(true)
            Text(text).font(.tBody).fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Step \(number). \(text)")
    }
}
