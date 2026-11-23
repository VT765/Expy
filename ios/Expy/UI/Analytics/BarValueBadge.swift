import SwiftUI

/// White value bubble above the selected bar.
struct BarValueBadge: View {
    let total: Double
    let visible: Bool

    var body: some View {
        Text(Fmt.compact(total))
            .font(.app(11, .bold))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(.white))
            .foregroundStyle(.black)
            .opacity(visible ? 1 : 0)
    }
}
