import SwiftUI

/// Chip visuals: white when on, raised grey when off; 44pt hit area.
struct FilterChipLabel: View {
    let title: String
    let icon: String
    let on: Bool
    var menu = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.app(12, .semibold)).accessibilityHidden(true)
            Text(title).font(.app(14, .semibold)).lineLimit(1)
            if menu { Image(systemName: "chevron.down").font(.app(10, .bold)).accessibilityHidden(true) }
        }
        .padding(.horizontal, 12).frame(height: 34)
        .foregroundStyle(on ? .black : Theme.sub)
        .background(Capsule().fill(on ? .white : Theme.raised))
        .frame(minHeight: 44)
        .contentShape(.rect)
    }
}
